data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "vault" {
  name                          = "adrwalvaultde${var.resource_suffix}"
  location                      = var.location
  resource_group_name           = var.resource_group_name
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
  for_each     = { for secret in var.example_secrets : secret.name => secret }
  name         = each.value.name
  value        = each.value.value
  key_vault_id = azurerm_key_vault.vault.id
  depends_on = [
    azurerm_role_assignment.tf_vault_access
  ]
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

resource "azurerm_private_endpoint" "vault_pe" {
  name                = "adrwal-vault-endpoint"
  location            = var.location
  resource_group_name = var.resource_group_name

  subnet_id = var.subnet_id

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
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnet_vault" {
  name                  = "adrwal-vault-vnet-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.vault_dns_zone.name
  virtual_network_id    = var.virtual_network_id
  registration_enabled  = false
}
