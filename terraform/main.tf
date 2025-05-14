terraform {
  #   backend "azurerm" {
  #     storage_account_name = "adrwalstorageac"
  #     resource_group_name  = "state-storage-rg"
  #     container_name       = "tf-state"
  #     key                  = "ad.tfstate"
  #   }
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

resource "azurerm_subnet" "function_integration_subnet" {
  name                 = "adrwal-func-integration-subnet"
  resource_group_name  = azurerm_resource_group.main_rg.name
  virtual_network_name = azurerm_virtual_network.main_vnet.name
  address_prefixes     = ["10.0.1.0/24"]

  delegation {
    name = "function-delegation"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }

}

# =================== blob storage ===================
resource "azurerm_storage_account" "main_storage" {
  name                          = "adrwalstorageacblob"
  resource_group_name           = azurerm_resource_group.main_rg.name
  location                      = azurerm_resource_group.main_rg.location
  account_tier                  = "Standard"
  account_replication_type      = "LRS"
  public_network_access_enabled = true
}

resource "azurerm_storage_container" "main_container" {
  name                  = "adrwalcontainer"
  storage_account_id    = azurerm_storage_account.main_storage.id
  container_access_type = "private"
}

resource "azurerm_private_endpoint" "sotrage_acc_endpoint" {
  name                = "adrwal-storage-endpoint"
  location            = azurerm_resource_group.main_rg.location
  resource_group_name = azurerm_resource_group.main_rg.name

  subnet_id = azurerm_subnet.main_subnet.id

  private_service_connection {
    name                           = "adrwal-storage-connection"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_storage_account.main_storage.id
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name = "adrwal-storage-dns-group"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.storage_acc_dns_zone.id,
    ]
  }
}

resource "azurerm_private_endpoint" "sotrage_acc_file_endpoint" {
  name                = "adrwal-storage-file-endpoint"
  location            = azurerm_resource_group.main_rg.location
  resource_group_name = azurerm_resource_group.main_rg.name

  subnet_id = azurerm_subnet.main_subnet.id

  private_service_connection {
    name                           = "adrwal-storage-file-connection"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_storage_account.main_storage.id
    subresource_names              = ["file"]
  }

  private_dns_zone_group {
    name = "adrwal-storage-file-dns-group"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.storage_acc_dns_zone_file.id,
    ]
  }
}
resource "azurerm_private_endpoint" "sotrage_acc_queue_endpoint" {
  name                = "adrwal-storage-queue-endpoint"
  location            = azurerm_resource_group.main_rg.location
  resource_group_name = azurerm_resource_group.main_rg.name

  subnet_id = azurerm_subnet.main_subnet.id

  private_service_connection {
    name                           = "adrwal-storage-queue-connection"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_storage_account.main_storage.id
    subresource_names              = ["queue"]
  }

  private_dns_zone_group {
    name = "adrwal-storage-queue-dns-group"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.storage_acc_dns_zone_queue.id,
    ]
  }
}

resource "azurerm_private_endpoint" "sotrage_acc_table_endpoint" {
  name                = "adrwal-storage-table-endpoint"
  location            = azurerm_resource_group.main_rg.location
  resource_group_name = azurerm_resource_group.main_rg.name

  subnet_id = azurerm_subnet.main_subnet.id

  private_service_connection {
    name                           = "adrwal-storage-table-connection"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_storage_account.main_storage.id
    subresource_names              = ["table"]
  }

  private_dns_zone_group {
    name = "adrwal-storage-table-dns-group"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.storage_acc_dns_zone_table.id,
    ]
  }
}

resource "azurerm_private_dns_zone" "storage_acc_dns_zone" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.main_rg.name
}

resource "azurerm_private_dns_zone" "storage_acc_dns_zone_file" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = azurerm_resource_group.main_rg.name
}

resource "azurerm_private_dns_zone" "storage_acc_dns_zone_queue" {
  name                = "privatelink.queue.core.windows.net"
  resource_group_name = azurerm_resource_group.main_rg.name
}

resource "azurerm_private_dns_zone" "storage_acc_dns_zone_table" {
  name                = "privatelink.table.core.windows.net"
  resource_group_name = azurerm_resource_group.main_rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnet_storage_acc" {
  name                  = "adrwal-storage-vnet-link"
  resource_group_name   = azurerm_resource_group.main_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.storage_acc_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.main_vnet.id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnet_storage_acc_file" {
  name                  = "adrwal-storage-vnet-link-file"
  resource_group_name   = azurerm_resource_group.main_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.storage_acc_dns_zone_file.name
  virtual_network_id    = azurerm_virtual_network.main_vnet.id
  registration_enabled  = false
}
resource "azurerm_private_dns_zone_virtual_network_link" "vnet_storage_acc_queue" {
  name                  = "adrwal-storage-vnet-link-queue"
  resource_group_name   = azurerm_resource_group.main_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.storage_acc_dns_zone_queue.name
  virtual_network_id    = azurerm_virtual_network.main_vnet.id
  registration_enabled  = false
}
resource "azurerm_private_dns_zone_virtual_network_link" "vnet_storage_acc_table" {
  name                  = "adrwal-storage-vnet-link-table"
  resource_group_name   = azurerm_resource_group.main_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.storage_acc_dns_zone_table.name
  virtual_network_id    = azurerm_virtual_network.main_vnet.id
  registration_enabled  = false
}


