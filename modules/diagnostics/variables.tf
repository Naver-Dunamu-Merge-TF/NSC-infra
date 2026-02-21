# =============================================================================
# Diagnostics Module — Variables
# =============================================================================

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID"
  type        = string
}

variable "aks_id" {
  description = "AKS Cluster ID"
  type        = string
}

variable "appgw_id" {
  description = "Application Gateway ID"
  type        = string
}

variable "firewall_id" {
  description = "Azure Firewall ID"
  type        = string
}

variable "key_vault_id" {
  description = "Key Vault ID"
  type        = string
}

variable "sql_database_id" {
  description = "SQL Database ID"
  type        = string
}
