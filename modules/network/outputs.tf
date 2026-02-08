output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}

output "vnet_name" {
  value = azurerm_virtual_network.vnet.name
}

output "aks_subnet_id" {
  value = azurerm_subnet.subnets["app-aks"].id
}

output "bastion_subnet_id" {
  value = azurerm_subnet.bastion_snet.id
}

output "firewall_subnet_id" {
  value = azurerm_subnet.firewall_snet.id
}

output "appgw_subnet_id" {
  value = azurerm_subnet.appgw_snet.id
}
