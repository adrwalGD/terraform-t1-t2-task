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
