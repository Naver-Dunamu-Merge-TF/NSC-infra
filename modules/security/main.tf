# =============================================================================
# Security Module - Key Vault, Container Registry
# =============================================================================

# 7. Azure Key Vault (Security Subnet)
resource "azurerm_key_vault" "kv" {
  name                        = "kv-platform-${var.suffix}"
  location                    = var.location
  resource_group_name         = var.resource_group_name
  tenant_id                   = var.tenant_id
  sku_name                    = "standard"
  
  # Security settings (Checkov fixes)
  purge_protection_enabled    = true
  soft_delete_retention_days  = 90
  enable_rbac_authorization   = true
  
  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }
}

# 12. Azure Container Registry (Security Subnet)
resource "azurerm_container_registry" "acr" {
  name                = "acrplatform${var.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"
  admin_enabled       = false
}
