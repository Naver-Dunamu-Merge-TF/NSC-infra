# =============================================================================
# Private Endpoints Module — 7 PEs (§4.3)
# Source of Truth: README.md §4.3, §7.2
# =============================================================================

resource "azurerm_private_endpoint" "sql" {
  name                = "${var.project_prefix}-pe-sqldb"       # nsc-pe-sqldb
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.subnet_ids["data"]

  private_service_connection {
    name                           = "psc-sqldb"
    private_connection_resource_id = var.sql_server_id          # SQL Server ID
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "dns-sqldb"
    private_dns_zone_ids = [var.dns_zone_ids["sql"]]           # SQL DNS Zone
  }

  tags = var.tags
}

resource "azurerm_private_endpoint" "postgresql" {
  name                = "${var.project_prefix}-pe-pg"          # nsc-pe-pg
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.subnet_ids["data"]

  private_service_connection {
    name                           = "psc-pg"
    private_connection_resource_id = var.postgresql_server_id
    subresource_names              = ["postgresqlServer"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "dns-pg"
    private_dns_zone_ids = [var.dns_zone_ids["postgresql"]]
  }

  tags = var.tags
}

# Confidential Ledger PE — 구독에 AllowPrivateEndpoints feature 미등록
# resource "azurerm_private_endpoint" "ledger" {
#   name                = "${var.project_prefix}-pe-ledger"
#   resource_group_name = var.resource_group_name
#   location            = var.location
#   subnet_id           = var.subnet_ids["data"]
#
#   private_service_connection {
#     name                           = "psc-ledger"
#     private_connection_resource_id = var.ledger_id
#     subresource_names              = ["Ledger"]
#     is_manual_connection           = false
#   }
#
#   private_dns_zone_group {
#     name                 = "dns-ledger"
#     private_dns_zone_ids = [var.dns_zone_ids["ledger"]]
#   }
#
#   tags = var.tags
# }

resource "azurerm_private_endpoint" "keyvault" {
  name                = "${var.project_prefix}-pe-kv"          # nsc-pe-kv
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.subnet_ids["security"]

  private_service_connection {
    name                           = "psc-kv"
    private_connection_resource_id = var.key_vault_id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "dns-kv"
    private_dns_zone_ids = [var.dns_zone_ids["keyvault"]]
  }

  tags = var.tags
}

resource "azurerm_private_endpoint" "acr" {
  name                = "${var.project_prefix}-pe-acr"         # nsc-pe-acr
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.subnet_ids["security"]

  private_service_connection {
    name                           = "psc-acr"
    private_connection_resource_id = var.acr_id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "dns-acr"
    private_dns_zone_ids = [var.dns_zone_ids["acr"]]
  }

  tags = var.tags
}

resource "azurerm_private_endpoint" "eventhubs" {
  name                = "${var.project_prefix}-pe-evh"         # nsc-pe-evh
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.subnet_ids["messaging"]

  private_service_connection {
    name                           = "psc-evh"
    private_connection_resource_id = var.eventhubs_namespace_id
    subresource_names              = ["namespace"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "dns-evh"
    private_dns_zone_ids = [var.dns_zone_ids["eventhubs"]]
  }

  tags = var.tags
}

resource "azurerm_private_endpoint" "adls" {
  name                = "${var.project_prefix}-pe-adls"        # nsc-pe-adls
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.subnet_ids["data"]             # analytics_host는 Databricks delegation

  private_service_connection {
    name                           = "psc-adls"
    private_connection_resource_id = var.adls_storage_id
    subresource_names              = ["dfs"]                   # ADLS Gen2 = dfs
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "dns-adls"
    private_dns_zone_ids = [var.dns_zone_ids["adls"]]
  }

  tags = var.tags
}
