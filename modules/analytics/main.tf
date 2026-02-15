# =============================================================================
# Analytics Module — Databricks + ADLS Gen2
# Source of Truth: README.md §7.1
# =============================================================================

# Databricks NSGs (VNet Injection 필수 — Analytics 서브넷용)
resource "azurerm_network_security_group" "analytics_host" {
  name                = "${var.project_prefix}-nsg-analytics-host"     # nsc-nsg-analytics-host
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_network_security_group" "analytics_container" {
  name                = "${var.project_prefix}-nsg-analytics-container"  # nsc-nsg-analytics-container
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

# NSG → Subnet Association (Databricks 필수)
resource "azurerm_subnet_network_security_group_association" "analytics_host" {
  subnet_id                 = var.analytics_host_subnet_id       # Analytics Host
  network_security_group_id = azurerm_network_security_group.analytics_host.id
}

resource "azurerm_subnet_network_security_group_association" "analytics_container" {
  subnet_id                 = var.analytics_container_subnet_id  # Analytics Container
  network_security_group_id = azurerm_network_security_group.analytics_container.id
}

# Databricks (§7.1: Premium, DS3_v2, AutoScale 2-8, VNet Injection)
resource "azurerm_databricks_workspace" "main" {
  name                        = "${var.project_prefix}-dbw-${var.environment}"  # nsc-dbw-dev
  resource_group_name         = var.resource_group_name
  location                    = var.location
  sku                         = "premium"                # §7.1: Premium SKU
  managed_resource_group_name = "${var.project_prefix}-dbw-managed-rg-${var.environment}"  # Managed RG

  custom_parameters {
    virtual_network_id                                   = var.vnet_id                     # VNet 참조
    public_subnet_name                                   = var.analytics_host_subnet_name   # Host 서브넷
    public_subnet_network_security_group_association_id   = azurerm_subnet_network_security_group_association.analytics_host.id
    private_subnet_name                                  = var.analytics_container_subnet_name  # Container 서브넷
    private_subnet_network_security_group_association_id  = azurerm_subnet_network_security_group_association.analytics_container.id
    no_public_ip                                         = true   # Public IP 비활성화 (보안)
  }

  tags = var.tags
}

# ADLS Gen2 (§7.1: Standard LRS, Hot, HNS)
# §7.4 예외: 하이픈 불가 → nscst{env}{suffix}
resource "azurerm_storage_account" "adls" {
  name                          = "${var.project_prefix}st${var.environment}${var.suffix}"  # nscstdev3a7k
  resource_group_name           = var.resource_group_name
  location                      = var.location
  account_tier                  = "Standard"             # §7.1: Standard
  account_replication_type      = "LRS"                  # §7.1: LRS
  account_kind                  = "StorageV2"            # StorageV2 필수 (ADLS Gen2)
  is_hns_enabled                = true                   # §7.1: HNS (Hierarchical Namespace)
  min_tls_version               = "TLS1_2"               # §7.3: TLS 1.2
  public_network_access_enabled = false                  # PE Only
  tags                          = var.tags
}
