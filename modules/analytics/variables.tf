# =============================================================================
# Analytics Module — Variables
# =============================================================================

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "project_prefix" {
  type = string                                         # nsc
}

variable "environment" {
  type = string                                         # dev/stg/prod
}

variable "suffix" {
  description = "글로벌 유니크 suffix (ADLS Storage Account)"
  type        = string                                  # random_string 결과
}

variable "vnet_id" {
  description = "VNet ID (Databricks VNet Injection)"
  type        = string
}

variable "analytics_host_subnet_id" {
  description = "Databricks Host 서브넷 ID"
  type        = string
}

variable "analytics_host_subnet_name" {
  description = "Databricks Host 서브넷 이름"
  type        = string                                  # nsc-snet-analytics-host
}

variable "analytics_container_subnet_id" {
  description = "Databricks Container 서브넷 ID"
  type        = string
}

variable "analytics_container_subnet_name" {
  description = "Databricks Container 서브넷 이름"
  type        = string                                  # nsc-snet-analytics-container
}

variable "tags" {
  type = map(string)
}
