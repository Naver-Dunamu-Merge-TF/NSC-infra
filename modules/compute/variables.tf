# =============================================================================
# Compute Module — Variables
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

variable "aks_subnet_id" {
  description = "AKS Node Pool 배치 서브넷"
  type        = string                                  # module.network.subnet_ids["app"]
}

variable "log_analytics_workspace_id" {
  description = "OMS Agent용 LAW ID"
  type        = string                                  # module.monitoring.law_id
}

variable "tags" {
  type = map(string)
}
