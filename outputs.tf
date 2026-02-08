# =============================================================================
# Outputs
# =============================================================================
output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "aks_cluster_name" {
  value = module.compute.aks_cluster_name
}

output "vnet_name" {
  value = module.network.vnet_name
}
