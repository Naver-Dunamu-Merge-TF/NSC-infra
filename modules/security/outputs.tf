output "key_vault_id" {
  value = azurerm_key_vault.kv.id
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "acr_id" {
  description = "Container Registry ID for role assignment"
  value       = azurerm_container_registry.acr.id
}
