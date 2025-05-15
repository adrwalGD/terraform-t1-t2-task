
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

output "function_app_name" {
  description = "Name of the Function App."
  value       = azurerm_linux_function_app.func_app.name
}

output "func_address" {
  description = "Funcion address through App Gateway."
  value       = "https://${azurerm_public_ip.app_gw_pip.ip_address}/api/httptrigger"
}
