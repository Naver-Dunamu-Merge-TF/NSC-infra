# =============================================================================
# Compute Module — Outputs
# =============================================================================

output "aks_id" {
  value = azurerm_kubernetes_cluster.main.id             # AKS Cluster ID
}

output "aks_fqdn" {
  value = azurerm_kubernetes_cluster.main.fqdn           # AKS API Server FQDN
}

output "aks_identity_principal_id" {
  value = azurerm_kubernetes_cluster.main.identity[0].principal_id
}

output "kubelet_identity_object_id" {
  value = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
}
