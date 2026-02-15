# =============================================================================
# Security Module — Key Vault + ACR + Private DNS Zones
# Source of Truth: README.md §5.2, §7.1, §7.3, §4.3
# =============================================================================

# Key Vault (§7.1: Standard, Soft Delete 90일, Purge Protection)
resource "azurerm_key_vault" "main" {
  name                          = "${var.project_prefix}-kv-${var.environment}"   # nsc-kv-dev (§7.4)
  resource_group_name           = var.resource_group_name      # RG 참조
  location                      = var.location                 # Korea Central
  tenant_id                     = var.tenant_id                # Azure AD 테넌트
  sku_name                      = "standard"                   # §7.1: Standard
  soft_delete_retention_days    = 90                            # §5.2: 90일 Soft Delete
  purge_protection_enabled      = true                         # §5.2: Purge Protection 활성화
  enable_rbac_authorization     = true                         # §5.2: RBAC 접근 방식
  public_network_access_enabled = false                        # §7.3: PE Only 접근
  tags                          = var.tags                     # 공통 태그
}

# Container Registry (§7.1: Premium, 500GB, Content Trust)
# §7.4 예외: 하이픈 불가 → nscacr{env}{suffix}
resource "azurerm_container_registry" "main" {
  name                          = "${var.project_prefix}acr${var.environment}${var.suffix}"  # nscacrdev3a7k
  resource_group_name           = var.resource_group_name      # RG 참조
  location                      = var.location                 # Korea Central
  sku                           = "Premium"                    # §7.1: Premium (PE 지원, Geo-Rep)
  admin_enabled                 = false                        # Admin 비활성화 (MI 사용)
  public_network_access_enabled = false                        # §7.3: PE Only 접근
  tags                          = var.tags                     # 공통 태그
}

# =============================================================================
# Private DNS Zones (§4.3 — PE당 1개, 총 7개)
# =============================================================================

resource "azurerm_private_dns_zone" "sql" {
  name                = "privatelink.database.windows.net"             # SQL DB용
  resource_group_name = var.resource_group_name           # RG 참조
  tags                = var.tags                          # 공통 태그
}

resource "azurerm_private_dns_zone" "postgresql" {
  name                = "privatelink.postgres.database.azure.com"      # PostgreSQL용
  resource_group_name = var.resource_group_name           # RG 참조
  tags                = var.tags                          # 공통 태그
}

resource "azurerm_private_dns_zone" "ledger" {
  name                = "privatelink.confidential-ledger.azure.com"    # Confidential Ledger용
  resource_group_name = var.resource_group_name           # RG 참조
  tags                = var.tags                          # 공통 태그
}

resource "azurerm_private_dns_zone" "keyvault" {
  name                = "privatelink.vaultcore.azure.net"              # Key Vault용
  resource_group_name = var.resource_group_name           # RG 참조
  tags                = var.tags                          # 공통 태그
}

resource "azurerm_private_dns_zone" "acr" {
  name                = "privatelink.azurecr.io"                       # Container Registry용
  resource_group_name = var.resource_group_name           # RG 참조
  tags                = var.tags                          # 공통 태그
}

resource "azurerm_private_dns_zone" "eventhubs" {
  name                = "privatelink.servicebus.windows.net"           # Event Hubs용
  resource_group_name = var.resource_group_name           # RG 참조
  tags                = var.tags                          # 공통 태그
}

resource "azurerm_private_dns_zone" "adls" {
  name                = "privatelink.dfs.core.windows.net"             # ADLS Gen2용
  resource_group_name = var.resource_group_name           # RG 참조
  tags                = var.tags                          # 공통 태그
}

# =============================================================================
# Private DNS Zone → VNet Links (DNS 이름 해석 활성화)
# =============================================================================

resource "azurerm_private_dns_zone_virtual_network_link" "sql" {
  name                  = "vnet-link-sql"                 # SQL DNS → VNet 링크
  resource_group_name   = var.resource_group_name         # RG 참조
  private_dns_zone_name = azurerm_private_dns_zone.sql.name  # SQL DNS 존
  virtual_network_id    = var.vnet_id                     # VNet 연결
  registration_enabled  = false                           # Auto-Registration 비활성화 (§7.1)
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgresql" {
  name                  = "vnet-link-postgresql"          # PostgreSQL DNS → VNet 링크
  resource_group_name   = var.resource_group_name         # RG 참조
  private_dns_zone_name = azurerm_private_dns_zone.postgresql.name  # PG DNS 존
  virtual_network_id    = var.vnet_id                     # VNet 연결
  registration_enabled  = false                           # Auto-Registration 비활성화
}

resource "azurerm_private_dns_zone_virtual_network_link" "ledger" {
  name                  = "vnet-link-ledger"              # Ledger DNS → VNet 링크
  resource_group_name   = var.resource_group_name         # RG 참조
  private_dns_zone_name = azurerm_private_dns_zone.ledger.name  # Ledger DNS 존
  virtual_network_id    = var.vnet_id                     # VNet 연결
  registration_enabled  = false                           # Auto-Registration 비활성화
}

resource "azurerm_private_dns_zone_virtual_network_link" "keyvault" {
  name                  = "vnet-link-keyvault"            # KV DNS → VNet 링크
  resource_group_name   = var.resource_group_name         # RG 참조
  private_dns_zone_name = azurerm_private_dns_zone.keyvault.name  # KV DNS 존
  virtual_network_id    = var.vnet_id                     # VNet 연결
  registration_enabled  = false                           # Auto-Registration 비활성화
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr" {
  name                  = "vnet-link-acr"                 # ACR DNS → VNet 링크
  resource_group_name   = var.resource_group_name         # RG 참조
  private_dns_zone_name = azurerm_private_dns_zone.acr.name  # ACR DNS 존
  virtual_network_id    = var.vnet_id                     # VNet 연결
  registration_enabled  = false                           # Auto-Registration 비활성화
}

resource "azurerm_private_dns_zone_virtual_network_link" "eventhubs" {
  name                  = "vnet-link-eventhubs"           # EH DNS → VNet 링크
  resource_group_name   = var.resource_group_name         # RG 참조
  private_dns_zone_name = azurerm_private_dns_zone.eventhubs.name  # EH DNS 존
  virtual_network_id    = var.vnet_id                     # VNet 연결
  registration_enabled  = false                           # Auto-Registration 비활성화
}

resource "azurerm_private_dns_zone_virtual_network_link" "adls" {
  name                  = "vnet-link-adls"                # ADLS DNS → VNet 링크
  resource_group_name   = var.resource_group_name         # RG 참조
  private_dns_zone_name = azurerm_private_dns_zone.adls.name  # ADLS DNS 존
  virtual_network_id    = var.vnet_id                     # VNet 연결
  registration_enabled  = false                           # Auto-Registration 비활성화
}
