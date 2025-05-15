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
    key_vault {
      #   purge_soft_deleted_secrets_on_destroy      = true
      #   purge_soft_deleted_certificates_on_destroy = true

      #   recover_soft_deleted_key_vaults   = false
      #   recover_soft_deleted_secrets      = false
      #   recover_soft_deleted_certificates = false
      #   recover_soft_deleted_keys         = false
    }
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

# New Subnet for Application Gateway (must be dedicated)
resource "azurerm_subnet" "app_gw_subnet" {
  name                 = "adrwal-appgw-subnet"
  resource_group_name  = azurerm_resource_group.main_rg.name
  virtual_network_name = azurerm_virtual_network.main_vnet.name
  address_prefixes     = ["10.0.2.0/24"] # Ensure this range is available in your VNet
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

# terraform access to storage account
# resource "azurerm_role_assignment" "tf_storage_access" {
#   principal_id         = data.azurerm_client_config.current.object_id
#   role_definition_name = "Owner"
#   scope                = azurerm_storage_account.main_storage.id
# }

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

# Public IP for Application Gateway
resource "azurerm_public_ip" "app_gw_pip" {
  name                = "adrwal-appgw-pip"
  resource_group_name = azurerm_resource_group.main_rg.name
  location            = azurerm_resource_group.main_rg.location
  allocation_method   = "Static"
  sku                 = "Standard" # Standard SKU PIP for Standard SKU App Gateway
}

# User-Assigned Managed Identity for Application Gateway (to access Key Vault for SSL cert)
resource "azurerm_user_assigned_identity" "app_gw_identity" {
  name                = "adrwal-appgw-identity"
  resource_group_name = azurerm_resource_group.main_rg.name
  location            = azurerm_resource_group.main_rg.location
}

# Grant App Gateway's Managed Identity access to Key Vault secrets
resource "azurerm_role_assignment" "app_gw_kv_cert_access" {
  principal_id         = azurerm_user_assigned_identity.app_gw_identity.principal_id
  role_definition_name = "Key Vault Secrets User" # Allows reading secret content
  scope                = azurerm_key_vault.vault.id
}

# Placeholder/Self-Signed SSL Certificate in Key Vault for Application Gateway HTTPS Listener
# IMPORTANT: Replace this with your actual SSL certificate for your custom domain in production.
# This self-signed certificate allows Terraform to apply and the App Gateway to start.
resource "azurerm_key_vault_certificate" "app_gw_ssl_cert" {
  name         = "appgw-ssl-cert" # Name of the certificate in Key Vault
  key_vault_id = azurerm_key_vault.vault.id

  certificate_policy {
    issuer_parameters {
      name = "Self" # Specifies that Key Vault should generate a self-signed certificate
    }
    key_properties {
      exportable = true # Must be true for Application Gateway to use it
      key_size   = 2048 # Standard key size
      key_type   = "RSA"
      reuse_key  = false
    }
    secret_properties {
      content_type = "application/x-pkcs12" # Format required by Application Gateway (PFX)
    }
    x509_certificate_properties {
      key_usage = [
        "digitalSignature",
        "keyEncipherment",
        "dataEncipherment",
        "keyAgreement",
      ]
      # Subject Name of the certificate.
      # For testing, you can use a placeholder like "CN=test.yourappgw.com".
      # For production, this should be the custom domain your Application Gateway will serve (e.g., "CN=www.yourdomain.com").
      # The current value "CN=adrwal-func-app.example.com" is a placeholder.
      subject            = "CN=adrwal-func-app.example.com" # Customize this for your testing domain if needed
      validity_in_months = 12                               # How long the self-signed certificate will be valid

      # Optionally, add Subject Alternative Names (SANs) if the certificate needs to cover multiple hostnames.
      # subject_alternative_names {
      #   dns_names = ["www.yourdomain.com", "app.yourdomain.com", "test.yourappgw.com"]
      # }
    }
  }
  # Ensure the Terraform principal (or the identity it's running as)
  # has permissions to create/manage certificates in the Key Vault.
  # The 'tf_vault_access' role assignment grants "Key Vault Administrator" to the current client.
  depends_on = [azurerm_role_assignment.tf_vault_access]
}

# Application Gateway
resource "azurerm_application_gateway" "app_gateway" {
  name                = "adrwal-appgateway"
  resource_group_name = azurerm_resource_group.main_rg.name
  location            = azurerm_resource_group.main_rg.location

  sku {
    name     = "Standard_v2" # Choose appropriate SKU (Standard_v2 or WAF_v2)
    tier     = "Standard_v2"
    capacity = 2 # Autoscale is also an option for v2 SKUs
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

  # SSL Certificate from Key Vault
  ssl_certificate {
    name                = "appGwSslCertificate"
    key_vault_secret_id = azurerm_key_vault_certificate.app_gw_ssl_cert.secret_id # Reference the secret ID of the certificate
  }

  backend_address_pool {
    name  = "functionAppBackendPool"
    fqdns = [azurerm_linux_function_app.func_app.default_hostname] # Target the function app's default hostname
  }

  backend_http_settings {
    name                                = "functionAppHttpSettings"
    cookie_based_affinity               = "Disabled"
    port                                = 443
    protocol                            = "Https"
    request_timeout                     = 20
    probe_name                          = "functionAppHealthProbe"
    host_name                           = azurerm_linux_function_app.func_app.default_hostname # Pass correct host header
    pick_host_name_from_backend_address = false                                                # Since host_name is set
    # trusted_root_certificate_names = [] # Add if using self-signed certs on backend and AppGW needs to trust them
  }

  # Health Probe
  probe {
    name     = "functionAppHealthProbe"
    protocol = "Https"
    # host     = azurerm_linux_function_app.func_app.default_hostname
    path = "/" # IMPORTANT: Ensure this path returns 200 OK on your Function App for an unauthenticated request.
    # Otherwise, create a dedicated /api/health or similar endpoint.
    interval                                  = 30
    timeout                                   = 10
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = true # Use host from backend HTTP settings for probe
    # minimum_servers = 0 # Default
    match {
      status_code = ["200-399"] # Valid HTTP responses
    }
  }

  http_listener {
    name                           = "httpsListener"
    frontend_ip_configuration_name = "publicFrontendIp"
    frontend_port_name             = "httpsPort"
    protocol                       = "Https"
    ssl_certificate_name           = "appGwSslCertificate"
    # require_sni = true # Recommended for multiple site hosting
  }

  request_routing_rule {
    name                       = "functionAppRoutingRule"
    rule_type                  = "Basic"
    http_listener_name         = "httpsListener"
    backend_address_pool_name  = "functionAppBackendPool"
    backend_http_settings_name = "functionAppHttpSettings"
    priority                   = 100
  }

  # Enable WAF if using WAF_v2 SKU
  # waf_configuration {
  #   enabled                  = true
  #   firewall_mode            = "Detection" # Or "Prevention"
  #   rule_set_type            = "OWASP"
  #   rule_set_version         = "3.2" # Or other supported version
  # }

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
  storage_account_name       = azurerm_storage_account.main_storage.name # Uses same storage for function metadata
  storage_account_access_key = azurerm_storage_account.main_storage.primary_access_key
  # Enable Managed Identity
  identity {
    type = "SystemAssigned"
  }

  # VNet Integration Settings
  virtual_network_subnet_id     = azurerm_subnet.function_integration_subnet.id
  https_only                    = true
  public_network_access_enabled = true # Restrict direct public access

  site_config {
    application_stack {
      python_version = "3.9" # Specify Python version (or node, dotnet etc.)
    }
    vnet_route_all_enabled = true       # Route all outbound traffic through VNet
    ftps_state             = "Disabled" # Disable FTP for security

    ip_restriction {
      action                    = "Allow"
      priority                  = 100
      name                      = "AllowAppGatewaySubnet"
      virtual_network_subnet_id = azurerm_subnet.app_gw_subnet.id
    }
  }

  app_settings = {
    # Settings needed by the function code
    "AzureWebJobsStorage"                      = azurerm_storage_account.main_storage.primary_connection_string # Connection string for function triggers/bindings
    "WEBSITE_CONTENTAZUREFILECONNECTIONSTRING" = azurerm_storage_account.main_storage.primary_connection_string
    "WEBSITE_CONTENTSHARE"                     = lower("adrwal-func-app-de-${random_string.rand_str.result}") # Unique share name for function app content
    "FUNCTIONS_EXTENSION_VERSION"              = "~4"
    "FUNCTIONS_WORKER_RUNTIME"                 = "python" # Or node, dotnet etc.
    "KEY_VAULT_URI"                            = azurerm_key_vault.vault.vault_uri
    "STORAGE_ACCOUNT_NAME"                     = azurerm_storage_account.main_storage.name
    "CONTAINER_NAME"                           = azurerm_storage_container.main_container.name
    "SECRET_NAME"                              = "SECRET-TEST"
    "WEBSITE_DNS_SERVER"                       = "168.63.129.16" # Required for PE resolution with VNet integration
    "WEBSITE_VNET_ROUTE_ALL"                   = "1"             # Ensure VNet integration routes all traffic
    # "WEBSITE_CONTENTOVERVNET"                  = "1"             # Ensures function app content share is accessed over VNet
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

  depends_on = [
    azurerm_private_endpoint.sotrage_acc_file_endpoint,
    azurerm_private_dns_zone_virtual_network_link.vnet_storage_acc_file
  ]
}

resource "azurerm_private_endpoint" "func_app_pe" {
  name                = "adrwal-func-app-pe"
  location            = azurerm_resource_group.main_rg.location
  resource_group_name = azurerm_resource_group.main_rg.name
  subnet_id           = azurerm_subnet.main_subnet.id # Using the main subnet designated for PEs

  private_service_connection {
    name                           = "adrwal-func-app-psc"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_linux_function_app.func_app.id
    subresource_names              = ["sites"] # Subresource for App Services (including Function Apps)
  }

  # This group will automatically create the A record in the specified private DNS zone
  private_dns_zone_group {
    name                 = "adrwal-func-app-dns-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.func_app_dns_zone.id]
  }

  depends_on = [
    azurerm_linux_function_app.func_app,
    azurerm_private_dns_zone.func_app_dns_zone # Ensure DNS zone exists before PE tries to register
  ]
}

resource "azurerm_private_dns_zone" "func_app_dns_zone" {
  name                = "privatelink.azurewebsites.net" # Standard DNS zone for App Service/Function App PEs
  resource_group_name = azurerm_resource_group.main_rg.name
}

# --- NEW: Link Private DNS Zone to Virtual Network ---
resource "azurerm_private_dns_zone_virtual_network_link" "func_app_dns_vnet_link" {
  name                  = "adrwal-func-app-dns-vnet-link"
  resource_group_name   = azurerm_resource_group.main_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.func_app_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.main_vnet.id
  registration_enabled  = false # PE DNS group handles A record registration

  # Ensure the DNS zone exists before creating the link
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
