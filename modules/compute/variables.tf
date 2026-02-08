variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "aks_subnet_id" {
  description = "Subnet ID for AKS default node pool"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID for OMS agent"
  type        = string
}
