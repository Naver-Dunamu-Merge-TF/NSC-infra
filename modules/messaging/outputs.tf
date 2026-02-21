# =============================================================================
# Messaging Module — Outputs
# =============================================================================

output "namespace_id" {
  value = azurerm_eventhub_namespace.main.id
}

output "namespace_name" {
  value = azurerm_eventhub_namespace.main.name
}
