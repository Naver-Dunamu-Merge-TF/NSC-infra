# =============================================================================
# Security Module — Variables
# =============================================================================

variable "resource_group_name" {
  type = string                                         # RG 이름
}

variable "location" {
  type = string                                         # Azure 리전
}

variable "project_prefix" {
  type = string                                         # 네이밍 접두어: nsc
}

variable "environment" {
  type = string                                         # 환경: dev / stg / prod
}

variable "suffix" {
  description = "글로벌 유니크 이름용 suffix (ACR)"
  type        = string                                  # random_string 결과
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
  type = map(string)                                    # 공통 태그
}
