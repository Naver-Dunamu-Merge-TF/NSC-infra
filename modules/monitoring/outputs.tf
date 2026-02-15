# =============================================================================
# Monitoring Module — Outputs
# =============================================================================

output "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID (Diagnostic Settings용)"
  value       = azurerm_log_analytics_workspace.main.id          # Phase 4 diagnostics에서 참조
}

output "log_analytics_workspace_name" {
  description = "Log Analytics Workspace Name"
  value       = azurerm_log_analytics_workspace.main.name        # 리소스 참조용
}

output "application_insights_id" {
  description = "Application Insights ID"
  value       = azurerm_application_insights.main.id             # APM 연동용
}

output "application_insights_instrumentation_key" {
  description = "Application Insights Instrumentation Key"
  value       = azurerm_application_insights.main.instrumentation_key  # 앱에서 SDK 연동 시 사용
  sensitive   = true                                     # 민감 정보 마스킹
}
