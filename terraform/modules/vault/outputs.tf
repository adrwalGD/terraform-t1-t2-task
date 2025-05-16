output "id" {
  description = "ID of the key vault"
  value       = azurerm_key_vault.vault.id
}

output "vault_uri" {
  description = "URI of the key vault"
  value       = azurerm_key_vault.vault.vault_uri
}

output "name" {
  description = "Name of the key vault"
  value       = azurerm_key_vault.vault.name
}

# output "private_endpoint_ip" {
#   description = "IP address of the vault private endpoint"
#   value       = azurerm_private_endpoint.vault_pe.private_service_connection[0].private_ip_address
# }

# output "cert_id" {
#   description = "ID of the Key Vault certificate"
#   value       = azurerm_key_vault_certificate.app_gw_ssl_cert.secret_id
# }
