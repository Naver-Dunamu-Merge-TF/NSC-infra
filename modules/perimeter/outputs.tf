output "firewall_id" {
  value = azurerm_firewall.firewall.id
}

output "appgw_id" {
  value = azurerm_application_gateway.appgw.id
}
