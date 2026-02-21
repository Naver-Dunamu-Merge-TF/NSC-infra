# =============================================================================
# Data Module — Outputs
# =============================================================================

output "sql_server_id" {
  value = azurerm_mssql_server.main.id
}

output "sql_server_fqdn" {
  value = azurerm_mssql_server.main.fully_qualified_domain_name
}

output "postgresql_server_id" {
  value = azurerm_postgresql_flexible_server.main.id
}

output "postgresql_server_fqdn" {
  value = azurerm_postgresql_flexible_server.main.fqdn
}

output "sql_database_id" {
  value = azurerm_mssql_database.main.id
}

output "ledger_id" {
  value = azurerm_confidential_ledger.main.id
}
