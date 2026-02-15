# =============================================================================
# Monitoring Module — Log Analytics + Application Insights
# Source of Truth: README.md §7.1
# Naming Convention: README.md §7.4
# =============================================================================

# Log Analytics Workspace (§7.1: Pay-per-GB, 30일 Retention)
resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.project_prefix}-law-${var.environment}"  # 예: nsc-law-dev
  resource_group_name = var.resource_group_name          # RG에 배치
  location            = var.location                     # Korea Central
  sku                 = "PerGB2018"                      # Pay-per-GB 요금제
  retention_in_days   = 30                               # §7.1: 30일 보존
  tags                = var.tags                         # 공통 태그
}

# Application Insights (§7.1: Workspace-based)
resource "azurerm_application_insights" "main" {
  name                = "${var.project_prefix}-ai-${var.environment}"   # 예: nsc-ai-dev
  resource_group_name = var.resource_group_name          # RG에 배치
  location            = var.location                     # Korea Central
  workspace_id        = azurerm_log_analytics_workspace.main.id  # LAW 통합 모드
  application_type    = "web"                            # 웹 애플리케이션 APM
  tags                = var.tags                         # 공통 태그
}
