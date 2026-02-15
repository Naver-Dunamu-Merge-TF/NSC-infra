# =============================================================================
# Messaging Module — Event Hubs (§7.1)
# Source of Truth: README.md §7.1
# =============================================================================

# Event Hubs Namespace (§7.1: Standard, 2 TU, AutoInflate 10)
resource "azurerm_eventhub_namespace" "main" {
  name                     = "${var.project_prefix}-evh-${var.environment}"  # nsc-evh-dev
  resource_group_name      = var.resource_group_name     # RG 참조
  location                 = var.location                # Korea Central
  sku                      = "Standard"                  # §7.1: Standard
  capacity                 = 2                           # §7.1: 2 TU (Throughput Units)
  auto_inflate_enabled     = true                        # §7.1: AutoInflate 활성화
  maximum_throughput_units = 10                           # §7.1: 최대 10 TU
  zone_redundant           = true                        # Zone Redundant
  tags                     = var.tags
}

# Event Hub — 주문 이벤트 (Kafka Protocol)
resource "azurerm_eventhub" "order_events" {
  name                = "order-events"                   # 주문 이벤트 토픽
  namespace_name      = azurerm_eventhub_namespace.main.name
  resource_group_name = var.resource_group_name
  partition_count     = 4                                # 4파티션 (병렬 처리)
  message_retention   = 7                                # 7일 보존
}

# Event Hub — CDC 이벤트
resource "azurerm_eventhub" "cdc_events" {
  name                = "cdc-events"                     # CDC 변경 데이터 스트림
  namespace_name      = azurerm_eventhub_namespace.main.name
  resource_group_name = var.resource_group_name
  partition_count     = 4                                # 4파티션
  message_retention   = 7                                # 7일 보존
}

# Consumer Group — Sync Consumer
resource "azurerm_eventhub_consumer_group" "sync_consumer" {
  name                = "sync-consumer"                  # 동기화 컨슈머
  namespace_name      = azurerm_eventhub_namespace.main.name
  eventhub_name       = azurerm_eventhub.order_events.name
  resource_group_name = var.resource_group_name
}

# Consumer Group — Analytics Consumer
resource "azurerm_eventhub_consumer_group" "analytics_consumer" {
  name                = "analytics-consumer"             # 분석 컨슈머
  namespace_name      = azurerm_eventhub_namespace.main.name
  eventhub_name       = azurerm_eventhub.cdc_events.name
  resource_group_name = var.resource_group_name
}
