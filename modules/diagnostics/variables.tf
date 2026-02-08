variable "firewall_id" {
  description = "Resource ID of the Azure Firewall"
  type        = string
}

variable "appgw_id" {
  description = "Resource ID of the Application Gateway"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID for diagnostics"
  type        = string
}
