# =============================================================================
# Messaging Module — Outputs
# =============================================================================

output "namespace_id" {
  value = azurerm_eventhub_namespace.main.id             # PE 생성용
}

output "namespace_name" {
  value = azurerm_eventhub_namespace.main.name            # 참조용
}
