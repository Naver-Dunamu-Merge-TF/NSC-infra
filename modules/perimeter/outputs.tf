# =============================================================================
# Perimeter Module — Outputs
# =============================================================================

output "appgw_id" {
  value = azurerm_application_gateway.main.id            # AppGW ID
}

output "bastion_id" {
  value = azurerm_bastion_host.main.id                   # Bastion ID
}

output "firewall_id" {
  value = azurerm_firewall.main.id                       # Firewall ID
}

output "firewall_private_ip" {
  value = azurerm_firewall.main.ip_configuration[0].private_ip_address  # UDR next hop용
}

output "firewall_public_ip" {
  value = azurerm_public_ip.firewall.ip_address          # SNAT Public IP
}
