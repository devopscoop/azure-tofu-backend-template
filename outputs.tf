output "resource_group_name" {
  description = "Resource group holding the state storage account."
  value       = azurerm_resource_group.state.name
}

output "storage_account_name" {
  description = "Storage account holding the state."
  value       = azurerm_storage_account.state.name
}

output "container_name" {
  description = "Blob container holding the state."
  value       = azurerm_storage_container.state.name
}

output "backend_config" {
  description = "Backend block for the repo's main configuration. Paste into its terraform {} block; adjust `key` if the repo has multiple root modules."
  value       = <<-EOT
    backend "azurerm" {
      resource_group_name  = "${azurerm_resource_group.state.name}"
      storage_account_name = "${azurerm_storage_account.state.name}"
      container_name       = "${azurerm_storage_container.state.name}"
      key                  = "terraform.tfstate"
    }
  EOT
}
