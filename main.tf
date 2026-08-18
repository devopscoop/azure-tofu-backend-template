data "azurerm_client_config" "current" {}

locals {
  resource_group_name = var.resource_group_name != "" ? var.resource_group_name : "${var.repo_name}-tfstate"

  # Storage account names allow only 3-24 lowercase alphanumerics and are
  # globally unique, so strip hyphens and salt with the subscription id.
  storage_account_name = var.storage_account_name != "" ? var.storage_account_name : "${substr(replace(var.repo_name, "-", ""), 0, 14)}tf${substr(sha1(data.azurerm_client_config.current.subscription_id), 0, 8)}"

  tags = {
    purpose = "opentofu-remote-state"
    repo    = var.repo_name
  }
}

resource "azurerm_resource_group" "state" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.tags
}

resource "azurerm_storage_account" "state" {
  name                = local.storage_account_name
  resource_group_name = azurerm_resource_group.state.name
  location            = azurerm_resource_group.state.location

  account_tier             = "Standard"
  account_replication_type = var.replication_type

  # Encryption at rest with Microsoft-managed keys is always on and cannot
  # be disabled; this adds a second, independent encryption layer beneath it.
  infrastructure_encryption_enabled = true

  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = var.delete_retention_days
    }

    container_delete_retention_policy {
      days = var.delete_retention_days
    }
  }

  tags = local.tags

  # This account holds the state that describes it. Destroying it destroys
  # the record of everything in this configuration, so make `tofu destroy`
  # refuse to touch it unless this guard is removed first.
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_storage_container" "state" {
  name                  = var.container_name
  storage_account_id    = azurerm_storage_account.state.id
  container_access_type = "private"
}

resource "azurerm_storage_management_policy" "expire_old_versions" {
  storage_account_id = azurerm_storage_account.state.id

  rule {
    name    = "expire-old-state-versions"
    enabled = true

    filters {
      blob_types = ["blockBlob"]
    }

    actions {
      version {
        delete_after_days_since_creation = var.version_expiration_days
      }
    }
  }
}
