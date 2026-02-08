# =============================================================================
# Data Module - SQL Server, PostgreSQL, Data Lake Storage
# =============================================================================

# 14. Azure Data Lake Storage Gen2 (Analytics Subnet)
resource "azurerm_storage_account" "datalake" {
  name                     = "adls${var.suffix}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true  # Hierarchical namespace for Data Lake
  
  # Security settings (Checkov fixes)
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false
  public_network_access_enabled   = false
  
  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }
  
  blob_properties {
    delete_retention_policy {
      days = 7
    }
    container_delete_retention_policy {
      days = 7
    }
  }
}

# 8. Azure SQL Database (Data Subnet)
resource "azurerm_mssql_server" "sql" {
  name                         = "sql-platform-${var.suffix}"
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = "ComplexP@ssword123!"
  
  # Security settings (Checkov fixes)
  minimum_tls_version          = "1.2"
  public_network_access_enabled = false
}

# SQL Server Auditing Policy
resource "azurerm_mssql_server_extended_auditing_policy" "sql_audit" {
  server_id              = azurerm_mssql_server.sql.id
  storage_endpoint       = azurerm_storage_account.datalake.primary_blob_endpoint
  retention_in_days      = 90
  log_monitoring_enabled = true
}

# 13. Azure Database for PostgreSQL (Data Subnet)
resource "azurerm_postgresql_flexible_server" "postgres" {
  name                   = "psql-platform-${var.suffix}"
  resource_group_name    = var.resource_group_name
  location               = var.location
  version                = "14"
  administrator_login    = "psqladmin"
  administrator_password = "ComplexP@ssword456!"
  storage_mb             = 32768
  sku_name               = "B_Standard_B1ms"
  zone                   = "1"
}

# 15. Azure Databricks Workspace (Analytics Subnet)
resource "azurerm_databricks_workspace" "databricks" {
  name                = "dbw-platform-${var.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "standard"
}

# 16. Azure Confidential Ledger (Data Subnet)
resource "azurerm_confidential_ledger" "ledger" {
  name                = "acl-platform-${var.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  ledger_type         = "Private"

  azuread_based_service_principal {
    principal_id = var.current_object_id
    tenant_id    = var.tenant_id
    ledger_role_name = "Administrator"
  }
}
