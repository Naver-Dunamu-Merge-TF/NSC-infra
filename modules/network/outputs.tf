# =============================================================================
# Network Module — Outputs
# =============================================================================

output "vnet_id" {
  description = "VNet ID"
  value       = azurerm_virtual_network.main.id         # PE VNet Link, AKS 등에서 참조
}

output "vnet_name" {
  description = "VNet name"
  value       = azurerm_virtual_network.main.name       # 서브넷 추가 시 참조
}

output "subnet_ids" {
  description = "모든 서브넷 ID 맵"
  value = {
    perimeter           = azurerm_subnet.perimeter.id           # AppGW 배치용
    bastion             = azurerm_subnet.bastion.id             # Bastion 배치용
    app                 = azurerm_subnet.app.id                 # AKS Node Pool 배치용
    messaging           = azurerm_subnet.messaging.id           # Event Hubs PE 배치용
    data                = azurerm_subnet.data.id                # SQL/PG/Ledger PE 배치용
    security            = azurerm_subnet.security.id            # KV/ACR PE 배치용
    analytics_host      = azurerm_subnet.analytics_host.id      # Databricks Host 배치용
    analytics_container = azurerm_subnet.analytics_container.id # Databricks Container 배치용
    egress              = azurerm_subnet.egress.id              # Firewall 배치용
    admin               = azurerm_subnet.admin.id               # Admin UI 배치용
  }
}

output "nsg_ids" {
  description = "NSG ID 맵"
  value = {
    perimeter = azurerm_network_security_group.perimeter.id     # Perimeter NSG
    app       = azurerm_network_security_group.app.id           # Application NSG
    admin     = azurerm_network_security_group.admin.id         # Admin Portal NSG
    messaging = azurerm_network_security_group.messaging.id     # Messaging NSG
    data      = azurerm_network_security_group.data.id          # Data NSG
    bastion   = azurerm_network_security_group.bastion.id       # Bastion NSG
  }
}
