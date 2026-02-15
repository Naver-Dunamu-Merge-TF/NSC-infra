# =============================================================================
# Security Module — Outputs
# =============================================================================

output "key_vault_id" {
  description = "Key Vault ID"
  value       = azurerm_key_vault.main.id               # RBAC Role Assignment용
}

output "key_vault_uri" {
  description = "Key Vault URI"
  value       = azurerm_key_vault.main.vault_uri         # SDK 연동용
}

output "acr_id" {
  description = "Container Registry ID"
  value       = azurerm_container_registry.main.id       # AKS AcrPull Role Assignment용
}

output "acr_login_server" {
  description = "ACR Login Server URL"
  value       = azurerm_container_registry.main.login_server  # Docker push/pull 주소
}

output "dns_zone_ids" {
  description = "Private DNS Zone ID 맵"
  value = {
    sql        = azurerm_private_dns_zone.sql.id         # SQL PE용
    postgresql = azurerm_private_dns_zone.postgresql.id  # PG PE용
    ledger     = azurerm_private_dns_zone.ledger.id      # Ledger PE용
    keyvault   = azurerm_private_dns_zone.keyvault.id    # KV PE용
    acr        = azurerm_private_dns_zone.acr.id         # ACR PE용
    eventhubs  = azurerm_private_dns_zone.eventhubs.id   # EH PE용
    adls       = azurerm_private_dns_zone.adls.id        # ADLS PE용
  }
}
