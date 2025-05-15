resource "azurerm_storage_account" "main_storage" {
  name                          = "adrwalstorageac${var.resource_suffix}"
  resource_group_name           = var.resource_group_name
  location                      = var.location
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
  for_each               = { for file in var.example_files : file.name => file }
  name                   = each.value.name
  storage_account_name   = azurerm_storage_account.main_storage.name
  storage_container_name = azurerm_storage_container.main_container.name
  type                   = "Block"
  source                 = each.value.source
  # name                   = "main.tf"
  # storage_account_name   = azurerm_storage_account.main_storage.name
  # storage_container_name = azurerm_storage_container.main_container.name
  # type                   = "Block"
  # source                 = var.source_file
}

resource "azurerm_private_endpoint" "sotrage_acc_endpoint" {
  name                = "adrwal-storage-endpoint"
  location            = var.location
  resource_group_name = var.resource_group_name

  subnet_id = var.subnet_id

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
  location            = var.location
  resource_group_name = var.resource_group_name

  subnet_id = var.subnet_id

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
  location            = var.location
  resource_group_name = var.resource_group_name

  subnet_id = var.subnet_id

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
  location            = var.location
  resource_group_name = var.resource_group_name

  subnet_id = var.subnet_id

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
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone" "storage_acc_dns_zone_file" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone" "storage_acc_dns_zone_queue" {
  name                = "privatelink.queue.core.windows.net"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone" "storage_acc_dns_zone_table" {
  name                = "privatelink.table.core.windows.net"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnet_storage_acc" {
  name                  = "adrwal-storage-vnet-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.storage_acc_dns_zone.name
  virtual_network_id    = var.virtual_network_id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnet_storage_acc_file" {
  name                  = "adrwal-storage-vnet-link-file"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.storage_acc_dns_zone_file.name
  virtual_network_id    = var.virtual_network_id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnet_storage_acc_queue" {
  name                  = "adrwal-storage-vnet-link-queue"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.storage_acc_dns_zone_queue.name
  virtual_network_id    = var.virtual_network_id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnet_storage_acc_table" {
  name                  = "adrwal-storage-vnet-link-table"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.storage_acc_dns_zone_table.name
  virtual_network_id    = var.virtual_network_id
  registration_enabled  = false
}
