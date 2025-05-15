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
  features {
  }
}

resource "azurerm_resource_group" "main_rg" {
  name     = "adrwal-rg-de${random_string.rand_str.result}"
  location = "germanywestcentral"
}

resource "random_string" "rand_str" {
  length  = 4
  special = false
  upper   = false
}

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

resource "azurerm_subnet" "app_gw_subnet" {
  name                 = "adrwal-appgw-subnet"
  resource_group_name  = azurerm_resource_group.main_rg.name
  virtual_network_name = azurerm_virtual_network.main_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# =================== blob storage ===================
resource "azurerm_storage_account" "main_storage" {
  name                          = "adrwalstorageac${random_string.rand_str.result}"
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

resource "azurerm_storage_blob" "example_file" {
  name                   = "main.tf"
  storage_account_name   = azurerm_storage_account.main_storage.name
  storage_container_name = azurerm_storage_container.main_container.name
  type                   = "Block"
  source                 = "main.tf"
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
  name                          = "adrwalvaultde${random_string.rand_str.result}"
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

# =================== Application Gateway Components ===================

resource "azurerm_public_ip" "app_gw_pip" {
  name                = "adrwal-appgw-pip"
  resource_group_name = azurerm_resource_group.main_rg.name
  location            = azurerm_resource_group.main_rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_user_assigned_identity" "app_gw_identity" {
  name                = "adrwal-appgw-identity"
  resource_group_name = azurerm_resource_group.main_rg.name
  location            = azurerm_resource_group.main_rg.location
}

resource "azurerm_role_assignment" "app_gw_kv_cert_access" {
  principal_id         = azurerm_user_assigned_identity.app_gw_identity.principal_id
  role_definition_name = "Key Vault Secrets User" # Allows reading secret content
  scope                = azurerm_key_vault.vault.id
}

resource "azurerm_key_vault_certificate" "app_gw_ssl_cert" {
  name         = "appgw-ssl-cert"
  key_vault_id = azurerm_key_vault.vault.id

  certificate_policy {
    issuer_parameters {
      name = "Self" #
    }
    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = false
    }
    secret_properties {
      content_type = "application/x-pkcs12"
    }
    x509_certificate_properties {
      key_usage = [
        "digitalSignature",
        "keyEncipherment",
        "dataEncipherment",
        "keyAgreement",
      ]
      subject            = "CN=adrwal-func-app.example.com"
      validity_in_months = 12

    }
  }

  depends_on = [azurerm_role_assignment.tf_vault_access]
}

#
resource "azurerm_application_gateway" "app_gateway" {
  name                = "adrwal-appgateway"
  resource_group_name = azurerm_resource_group.main_rg.name
  location            = azurerm_resource_group.main_rg.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.app_gw_identity.id]
  }

  gateway_ip_configuration {
    name      = "appGatewayIpConfig"
    subnet_id = azurerm_subnet.app_gw_subnet.id
  }

  frontend_port {
    name = "httpsPort"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "publicFrontendIp"
    public_ip_address_id = azurerm_public_ip.app_gw_pip.id
  }


  ssl_certificate {
    name                = "appGwSslCertificate"
    key_vault_secret_id = azurerm_key_vault_certificate.app_gw_ssl_cert.secret_id
  }

  backend_address_pool {
    name  = "functionAppBackendPool"
    fqdns = [azurerm_linux_function_app.func_app.default_hostname]
  }

  backend_http_settings {
    name                                = "functionAppHttpSettings"
    cookie_based_affinity               = "Disabled"
    port                                = 443
    protocol                            = "Https"
    request_timeout                     = 20
    probe_name                          = "functionAppHealthProbe"
    host_name                           = azurerm_linux_function_app.func_app.default_hostname
    pick_host_name_from_backend_address = false

  }


  probe {
    name     = "functionAppHealthProbe"
    protocol = "Https"

    path = "/"

    interval                                  = 30
    timeout                                   = 10
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = true

    match {
      status_code = ["200-399"]
    }
  }

  http_listener {
    name                           = "httpsListener"
    frontend_ip_configuration_name = "publicFrontendIp"
    frontend_port_name             = "httpsPort"
    protocol                       = "Https"
    ssl_certificate_name           = "appGwSslCertificate"

  }

  request_routing_rule {
    name                       = "functionAppRoutingRule"
    rule_type                  = "Basic"
    http_listener_name         = "httpsListener"
    backend_address_pool_name  = "functionAppBackendPool"
    backend_http_settings_name = "functionAppHttpSettings"
    priority                   = 100
  }

  depends_on = [
    azurerm_role_assignment.app_gw_kv_cert_access,
    azurerm_key_vault_certificate.app_gw_ssl_cert
  ]
}
# ==================================================

