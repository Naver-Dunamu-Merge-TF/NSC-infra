# =============================================================================
# Security Module — Variables
# =============================================================================

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "project_prefix" {
  type = string
}

variable "environment" {
  type = string
}

variable "suffix" {
  description = "글로벌 유니크 이름용 suffix (ACR)"
  type        = string
}

variable "tenant_id" {
  description = "Azure AD Tenant ID (Key Vault용)"
  type        = string                                  # data.azurerm_client_config.current.tenant_id
}

variable "vnet_id" {
  description = "VNet ID (DNS Zone VNet Link용)"
  type        = string                                  # module.network.vnet_id
}

variable "tags" {
  type = map(string)
}
