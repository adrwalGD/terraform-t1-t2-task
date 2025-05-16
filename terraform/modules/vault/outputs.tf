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
