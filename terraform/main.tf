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
  features {
  }
}

resource "azurerm_resource_group" "main_rg" {
  name     = "${var.resource_group_name}${random_string.rand_str.result}"
  location = var.location
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
module "storage" {
  source = "./modules/storage"

  resource_group_name = azurerm_resource_group.main_rg.name
  location            = azurerm_resource_group.main_rg.location
  subnet_id           = azurerm_subnet.main_subnet.id
  virtual_network_id  = azurerm_virtual_network.main_vnet.id
  resource_suffix     = random_string.rand_str.result
  example_files = [{
    name   = "main.tf"
    source = "main.tf"
  }]

}


# ==================================================

# =================== vault ===================

module "vault" {
  source = "./modules/vault"

  resource_group_name = azurerm_resource_group.main_rg.name
  location            = azurerm_resource_group.main_rg.location
  subnet_id           = azurerm_subnet.main_subnet.id
  virtual_network_id  = azurerm_virtual_network.main_vnet.id
  resource_suffix     = random_string.rand_str.result
  example_secrets = [{
    name  = "SECRET-TEST"
    value = "test_value"
  }]
}


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
  role_definition_name = "Key Vault Secrets User"
  scope                = module.vault.id
}

resource "azurerm_key_vault_certificate" "app_gw_ssl_cert" {
  name         = "appgw-ssl-cert"
  key_vault_id = module.vault.id

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

  depends_on = [
    azurerm_role_assignment.func_vault_read
  ]
}

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
  storage_account_name       = module.storage.name #
  storage_account_access_key = module.storage.primary_access_key

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

    "AzureWebJobsStorage"                      = module.storage.primary_connection_string
    "WEBSITE_CONTENTAZUREFILECONNECTIONSTRING" = module.storage.primary_connection_string
    "WEBSITE_CONTENTSHARE"                     = lower("adrwal-func-app-de-${random_string.rand_str.result}")
    "FUNCTIONS_EXTENSION_VERSION"              = "~4"
    "FUNCTIONS_WORKER_RUNTIME"                 = "python"
    "KEY_VAULT_URI"                            = module.vault.vault_uri
    "STORAGE_ACCOUNT_NAME"                     = module.storage.name
    "CONTAINER_NAME"                           = module.storage.container_name
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
  scope                = module.vault.id

  depends_on = [
    azurerm_linux_function_app.func_app,
  ]
}

resource "azurerm_role_assignment" "func_storage_read" {
  principal_id         = azurerm_linux_function_app.func_app.identity[0].principal_id
  role_definition_name = "Storage Blob Data Reader"
  scope                = module.storage.id
}
