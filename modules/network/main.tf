# =============================================================================
# Network Module - VNet, Subnets, NSGs, DNS
# =============================================================================

# 3. Virtual Network (Single VNet)
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-core-platform"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = var.resource_group_name
}

# 4. Subnets for each zone
resource "azurerm_subnet" "subnets" {
  for_each = {
    "perimeter" = "10.0.1.0/24"
    "app-aks"   = "10.0.2.0/24"
    "messaging" = "10.0.3.0/24"
    "data"      = "10.0.4.0/24"
    "security"  = "10.0.5.0/24"
    "analytics" = "10.0.6.0/24"
    "egress"    = "10.0.7.0/24"
    "ops"       = "10.0.8.0/24"
  }

  name                 = "snet-${each.key}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [each.value]
}

# =============================================================================
# 4.1 Network Security Groups for each subnet
# =============================================================================
resource "azurerm_network_security_group" "nsg" {
  for_each = {
    "perimeter" = "10.0.1.0/24"
    "app-aks"   = "10.0.2.0/24"
    "messaging" = "10.0.3.0/24"
    "data"      = "10.0.4.0/24"
    "security"  = "10.0.5.0/24"
    "analytics" = "10.0.6.0/24"
    "egress"    = "10.0.7.0/24"
    "ops"       = "10.0.8.0/24"
  }

  name                = "nsg-${each.key}"
  location            = var.location
  resource_group_name = var.resource_group_name
}

# 4.2 Associate NSG to each subnet
resource "azurerm_subnet_network_security_group_association" "nsg_assoc" {
  for_each = azurerm_subnet.subnets

  subnet_id                 = each.value.id
  network_security_group_id = azurerm_network_security_group.nsg[each.key].id
}

# =============================================================================
# 9. Azure Bastion Subnet
# Note: Bastion requires subnet named "AzureBastionSubnet"
# =============================================================================
resource "azurerm_subnet" "bastion_snet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.9.0/24"]
}

# =============================================================================
# 18. Azure Firewall Subnet
# =============================================================================
resource "azurerm_subnet" "firewall_snet" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.10.0/24"]
}

# =============================================================================
# 19. Application Gateway Subnet
# =============================================================================
resource "azurerm_subnet" "appgw_snet" {
  name                 = "snet-appgw"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.11.0/24"]
}

# =============================================================================
# 16. Azure Private DNS Zone (Security Subnet)
# =============================================================================
resource "azurerm_private_dns_zone" "dns" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns_link" {
  name                  = "dns-vnet-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.dns.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}
