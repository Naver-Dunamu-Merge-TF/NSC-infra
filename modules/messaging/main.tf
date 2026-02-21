# =============================================================================
# Messaging Module — Event Hubs (§7.1)
# Source of Truth: README.md §7.1
# =============================================================================

# Event Hubs Namespace (§7.1: Standard, 2 TU, AutoInflate 10)
resource "azurerm_eventhub_namespace" "main" {
  name                     = "${var.project_prefix}-evh-${var.environment}"  # nsc-evh-dev
  resource_group_name      = var.resource_group_name
  location                 = var.location                # Korea Central
  sku                      = "Standard"                  # §7.1: Standard
  capacity                 = 2                           # §7.1: 2 TU (Throughput Units)
  auto_inflate_enabled     = true
  maximum_throughput_units = 10
  zone_redundant           = true                        # Zone Redundant
  tags                     = var.tags
}

resource "azurerm_eventhub" "order_events" {
  name                = "order-events"
  namespace_name      = azurerm_eventhub_namespace.main.name
  resource_group_name = var.resource_group_name
  partition_count     = 4
  message_retention   = 7
}

resource "azurerm_eventhub" "cdc_events" {
  name                = "cdc-events"
  namespace_name      = azurerm_eventhub_namespace.main.name
  resource_group_name = var.resource_group_name
  partition_count     = 4
  message_retention   = 7
}

# Consumer Group — Sync Consumer
resource "azurerm_eventhub_consumer_group" "sync_consumer" {
  name                = "sync-consumer"
  namespace_name      = azurerm_eventhub_namespace.main.name
  eventhub_name       = azurerm_eventhub.order_events.name
  resource_group_name = var.resource_group_name
}

# Consumer Group — Analytics Consumer
resource "azurerm_eventhub_consumer_group" "analytics_consumer" {
  name                = "analytics-consumer"
  namespace_name      = azurerm_eventhub_namespace.main.name
  eventhub_name       = azurerm_eventhub.cdc_events.name
  resource_group_name = var.resource_group_name
}
