# =============================================================================
# Security Module — Key Vault + ACR + Private DNS Zones
# Source of Truth: README.md §5.2, §7.1, §7.3, §4.3
# =============================================================================

resource "azurerm_key_vault" "main" {
  name                          = "${var.project_prefix}-kv-${var.environment}"   # nsc-kv-dev (§7.4)
  resource_group_name           = var.resource_group_name
  location                      = var.location                 # Korea Central
  tenant_id                     = var.tenant_id
  sku_name                      = "standard"                   # §7.1: Standard
  soft_delete_retention_days    = 90
  purge_protection_enabled      = true
  enable_rbac_authorization     = true
  public_network_access_enabled = false
  tags                          = var.tags
}

# Container Registry (§7.1: Premium, 500GB, Content Trust)
resource "azurerm_container_registry" "main" {
  name                          = "${var.project_prefix}acr${var.environment}${var.suffix}"  # nscacrdev3a7k
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = "Premium"
  admin_enabled                 = false
  public_network_access_enabled = false
  data_endpoint_enabled         = true                     # CKV_AZURE_166: dedicated data endpoint

  retention_policy {                                        # CKV_AZURE_164: image retention
    days    = 30
    enabled = true
  }

  trust_policy {                                            # CKV_AZURE_163: content trust
    enabled = true
  }

  tags = var.tags
}

# =============================================================================
# =============================================================================

resource "azurerm_private_dns_zone" "sql" {
  name                = "privatelink.database.windows.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone" "postgresql" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone" "ledger" {
  name                = "privatelink.confidential-ledger.azure.com"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone" "keyvault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone" "acr" {
  name                = "privatelink.azurecr.io"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone" "eventhubs" {
  name                = "privatelink.servicebus.windows.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone" "adls" {
  name                = "privatelink.dfs.core.windows.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# =============================================================================
# =============================================================================

resource "azurerm_private_dns_zone_virtual_network_link" "sql" {
  name                  = "vnet-link-sql"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.sql.name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgresql" {
  name                  = "vnet-link-postgresql"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.postgresql.name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "ledger" {
  name                  = "vnet-link-ledger"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.ledger.name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "keyvault" {
  name                  = "vnet-link-keyvault"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault.name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr" {
  name                  = "vnet-link-acr"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.acr.name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "eventhubs" {
  name                  = "vnet-link-eventhubs"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.eventhubs.name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "adls" {
  name                  = "vnet-link-adls"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.adls.name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
}
