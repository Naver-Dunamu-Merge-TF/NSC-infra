# =============================================================================
# Network Module — Outputs
# =============================================================================

output "vnet_id" {
  description = "VNet ID"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "VNet name"
  value       = azurerm_virtual_network.main.name
}

output "subnet_ids" {
  description = "모든 서브넷 ID 맵"
  value = {
    perimeter           = azurerm_subnet.perimeter.id
    bastion             = azurerm_subnet.bastion.id
    app                 = azurerm_subnet.app.id
    messaging           = azurerm_subnet.messaging.id
    data                = azurerm_subnet.data.id
    security            = azurerm_subnet.security.id
    analytics_host      = azurerm_subnet.analytics_host.id
    analytics_container = azurerm_subnet.analytics_container.id
    egress              = azurerm_subnet.egress.id
    admin               = azurerm_subnet.admin.id
  }
}

output "nsg_ids" {
  description = "NSG ID 맵"
  value = {
    perimeter = azurerm_network_security_group.perimeter.id
    app       = azurerm_network_security_group.app.id
    admin     = azurerm_network_security_group.admin.id
    messaging = azurerm_network_security_group.messaging.id
    data      = azurerm_network_security_group.data.id
    bastion   = azurerm_network_security_group.bastion.id
    security  = azurerm_network_security_group.security.id
  }
}
