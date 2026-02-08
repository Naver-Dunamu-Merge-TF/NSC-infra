# =============================================================================
# Enterprise Platform - Terraform Configuration (Modularized)
# =============================================================================

# 1. Provider Configuration
terraform {
  required_version = ">= 1.0.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Random suffix for globally unique names
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# 2. Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-enterprise-platform"
  location = "Korea Central"
}

data "azurerm_client_config" "current" {}

# =============================================================================
# Module Calls
# =============================================================================

# 10-11. Monitoring (Log Analytics, App Insights)
module "monitoring" {
  source              = "./modules/monitoring"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  suffix              = random_string.suffix.result
}

# 3-4. Network (VNet, Subnets, NSGs, DNS)
module "network" {
  source              = "./modules/network"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
}

# 5. Compute (AKS)
module "compute" {
  source                     = "./modules/compute"
  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  aks_subnet_id              = module.network.aks_subnet_id
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
}

# 6. Messaging (Event Hubs)
module "messaging" {
  source              = "./modules/messaging"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  suffix              = random_string.suffix.result
}

# 7, 12. Security (Key Vault, ACR)
module "security" {
  source              = "./modules/security"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  suffix              = random_string.suffix.result
  tenant_id           = data.azurerm_client_config.current.tenant_id
}

# 8, 13-16. Data (SQL, PostgreSQL, Data Lake Storage, Databricks, Confidential Ledger)
module "data" {
  source              = "./modules/data"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  suffix              = random_string.suffix.result
  tenant_id           = data.azurerm_client_config.current.tenant_id
  current_object_id   = data.azurerm_client_config.current.object_id
}

# 17-19. Perimeter (Bastion, Firewall, App Gateway + WAF)
module "perimeter" {
  source              = "./modules/perimeter"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  bastion_subnet_id   = module.network.bastion_subnet_id
  firewall_subnet_id  = module.network.firewall_subnet_id
  appgw_subnet_id     = module.network.appgw_subnet_id
}

# 20. Diagnostics (Firewall & App Gateway diagnostic settings)
module "diagnostics" {
  source                     = "./modules/diagnostics"
  firewall_id                = module.perimeter.firewall_id
  appgw_id                   = module.perimeter.appgw_id
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
}

# =============================================================================
# Role Assignments (AKS -> ACR, AKS -> Key Vault)
# =============================================================================

# AKS kubelet identity -> ACR: AcrPull (Image Pull)
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = module.compute.aks_principal_id
  role_definition_name             = "AcrPull"
  scope                            = module.security.acr_id
  skip_service_principal_aad_check = true
}

# AKS kubelet identity -> Key Vault: Key Vault Secrets User (Secret Retrieval)
resource "azurerm_role_assignment" "aks_kv_secrets" {
  principal_id                     = module.compute.aks_principal_id
  role_definition_name             = "Key Vault Secrets User"
  scope                            = module.security.key_vault_id
  skip_service_principal_aad_check = true
}