# ==================================================

# =================== vault ===================

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "vault" {
  name                          = "adrwalvault"
  location                      = azurerm_resource_group.main_rg.location
  resource_group_name           = azurerm_resource_group.main_rg.name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  public_network_access_enabled = true
  enable_rbac_authorization     = true
}

resource "azurerm_role_assignment" "tf_vault_access" {
  principal_id         = data.azurerm_client_config.current.object_id
  role_definition_name = "Key Vault Administrator"
  scope                = azurerm_key_vault.vault.id
}

resource "azurerm_key_vault_secret" "test_secret" {
  name         = "SECRET-TEST"
  value        = "test_value"
  key_vault_id = azurerm_key_vault.vault.id
  depends_on = [
    azurerm_role_assignment.tf_vault_access
  ]
}

resource "azurerm_private_endpoint" "vault_pe" {
  name                = "adrwal-vault-endpoint"
  location            = azurerm_resource_group.main_rg.location
  resource_group_name = azurerm_resource_group.main_rg.name

  subnet_id = azurerm_subnet.main_subnet.id

  private_service_connection {
    name                           = "adrwal-vault-connection"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_key_vault.vault.id
    subresource_names              = ["vault"]
  }

  private_dns_zone_group {
    name                 = "adrwal-vault-dns-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.vault_dns_zone.id]
  }
}

resource "azurerm_private_dns_zone" "vault_dns_zone" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.main_rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnet_vault" {
  name                  = "adrwal-vault-vnet-link"
  resource_group_name   = azurerm_resource_group.main_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.vault_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.main_vnet.id
  registration_enabled  = false
}
# ==================================================

# =================== function app ===================
resource "azurerm_service_plan" "func_plan" {
  name                = "adrwal-func-plan"
  location            = azurerm_resource_group.main_rg.location
  resource_group_name = azurerm_resource_group.main_rg.name
  os_type             = "Linux"
  sku_name            = "EP1"
}

resource "azurerm_linux_function_app" "func_app" {
  name                       = "adrwal-func-app"
  location                   = azurerm_resource_group.main_rg.location
  resource_group_name        = azurerm_resource_group.main_rg.name
  service_plan_id            = azurerm_service_plan.func_plan.id
  storage_account_name       = azurerm_storage_account.main_storage.name # Uses same storage for function metadata
  storage_account_access_key = azurerm_storage_account.main_storage.primary_access_key
  # Enable Managed Identity
  identity {
    type = "SystemAssigned"
  }

  # VNet Integration Settings
  virtual_network_subnet_id = azurerm_subnet.function_integration_subnet.id
  https_only                = true
  # public_network_access_enabled = false # Restrict direct public access

  site_config {
    application_stack {
      python_version = "3.9" # Specify Python version (or node, dotnet etc.)
    }
    vnet_route_all_enabled = true       # Route all outbound traffic through VNet
    ftps_state             = "Disabled" # Disable FTP for security
  }

  app_settings = {
    # Settings needed by the function code
    "AzureWebJobsStorage"                      = azurerm_storage_account.main_storage.primary_connection_string # Connection string for function triggers/bindings
    "WEBSITE_CONTENTAZUREFILECONNECTIONSTRING" = azurerm_storage_account.main_storage.primary_connection_string
    "WEBSITE_CONTENTSHARE"                     = lower("adrwal-func-app-${azurerm_storage_account.main_storage.name}") # Unique share name for function app content
    "FUNCTIONS_EXTENSION_VERSION"              = "~4"
    "FUNCTIONS_WORKER_RUNTIME"                 = "python" # Or node, dotnet etc.
    "KEY_VAULT_URI"                            = azurerm_key_vault.vault.vault_uri
    "STORAGE_ACCOUNT_NAME"                     = azurerm_storage_account.main_storage.name
    "CONTAINER_NAME"                           = azurerm_storage_container.main_container.name
    "SECRET_NAME"                              = "SECRET-TEST"
    "WEBSITE_DNS_SERVER"                       = "168.63.129.16" # Required for PE resolution with VNet integration
    "WEBSITE_VNET_ROUTE_ALL"                   = "1"             # Ensure VNet integration routes all traffic
  }

  lifecycle {
    ignore_changes = [
      # Ignore changes to app_settings to prevent Terraform from overwriting
      # settings potentially managed elsewhere (like connection strings after deployment)
      # or if you manage function code deployment separately.
      app_settings["AzureWebJobsStorage"],
      app_settings["WEBSITE_CONTENTAZUREFILECONNECTIONSTRING"],
      app_settings["WEBSITE_CONTENTSHARE"]
    ]
  }
}

resource "azurerm_role_assignment" "func_vault_read" {
  principal_id         = azurerm_linux_function_app.func_app.identity[0].principal_id
  role_definition_name = "Key Vault Secrets User"
  scope                = azurerm_key_vault.vault.id

  depends_on = [
    azurerm_linux_function_app.func_app,
    azurerm_key_vault.vault
  ]
}

resource "azurerm_role_assignment" "func_storage_read" {
  principal_id         = azurerm_linux_function_app.func_app.identity[0].principal_id
  role_definition_name = "Storage Blob Data Reader"
  scope                = azurerm_storage_account.main_storage.id
}
