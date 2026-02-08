# =============================================================================
# Messaging Module - Event Hubs (Messaging Subnet)
# =============================================================================
resource "azurerm_eventhub_namespace" "evh" {
  name                = "evh-ns-streaming-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
}
