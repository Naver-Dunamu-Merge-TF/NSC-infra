variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "bastion_subnet_id" {
  description = "Subnet ID for Azure Bastion"
  type        = string
}

variable "firewall_subnet_id" {
  description = "Subnet ID for Azure Firewall"
  type        = string
}

variable "appgw_subnet_id" {
  description = "Subnet ID for Application Gateway"
  type        = string
}
