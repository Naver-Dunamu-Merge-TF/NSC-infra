# =============================================================================
# Diagnostics Module - Diagnostic Settings for Security Resources
# =============================================================================

resource "azurerm_monitor_diagnostic_setting" "firewall_diag" {
  name                       = "firewall-diagnostics"
  target_resource_id         = var.firewall_id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AzureFirewallApplicationRule"
  }

  enabled_log {
    category = "AzureFirewallNetworkRule"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

resource "azurerm_monitor_diagnostic_setting" "appgw_diag" {
  name                       = "appgw-diagnostics"
  target_resource_id         = var.appgw_id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "ApplicationGatewayAccessLog"
  }

  enabled_log {
    category = "ApplicationGatewayFirewallLog"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
