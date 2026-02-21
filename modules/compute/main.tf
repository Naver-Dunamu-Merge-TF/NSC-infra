# =============================================================================
# Compute Module — AKS (§7.1)
# Source of Truth: README.md §7.1, §7.3
# =============================================================================

# AKS Cluster (§7.1: Standard, D4s_v3 × 3, AutoScale 3-10)
resource "azurerm_kubernetes_cluster" "main" {
  name                = "${var.project_prefix}-aks-${var.environment}"  # nsc-aks-dev
  resource_group_name = var.resource_group_name
  location            = var.location                      # Korea Central
  dns_prefix          = "${var.project_prefix}-aks-${var.environment}"
  kubernetes_version        = "1.32"                    # 1.28~1.31은 LTS 전용 → 1.32+ Standard tier 지원
  private_cluster_enabled   = true                        # CKV_AZURE_115: private cluster
  automatic_channel_upgrade = "stable"                    # CKV_AZURE_171: auto upgrade channel
  sku_tier                  = "Standard"                  # CKV_AZURE_170: Paid SLA
  image_cleaner_enabled        = true
  image_cleaner_interval_hours = 48

  # api_server_access_profile — 별도 API 서버 서브넷 + User Assigned MI 필요, private_cluster_enabled로 대체

  default_node_pool {
    name                = "system"
    vm_size             = "Standard_D4s_v3"
    type                = "VirtualMachineScaleSets"        # CKV_AZURE_169: scale sets
    node_count          = 3
    min_count           = 3
    max_count           = 10
    enable_auto_scaling = true
    vnet_subnet_id      = var.aks_subnet_id
    zones               = ["1", "2", "3"]
  }

  identity {
    type = "SystemAssigned"                               # §5.1: Managed Identity
  }

  oidc_issuer_enabled       = true
  workload_identity_enabled = true                        # CKV_AZURE_172: Workload Identity
  local_account_disabled    = false                       # 안정화 후 true 전환 (Deploy_TEST_LOG #9)
  azure_policy_enabled      = true                        # CKV_AZURE_116: Azure Policy addon

  azure_active_directory_role_based_access_control {
    managed            = true
    azure_rbac_enabled = true
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "calico"
    service_cidr   = "172.16.0.0/16"
    dns_service_ip = "172.16.0.10"
  }

  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  key_vault_secrets_provider {                             # CKV_AZURE_171: KV Secrets Provider
    secret_rotation_enabled = true
  }

  tags = var.tags
}
