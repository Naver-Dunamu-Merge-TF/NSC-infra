# =============================================================================
# Monitoring Module — Log Analytics + Application Insights
# Source of Truth: README.md §7.1
# Naming Convention: README.md §7.4
# =============================================================================

resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.project_prefix}-law-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location                     # Korea Central
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

# Application Insights (§7.1: Workspace-based)
resource "azurerm_application_insights" "main" {
  name                = "${var.project_prefix}-ai-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location                     # Korea Central
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"
  tags                = var.tags
}
