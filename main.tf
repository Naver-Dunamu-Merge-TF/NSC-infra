# =============================================================================
# NSC Platform — Root Configuration (All Phases)
# Source of Truth: README.md (Architecture Manual v02)
# =============================================================================

terraform {
  required_version = ">= 1.5.0"                        # Terraform 최소 버전

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"                     # Azure RM 프로바이더
      version = "~> 3.80"                               # 3.80 이상 4.0 미만
    }
    random = {
      source  = "hashicorp/random"                      # 랜덤 문자열 생성용
      version = "~> 3.0"                                # Storage/ACR suffix
    }
  }
}

provider "azurerm" {
  features {}                                           # 필수 블록
}

# 글로벌 유니크 이름용 suffix (§7.4: Storage Account, ACR만 사용)
resource "random_string" "suffix" {
  length  = 6                                           # 6자리
  special = false                                       # 특수문자 제외
  upper   = false                                       # 소문자만
}

# Resource Group (§7.4: nsc-rg-{env})
resource "azurerm_resource_group" "main" {
  name     = "${var.project_prefix}-rg-${var.environment}"  # nsc-rg-dev
  location = var.location                               # Korea Central
  tags     = var.tags                                   # 공통 태그
}

data "azurerm_client_config" "current" {}               # tenant_id, object_id 참조

# =============================================================================
# Phase 1: Foundation
# =============================================================================

# Network — VNet + 10 Subnets + NSG + UDR (§2.5, §4.1, §4.2, §7.2)
module "network" {
  source = "./modules/network"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  project_prefix      = var.project_prefix              # nsc
  environment         = var.environment                 # dev
  vnet_cidr           = var.vnet_cidr                   # 10.0.0.0/16
  subnet_cidrs        = var.subnet_cidrs                # 서브넷 CIDR 맵
  firewall_private_ip = module.perimeter.firewall_private_ip  # Phase 3 Firewall → UDR
  tags                = var.tags
}

# Monitoring — Log Analytics + App Insights (§7.1)
module "monitoring" {
  source = "./modules/monitoring"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  project_prefix      = var.project_prefix
  environment         = var.environment
  tags                = var.tags
}

# =============================================================================
# Phase 2: Core Services
# =============================================================================

# Security — Key Vault + ACR + Private DNS Zones (§5.2, §4.3)
module "security" {
  source = "./modules/security"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  project_prefix      = var.project_prefix
  environment         = var.environment
  suffix              = random_string.suffix.result      # ACR suffix
  tenant_id           = data.azurerm_client_config.current.tenant_id
  vnet_id             = module.network.vnet_id           # DNS Zone VNet Link
  tags                = var.tags
}

# Data — SQL DB + PostgreSQL + Confidential Ledger (§7.1)
module "data" {
  source = "./modules/data"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  project_prefix      = var.project_prefix
  environment         = var.environment
  tenant_id           = data.azurerm_client_config.current.tenant_id
  current_object_id   = data.azurerm_client_config.current.object_id
  pg_admin_password   = var.pg_admin_password            # tfvars 또는 환경변수
  tags                = var.tags
}

# Private Endpoints — 7개 PE (§4.3)
module "private_endpoints" {
  source = "./modules/private_endpoints"

  resource_group_name    = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location
  project_prefix         = var.project_prefix
  subnet_ids             = module.network.subnet_ids     # 서브넷 ID 맵
  dns_zone_ids           = module.security.dns_zone_ids  # DNS Zone ID 맵
  sql_server_id          = module.data.sql_server_id
  postgresql_server_id   = module.data.postgresql_server_id
  ledger_id              = module.data.ledger_id
  key_vault_id           = module.security.key_vault_id
  acr_id                 = module.security.acr_id
  eventhubs_namespace_id = module.messaging.namespace_id # Phase 3
  adls_storage_id        = module.analytics.adls_storage_id  # Phase 4
  tags                   = var.tags
}

# =============================================================================
# Phase 3: Compute + Messaging + Perimeter
# =============================================================================

# Compute — AKS (§7.1)
module "compute" {
  source = "./modules/compute"

  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  project_prefix             = var.project_prefix
  environment                = var.environment
  aks_subnet_id              = module.network.subnet_ids["app"]  # Application 서브넷
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  tags                       = var.tags
}

# Messaging — Event Hubs (§7.1)
module "messaging" {
  source = "./modules/messaging"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  project_prefix      = var.project_prefix
  environment         = var.environment
  tags                = var.tags
}

# Perimeter — AppGW + WAF + Bastion + Firewall (§5.3, §7.1)
module "perimeter" {
  source = "./modules/perimeter"

  resource_group_name   = azurerm_resource_group.main.name
  location              = azurerm_resource_group.main.location
  project_prefix        = var.project_prefix
  environment           = var.environment
  perimeter_subnet_id   = module.network.subnet_ids["perimeter"]  # Perimeter 서브넷
  bastion_subnet_id     = module.network.subnet_ids["bastion"]    # Bastion 서브넷
  egress_subnet_id      = module.network.subnet_ids["egress"]     # Firewall 서브넷
  app_subnet_cidr       = var.subnet_cidrs["app"]                 # FW Rule 소스
  analytics_subnet_cidr = var.subnet_cidrs["analytics_host"]      # FW Rule 소스
  vnet_cidr             = var.vnet_cidr                           # Network Rule 소스
  tags                  = var.tags
}

# =============================================================================
# Phase 4: Analytics + Diagnostics
# =============================================================================

# Analytics — Databricks + ADLS Gen2 (§7.1)
module "analytics" {
  source = "./modules/analytics"

  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  project_prefix                  = var.project_prefix
  environment                     = var.environment
  suffix                          = random_string.suffix.result
  vnet_id                         = module.network.vnet_id
  analytics_host_subnet_id        = module.network.subnet_ids["analytics_host"]
  analytics_host_subnet_name      = "${var.project_prefix}-snet-analytics-host"
  analytics_container_subnet_id   = module.network.subnet_ids["analytics_container"]
  analytics_container_subnet_name = "${var.project_prefix}-snet-analytics-container"
  tags                            = var.tags
}

# Diagnostics — 리소스 → LAW 로그 전송 (§6)
module "diagnostics" {
  source = "./modules/diagnostics"

  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  aks_id                     = module.compute.aks_id
  appgw_id                   = module.perimeter.appgw_id
  firewall_id                = module.perimeter.firewall_id
  key_vault_id               = module.security.key_vault_id
  sql_database_id            = module.data.sql_database_id
}

# =============================================================================
# RBAC Role Assignments (§5.1)
# =============================================================================

# AKS Kubelet → ACR Pull 권한
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = module.security.acr_id                        # ACR 스코프
  role_definition_name = "AcrPull"                       # 이미지 Pull 권한
  principal_id         = module.compute.kubelet_identity_object_id     # Kubelet MI
}

# AKS → Key Vault Secrets Reader
resource "azurerm_role_assignment" "aks_kv_reader" {
  scope                = module.security.key_vault_id                  # KV 스코프
  role_definition_name = "Key Vault Secrets User"        # 시크릿 읽기
  principal_id         = module.compute.aks_identity_principal_id      # AKS MI
}
