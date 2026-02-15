# =============================================================================
# Data Module — SQL DB + PostgreSQL + Confidential Ledger
# Source of Truth: README.md §7.1, §7.3
# =============================================================================

# SQL Server (§7.1: General Purpose, vCore 2, Zone Redundant)
resource "azurerm_mssql_server" "main" {
  name                          = "${var.project_prefix}-sql-${var.environment}"  # nsc-sql-dev
  resource_group_name           = var.resource_group_name      # RG 참조
  location                      = var.location                 # Korea Central
  version                       = "12.0"                       # SQL Server 버전
  minimum_tls_version           = "1.2"                        # §7.3: TLS 1.2
  public_network_access_enabled = false                        # PE Only

  azuread_administrator {
    login_username              = "nsc-sql-admin"              # AAD 관리자
    object_id                   = var.current_object_id        # 현재 사용자 OID
    tenant_id                   = var.tenant_id                # AAD 테넌트
    azuread_authentication_only = true                         # SQL 인증 비활성화
  }

  tags = var.tags
}

# SQL Database (§7.1: GP vCore 2, 32GB, Zone Redundant)
resource "azurerm_mssql_database" "main" {
  name                                = "nsc-account-commerce-db"  # 트랜잭션 DB
  server_id                           = azurerm_mssql_server.main.id
  sku_name                            = "GP_Gen5_2"            # General Purpose vCore 2
  max_size_gb                         = 32                     # 32GB
  zone_redundant                      = true                   # Zone Redundant
  storage_account_type                = "Zone"                 # Zone 스토리지
  transparent_data_encryption_enabled = true                   # TDE AES-256

  short_term_retention_policy {
    retention_days = 7                                         # 자동 백업 7일
  }

  tags = var.tags
}

# PostgreSQL Flexible Server (§7.1: Burstable B1ms, 32GB)
resource "azurerm_postgresql_flexible_server" "main" {
  name                   = "${var.project_prefix}-pg-${var.environment}"  # nsc-pg-dev
  resource_group_name    = var.resource_group_name
  location               = var.location
  version                = "14"                                # PG 14
  administrator_login    = "nscpgadmin"                        # 초기 관리자
  administrator_password = var.pg_admin_password               # KV에서 관리
  sku_name               = "B_Standard_B1ms"                   # Burstable B1ms
  storage_mb             = 32768                               # 32GB

  authentication {
    active_directory_auth_enabled = true                       # AAD 인증
    password_auth_enabled         = true                       # 초기용
    tenant_id                     = var.tenant_id
  }

  tags = var.tags
}

# Confidential Ledger (§7.1: Standard, Append-Only)
resource "azurerm_confidential_ledger" "main" {
  name                = "${var.project_prefix}-cl-${var.environment}"  # nsc-cl-dev
  resource_group_name = var.resource_group_name
  location            = var.location
  ledger_type         = "Public"                               # Public Ledger

  azuread_based_service_principal {
    principal_id     = var.current_object_id
    tenant_id        = var.tenant_id
    ledger_role_name = "Administrator"
  }

  tags = var.tags
}
