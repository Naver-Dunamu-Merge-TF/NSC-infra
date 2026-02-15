# =============================================================================
# Compute Module — AKS (§7.1)
# Source of Truth: README.md §7.1, §7.3
# =============================================================================

# AKS Cluster (§7.1: Standard, D4s_v3 × 3, AutoScale 3-10)
resource "azurerm_kubernetes_cluster" "main" {
  name                = "${var.project_prefix}-aks-${var.environment}"  # nsc-aks-dev
  resource_group_name = var.resource_group_name           # RG 참조
  location            = var.location                      # Korea Central
  dns_prefix          = "${var.project_prefix}-aks-${var.environment}"  # DNS 접두어
  kubernetes_version  = "1.28"                            # §7.1 기준 안정 버전

  default_node_pool {
    name                = "system"                        # 시스템 노드 풀
    vm_size             = "Standard_D4s_v3"               # §7.1: D4s_v3
    node_count          = 3                               # §7.1: 초기 3대
    min_count           = 3                               # AutoScale 최소
    max_count           = 10                              # §7.1: AutoScale 최대 10
    enable_auto_scaling = true                            # §7.1: AutoScaler 활성화
    vnet_subnet_id      = var.aks_subnet_id               # Application 서브넷
    zones               = ["1", "2", "3"]                 # Zone Redundant
  }

  identity {
    type = "SystemAssigned"                               # §5.1: Managed Identity
  }

  oidc_issuer_enabled       = true                        # Workload Identity 전제 조건
  workload_identity_enabled = true                        # §5.1: Workload Identity

  azure_active_directory_role_based_access_control {
    managed            = true                             # AAD 관리형
    azure_rbac_enabled = true                             # §5.1: Azure RBAC
  }

  network_profile {
    network_plugin = "azure"                              # Azure CNI (VNet 통합)
    network_policy = "calico"                             # Calico 네트워크 정책
    service_cidr   = "172.16.0.0/16"                      # Service CIDR (VNet 외부)
    dns_service_ip = "172.16.0.10"                        # DNS Service IP
  }

  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id  # LAW 연동
  }

  tags = var.tags
}
