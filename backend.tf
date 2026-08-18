# Phase 1 (bootstrap): leave this commented out. `tofu init && tofu apply`
# runs with local state and creates the storage account.
#
# Phase 2 (migrate): uncomment, fill in the values from `tofu output`,
# then run `tofu init -migrate-state`. See README.md for the full
# procedure.
#
# Locking is native: the azurerm backend takes a blob lease on the state
# object during operations — no extra configuration needed.

# terraform {
#   backend "azurerm" {
#     resource_group_name  = "REPLACE-WITH-resource_group_name-OUTPUT"
#     storage_account_name = "REPLACE-WITH-storage_account_name-OUTPUT"
#     container_name       = "tfstate"
#     key                  = "bootstrap/terraform.tfstate"
#   }
# }
