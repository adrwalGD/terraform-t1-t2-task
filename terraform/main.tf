terraform {
  backend "azurerm" {
    storage_account_name = "adrwalstorageac"
    resource_group_name  = "state-storage-rg"
    container_name       = "tf-state"
    key                  = "ad.tfstate"
  }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.28.0"
    }
  }
}


provider "azurerm" {
  subscription_id = "fed0fb3d-c158-4da2-a188-84d0bb413368"
  features {}
}

resource "azurerm_resource_group" "main_rg" {
  name     = "adrwal-rg"
  location = "westeurope"
}

# vnet
resource "azurerm_virtual_network" "main_vnet" {
  name                = "adrwal-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main_rg.location
  resource_group_name = azurerm_resource_group.main_rg.name
}

resource "azurerm_subnet" "main_subnet" {
  name                 = "adrwal-subnet"
  resource_group_name  = azurerm_resource_group.main_rg.name
  virtual_network_name = azurerm_virtual_network.main_vnet.name
  address_prefixes     = ["10.0.0.0/24"]
}
