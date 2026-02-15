# =============================================================================
# Diagnostics Module — Diagnostic Settings (§6)
# 모든 주요 리소스 → Log Analytics Workspace 로그 전송
# =============================================================================

# AKS Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "aks" {
  name                       = "diag-aks"               # AKS 진단 설정
  target_resource_id         = var.aks_id                # AKS Cluster
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log { category = "kube-apiserver" }            # API 서버 로그
  enabled_log { category = "kube-controller-manager" }   # 컨트롤러 로그
  enabled_log { category = "kube-scheduler" }            # 스케줄러 로그
  enabled_log { category = "kube-audit-admin" }          # 감사 로그

  metric { category = "AllMetrics" }                     # 모든 메트릭
}

# AppGW Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "appgw" {
  name                       = "diag-appgw"              # AppGW 진단 설정
  target_resource_id         = var.appgw_id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log { category = "ApplicationGatewayAccessLog" }     # 접근 로그
  enabled_log { category = "ApplicationGatewayFirewallLog" }   # WAF 로그

  metric { category = "AllMetrics" }
}

# Firewall Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "firewall" {
  name                       = "diag-firewall"           # Firewall 진단 설정
  target_resource_id         = var.firewall_id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log { category = "AzureFirewallApplicationRule" }    # 앱 규칙 로그
  enabled_log { category = "AzureFirewallNetworkRule" }        # 네트워크 규칙 로그
  enabled_log { category = "AzureFirewallDnsProxy" }           # DNS 프록시 로그

  metric { category = "AllMetrics" }
}

# Key Vault Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "keyvault" {
  name                       = "diag-keyvault"           # KV 진단 설정
  target_resource_id         = var.key_vault_id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log { category = "AuditEvent" }                # 감사 이벤트

  metric { category = "AllMetrics" }
}

# SQL Database Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "sqldb" {
  name                       = "diag-sqldb"              # SQL DB 진단 설정
  target_resource_id         = var.sql_database_id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log { category = "SQLSecurityAuditEvents" }    # 보안 감사
  enabled_log { category = "QueryStoreRuntimeStatistics" }  # 쿼리 성능

  metric { category = "AllMetrics" }
}
