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

variable "tenant_id" {
  description = "Azure AD tenant ID for Confidential Ledger"
  type        = string
}

variable "current_object_id" {
  description = "Current Azure AD object ID for Confidential Ledger admin"
  type        = string
}
