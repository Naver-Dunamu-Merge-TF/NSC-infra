# =============================================================================
# Data Module — Outputs
# =============================================================================

output "sql_server_id" {
  value = azurerm_mssql_server.main.id                  # PE 생성용
}

output "sql_server_fqdn" {
  value = azurerm_mssql_server.main.fully_qualified_domain_name  # 연결 문자열용
}

output "postgresql_server_id" {
  value = azurerm_postgresql_flexible_server.main.id    # PE 생성용
}

output "postgresql_server_fqdn" {
  value = azurerm_postgresql_flexible_server.main.fqdn  # 연결 문자열용
}

output "sql_database_id" {
  value = azurerm_mssql_database.main.id                # Diagnostics 진단 설정용
}

output "ledger_id" {
  value = azurerm_confidential_ledger.main.id           # PE 생성용
}
