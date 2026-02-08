# =============================================================================
# Monitoring Module - Log Analytics, Application Insights
# =============================================================================

# 10. Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-platform-monitoring"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
}

# 11. Application Insights (Monitoring)
resource "azurerm_application_insights" "appinsights" {
  name                = "appi-platform-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.law.id
  application_type    = "web"
}
