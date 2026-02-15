# =============================================================================
# Private Endpoints Module — Variables
# =============================================================================

variable "resource_group_name" {
  description = "Resource Group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "project_prefix" {
  description = "리소스 네이밍 접두어"
  type        = string
}

variable "subnet_ids" {
  description = "서브넷 ID 맵 (data, security, messaging, analytics_host)"
  type        = map(string)
}

variable "dns_zone_ids" {
  description = "Private DNS Zone ID 맵"
  type        = map(string)
}

variable "sql_server_id" {
  description = "SQL Server ID"
  type        = string
}

variable "postgresql_server_id" {
  description = "PostgreSQL Flexible Server ID"
  type        = string
}

variable "ledger_id" {
  description = "Confidential Ledger ID"
  type        = string
}

variable "key_vault_id" {
  description = "Key Vault ID"
  type        = string
}

variable "acr_id" {
  description = "Container Registry ID"
  type        = string
}

variable "eventhubs_namespace_id" {
  description = "Event Hubs Namespace ID"
  type        = string
}

variable "adls_storage_id" {
  description = "ADLS Gen2 Storage Account ID"
  type        = string
}

variable "tags" {
  description = "공통 태그"
  type        = map(string)
}
