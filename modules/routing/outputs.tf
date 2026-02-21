# =============================================================================
# Routing Module — Outputs
# =============================================================================

output "route_table_ids" {
  description = "Route Table IDs"
  value = {
    app       = azurerm_route_table.app.id
    data      = azurerm_route_table.data.id
    analytics = azurerm_route_table.analytics.id
  }
}
