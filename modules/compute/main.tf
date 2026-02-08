# =============================================================================
# Compute Module - AKS Cluster (App Subnet)
# =============================================================================
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-microservices"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "aks-platform"

  default_node_pool {
    name           = "default"
    node_count     = 2
    vm_size        = "Standard_D2s_v3"
    vnet_subnet_id = var.aks_subnet_id
  }

  identity {
    type = "SystemAssigned"
  }

  # Security settings (Checkov fixes)
  network_profile {
    network_plugin    = "azure"
    network_policy    = "calico"
    load_balancer_sku = "standard"
  }

  azure_policy_enabled = true
  
  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }
}
