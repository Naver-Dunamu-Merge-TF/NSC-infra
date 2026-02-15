# =============================================================================
# Analytics Module — Outputs
# =============================================================================

output "databricks_workspace_id" {
  value = azurerm_databricks_workspace.main.id           # Databricks ID
}

output "databricks_workspace_url" {
  value = azurerm_databricks_workspace.main.workspace_url  # Databricks URL
}

output "adls_storage_id" {
  value = azurerm_storage_account.adls.id                # PE 생성용
}

output "adls_storage_name" {
  value = azurerm_storage_account.adls.name              # 참조용
}
