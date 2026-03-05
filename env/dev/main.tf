provider "azurerm" {
  features {}
}

# ------------------------------
# Resource Group
# ------------------------------
resource "azurerm_resource_group" "rg" {
  name     = "tf-rg"
  location = "WestUS2"
}

# ------------------------------
# Storage Account
# ------------------------------
resource "azurerm_storage_account" "storage" {
  name                     = "tfstoragedemo177"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# ------------------------------
# Storage Containers
# ------------------------------
resource "azurerm_storage_container" "input_container" {
  name                  = "input"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "output_container" {
  name                  = "output"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}

# ------------------------------
# Data Factory
# ------------------------------
resource "azurerm_data_factory" "adf" {
  name                = "adfdemo177"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}
