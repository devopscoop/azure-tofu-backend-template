variable "repo_name" {
  description = "Name of the git repository this state storage belongs to. Used in resource names; the storage account name is derived from it with hyphens stripped."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,40}[a-z0-9]$", var.repo_name))
    error_message = "repo_name must be 3-42 chars of lowercase letters, digits, and hyphens, starting and ending with a letter or digit."
  }
}

variable "location" {
  description = "Azure region for the state storage."
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "Override for the resource group name. Leave empty to use '<repo_name>-tfstate'."
  type        = string
  default     = ""
}

variable "storage_account_name" {
  description = "Override for the storage account name (3-24 lowercase alphanumerics, globally unique). Leave empty to derive one from repo_name plus a hash of the subscription id."
  type        = string
  default     = ""
}

variable "container_name" {
  description = "Blob container that holds the state."
  type        = string
  default     = "tfstate"
}

variable "replication_type" {
  description = "Storage account replication. ZRS survives a zone outage; use LRS in regions without zone support."
  type        = string
  default     = "ZRS"
}

variable "version_expiration_days" {
  description = "Days to keep old blob versions before deleting them. Versioning is what lets you recover a clobbered state file, but old versions accumulate cost forever without this."
  type        = number
  default     = 90
}

variable "delete_retention_days" {
  description = "Days that deleted blobs and containers remain recoverable."
  type        = number
  default     = 30
}
