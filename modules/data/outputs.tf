output "datalake_primary_blob_endpoint" {
  value = azurerm_storage_account.datalake.primary_blob_endpoint
}

output "sql_server_name" {
  value = azurerm_mssql_server.sql.name
}

output "postgres_server_name" {
  value = azurerm_postgresql_flexible_server.postgres.name
}
