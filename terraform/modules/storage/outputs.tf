output "name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.main_storage.name
}

output "id" {
  description = "ID of the storage account"
  value       = azurerm_storage_account.main_storage.id
}

output "primary_access_key" {
  description = "Primary access key for the storage account"
  value       = azurerm_storage_account.main_storage.primary_access_key
  sensitive   = true
}

output "primary_connection_string" {
  description = "Primary connection string for the storage account"
  value       = azurerm_storage_account.main_storage.primary_connection_string
  sensitive   = true
}

output "container_name" {
  description = "Name of the storage container"
  value       = azurerm_storage_container.main_container.name
}

output "private_endpoint_ip" {
  description = "IP address of the storage account private endpoint"
  value       = azurerm_private_endpoint.sotrage_acc_endpoint.private_service_connection[0].private_ip_address
}
