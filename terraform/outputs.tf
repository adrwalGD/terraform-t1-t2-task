
# output "function_app_name" {
#   description = "Name of the Function App."
#   value       = azurerm_linux_function_app.func_app.name
# }

# output "function_app_default_hostname" {
#   description = "Default hostname of the Function App (this is the public access point)."
#   value       = azurerm_linux_function_app.func_app.default_hostname
# }


# output "function_trigger_url" {
#   description = "URL to trigger the HTTP function directly."
#   # Construct the URL using the function app's default hostname
#   # Note: Function keys might be required depending on the function's authorization level (default is 'function')
#   # This URL assumes the default 'function' auth level and doesn't include the key.
#   # You might need to get the key from the portal or use 'anonymous' auth level for direct access without a key.
#   value = "https://${azurerm_linux_function_app.func_app.default_hostname}/api/HttpTrigger1" # Adjust path if function name/route differs
# }

# output "tenant_id" {
#   description = "Tenant ID of the Azure subscription."
#   value       = data.azurerm_client_config.current.tenant_id
# }

# output "object_id" {
#   value       = data.azurerm_client_config.current.object_id
#   description = "Object ID of the current Azure client."
# }

# output "kv_uri" {
#   description = "URI of the Key Vault."
#   value       = azurerm_key_vault.vault.vault_uri
# }

# output "storage_acc_url" {
#   description = "URL of the Storage Account."
#   value       = azurerm_storage_account.main_storage.primary_blob_endpoint
# }

output "disable_storage_acc_public_network_access" {
  description = "Disable public network access for the Storage Account."
  value       = "az storage account update --name ${azurerm_storage_account.main_storage.name} --resource-group ${azurerm_resource_group.main_rg.name} --public-network-access 'Disabled' --default-action 'Deny'"
}

output "disable_vault_public_network_access" {
  description = "Disable public network access for the Key Vault."
  value       = "az keyvault update --name ${azurerm_key_vault.vault.name} --resource-group ${azurerm_resource_group.main_rg.name} --public-network-access 'Disabled'"
}


output "disable_function_app_public_network_access" {
  description = "Disable public network access for the Function App."
  value       = "az functionapp update --name ${azurerm_linux_function_app.func_app.name} --resource-group ${azurerm_resource_group.main_rg.name} --set publicNetworkAccess=Disabled"

}
