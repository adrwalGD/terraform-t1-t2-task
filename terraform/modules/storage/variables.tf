variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
}

variable "resource_suffix" {
  description = "Random string to append to resource names"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet for private endpoints"
  type        = string
}

variable "virtual_network_id" {
  description = "ID of the virtual network"
  type        = string
}

variable "example_files" {
  description = "List of example files to upload to the storage account"
  type = list(object({
    name   = string
    source = string
  }))
  default = [
    {
      name   = "main.tf"
      source = "./main.tf"
    },
  ]
}
