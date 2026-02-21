# =============================================================================
# Diagnostics Module — Diagnostic Settings (§6)
# =============================================================================

# AKS Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "aks" {
  name                       = "diag-aks"
  target_resource_id         = var.aks_id                # AKS Cluster
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log { category = "kube-apiserver" }
  enabled_log { category = "kube-controller-manager" }
  enabled_log { category = "kube-scheduler" }
  enabled_log { category = "kube-audit-admin" }

  metric { category = "AllMetrics" }
}

# AppGW Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "appgw" {
  name                       = "diag-appgw"
  target_resource_id         = var.appgw_id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log { category = "ApplicationGatewayAccessLog" }
  enabled_log { category = "ApplicationGatewayFirewallLog" }

  metric { category = "AllMetrics" }
}

# Firewall Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "firewall" {
  name                       = "diag-firewall"
  target_resource_id         = var.firewall_id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log { category = "AzureFirewallApplicationRule" }
  enabled_log { category = "AzureFirewallNetworkRule" }
  enabled_log { category = "AzureFirewallDnsProxy" }

  metric { category = "AllMetrics" }
}

# Key Vault Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "keyvault" {
  name                       = "diag-keyvault"
  target_resource_id         = var.key_vault_id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log { category = "AuditEvent" }

  metric { category = "AllMetrics" }
}

# SQL Database Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "sqldb" {
  name                       = "diag-sqldb"
  target_resource_id         = var.sql_database_id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log { category = "SQLSecurityAuditEvents" }
  enabled_log { category = "QueryStoreRuntimeStatistics" }

  metric { category = "AllMetrics" }
}
