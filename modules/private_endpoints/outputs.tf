# =============================================================================
# Private Endpoints Module — Outputs
# =============================================================================

output "private_endpoint_ids" {
  description = "Private Endpoint ID 맵"
  value = {
    sql        = azurerm_private_endpoint.sql.id
    postgresql = azurerm_private_endpoint.postgresql.id
    # ledger  — PE 비활성화 (구독 feature 미등록)
    keyvault   = azurerm_private_endpoint.keyvault.id
    acr        = azurerm_private_endpoint.acr.id
    eventhubs  = azurerm_private_endpoint.eventhubs.id
    adls       = azurerm_private_endpoint.adls.id
  }
}
