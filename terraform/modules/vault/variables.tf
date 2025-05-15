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

variable "example_secrets" {
  description = "List of example secrets to create in the Key Vault"
  type = list(object({
    name  = string
    value = string
  }))
  default = [
    {
      name  = "example-secret-1"
      value = "example-value-1"
    },
  ]
}
