# =============================================================================
# All Phase Outputs
# =============================================================================

# --- Phase 1: Foundation ---
output "resource_group_name" {
  value = data.azurerm_resource_group.main.name          # 2dt-final-team4
}

output "vnet_id" {
  value = module.network.vnet_id                         # VNet ID
}

output "subnet_ids" {
  value = module.network.subnet_ids                      # 서브넷 ID 맵
}

output "log_analytics_workspace_id" {
  value = module.monitoring.log_analytics_workspace_id   # LAW ID
}

# --- Phase 2: Core Services ---
output "key_vault_uri" {
  value = module.security.key_vault_uri                  # KV URI
}

output "acr_login_server" {
  value = module.security.acr_login_server               # ACR 로그인 서버
}

output "sql_server_fqdn" {
  value = module.data.sql_server_fqdn                    # SQL FQDN
}

output "postgresql_server_fqdn" {
  value = module.data.postgresql_server_fqdn             # PG FQDN
}

# --- Phase 3: Compute + Messaging + Perimeter ---
output "aks_fqdn" {
  value = module.compute.aks_fqdn                        # AKS API FQDN
}

output "eventhubs_namespace" {
  value = module.messaging.namespace_name                # EH Namespace 이름
}

output "firewall_private_ip" {
  value = module.perimeter.firewall_private_ip           # Firewall Private IP
}

output "firewall_public_ip" {
  value = module.perimeter.firewall_public_ip            # Firewall SNAT IP
}

# --- Phase 4: Analytics ---
output "databricks_workspace_url" {
  value = module.analytics.databricks_workspace_url      # Databricks URL
}

output "adls_storage_name" {
  value = module.analytics.adls_storage_name             # ADLS 계정 이름
}