# =================== function app ===================
resource "azurerm_service_plan" "func_plan" {
  name                = "adrwal-func-plan-de${random_string.rand_str.result}"
  location            = azurerm_resource_group.main_rg.location
  resource_group_name = azurerm_resource_group.main_rg.name
  os_type             = "Linux"
  sku_name            = "EP1"
}

resource "azurerm_linux_function_app" "func_app" {
  name                       = "adrwal-func-app-de${random_string.rand_str.result}"
  location                   = azurerm_resource_group.main_rg.location
  resource_group_name        = azurerm_resource_group.main_rg.name
  service_plan_id            = azurerm_service_plan.func_plan.id
  storage_account_name       = azurerm_storage_account.main_storage.name #
  storage_account_access_key = azurerm_storage_account.main_storage.primary_access_key

  identity {
    type = "SystemAssigned"
  }


  virtual_network_subnet_id     = azurerm_subnet.function_integration_subnet.id
  https_only                    = true
  public_network_access_enabled = true

  site_config {
    application_stack {
      python_version = "3.9"
    }
    vnet_route_all_enabled = true
    ftps_state             = "Disabled"

    ip_restriction {
      action                    = "Allow"
      priority                  = 100
      name                      = "AllowAppGatewaySubnet"
      virtual_network_subnet_id = azurerm_subnet.app_gw_subnet.id
    }
  }

  app_settings = {

    "AzureWebJobsStorage"                      = azurerm_storage_account.main_storage.primary_connection_string
    "WEBSITE_CONTENTAZUREFILECONNECTIONSTRING" = azurerm_storage_account.main_storage.primary_connection_string
    "WEBSITE_CONTENTSHARE"                     = lower("adrwal-func-app-de-${random_string.rand_str.result}")
    "FUNCTIONS_EXTENSION_VERSION"              = "~4"
    "FUNCTIONS_WORKER_RUNTIME"                 = "python"
    "KEY_VAULT_URI"                            = azurerm_key_vault.vault.vault_uri
    "STORAGE_ACCOUNT_NAME"                     = azurerm_storage_account.main_storage.name
    "CONTAINER_NAME"                           = azurerm_storage_container.main_container.name
    "SECRET_NAME"                              = "SECRET-TEST"
    "WEBSITE_DNS_SERVER"                       = "168.63.129.16"
    "WEBSITE_VNET_ROUTE_ALL"                   = "1"
    # "WEBSITE_CONTENTOVERVNET"                  = "1"
  }

  lifecycle {
    ignore_changes = [
      app_settings["AzureWebJobsStorage"],
      app_settings["WEBSITE_CONTENTAZUREFILECONNECTIONSTRING"],
      app_settings["WEBSITE_CONTENTSHARE"]
    ]
  }

  depends_on = [
    azurerm_private_endpoint.sotrage_acc_file_endpoint,
    azurerm_private_dns_zone_virtual_network_link.vnet_storage_acc_file
  ]
}

resource "azurerm_private_endpoint" "func_app_pe" {
  name                = "adrwal-func-app-pe"
  location            = azurerm_resource_group.main_rg.location
  resource_group_name = azurerm_resource_group.main_rg.name
  subnet_id           = azurerm_subnet.main_subnet.id

  private_service_connection {
    name                           = "adrwal-func-app-psc"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_linux_function_app.func_app.id
    subresource_names              = ["sites"]
  }


  private_dns_zone_group {
    name                 = "adrwal-func-app-dns-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.func_app_dns_zone.id]
  }

  depends_on = [
    azurerm_linux_function_app.func_app,
    azurerm_private_dns_zone.func_app_dns_zone
  ]
}

resource "azurerm_private_dns_zone" "func_app_dns_zone" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = azurerm_resource_group.main_rg.name
}


resource "azurerm_private_dns_zone_virtual_network_link" "func_app_dns_vnet_link" {
  name                  = "adrwal-func-app-dns-vnet-link"
  resource_group_name   = azurerm_resource_group.main_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.func_app_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.main_vnet.id
  registration_enabled  = false

  depends_on = [azurerm_private_dns_zone.func_app_dns_zone]
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
