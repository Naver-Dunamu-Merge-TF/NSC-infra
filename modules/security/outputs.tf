# =============================================================================
# Security Module — Outputs
# =============================================================================

output "key_vault_id" {
  description = "Key Vault ID"
  value       = azurerm_key_vault.main.id
}

output "key_vault_uri" {
  description = "Key Vault URI"
  value       = azurerm_key_vault.main.vault_uri
}

output "acr_id" {
  description = "Container Registry ID"
  value       = azurerm_container_registry.main.id
}

output "acr_login_server" {
  description = "ACR Login Server URL"
  value       = azurerm_container_registry.main.login_server
}

output "dns_zone_ids" {
  description = "Private DNS Zone ID 맵"
  value = {
    sql        = azurerm_private_dns_zone.sql.id
    postgresql = azurerm_private_dns_zone.postgresql.id
    ledger     = azurerm_private_dns_zone.ledger.id
    keyvault   = azurerm_private_dns_zone.keyvault.id
    acr        = azurerm_private_dns_zone.acr.id
    eventhubs  = azurerm_private_dns_zone.eventhubs.id
    adls       = azurerm_private_dns_zone.adls.id
  }
}
