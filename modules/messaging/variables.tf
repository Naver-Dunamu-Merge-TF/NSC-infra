variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "suffix" {
  description = "Random suffix for globally unique names"
  type        = string
}
