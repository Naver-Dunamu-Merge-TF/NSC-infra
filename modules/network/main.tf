# =============================================================================
# Network Module — VNet + 10 Subnets + NSG + UDR
# Source of Truth: README.md §2.5, §4.1, §4.2, §7.2
# Naming Convention: README.md §7.4
# =============================================================================

# =============================================================================
# VNet (Single VNet — §2.5)
# =============================================================================

resource "azurerm_virtual_network" "main" {
  name                = "${var.project_prefix}-vnet-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location                     # Korea Central
  address_space       = [var.vnet_cidr]                  # 10.0.0.0/16
  tags                = var.tags
}

# =============================================================================
# =============================================================================

# 1. Perimeter — Application Gateway + WAF
resource "azurerm_subnet" "perimeter" {
  name                 = "${var.project_prefix}-snet-perimeter"         # nsc-snet-perimeter
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet_cidrs["perimeter"]] # 10.0.0.0/24
}

resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet_cidrs["bastion"]]
}

# 3. Application — AKS Node Pool
resource "azurerm_subnet" "app" {
  name                 = "${var.project_prefix}-snet-app"               # nsc-snet-app
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet_cidrs["app"]]
}

# 4. Messaging — Event Hubs Private Endpoint
resource "azurerm_subnet" "messaging" {
  name                 = "${var.project_prefix}-snet-messaging"         # nsc-snet-messaging
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet_cidrs["messaging"]] # 10.0.3.0/24
}

# 5. Data — SQL DB, PostgreSQL, Confidential Ledger Private Endpoints
resource "azurerm_subnet" "data" {
  name                 = "${var.project_prefix}-snet-data"              # nsc-snet-data
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet_cidrs["data"]]      # 10.0.4.0/24
}

# 6. Security — Key Vault, ACR Private Endpoints
resource "azurerm_subnet" "security" {
  name                 = "${var.project_prefix}-snet-security"          # nsc-snet-security
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet_cidrs["security"]]  # 10.0.5.0/24
}

# 7a. Analytics Host — Databricks Public Subnet
resource "azurerm_subnet" "analytics_host" {
  name                 = "${var.project_prefix}-snet-analytics-host"    # nsc-snet-analytics-host
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet_cidrs["analytics_host"]]  # 10.0.6.0/24

  delegation {
    name = "databricks-host"
    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
      ]
    }
  }
}

# 7b. Analytics Container — Databricks Private Subnet
resource "azurerm_subnet" "analytics_container" {
  name                 = "${var.project_prefix}-snet-analytics-container"  # nsc-snet-analytics-container
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet_cidrs["analytics_container"]]  # 10.0.7.0/24

  delegation {
    name = "databricks-container"
    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
      ]
    }
  }
}

resource "azurerm_subnet" "egress" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet_cidrs["egress"]]
}

# 9. Admin Portal — Admin UI
resource "azurerm_subnet" "admin" {
  name                 = "${var.project_prefix}-snet-admin"             # nsc-snet-admin
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet_cidrs["admin"]]     # 10.0.10.0/28 (16 IPs)
}

# =============================================================================
# =============================================================================

resource "azurerm_network_security_group" "perimeter" {
  name                = "${var.project_prefix}-nsg-perimeter"           # nsc-nsg-perimeter
  resource_group_name = var.resource_group_name
  location            = var.location                     # Korea Central
  tags                = var.tags
}

# §4.1: Internet → Perimeter, HTTPS 443
resource "azurerm_network_security_rule" "perimeter_allow_https" {
  name                        = "allow-https-inbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"                    # TCP
  source_port_range           = "*"
  destination_port_range      = "443"                    # HTTPS
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.perimeter.name
}

resource "azurerm_network_security_rule" "perimeter_allow_gw_manager" {
  name                        = "allow-gateway-manager"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"                    # TCP
  source_port_range           = "*"
  destination_port_range      = "65200-65535"
  source_address_prefix       = "GatewayManager"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.perimeter.name
}

resource "azurerm_network_security_group" "app" {
  name                = "${var.project_prefix}-nsg-app"                 # nsc-nsg-app
  resource_group_name = var.resource_group_name
  location            = var.location                     # Korea Central
  tags                = var.tags
}

resource "azurerm_network_security_rule" "app_allow_ssh_bastion" {
  name                        = "allow-ssh-bastion"      # Bastion → AKS Node SSH
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"                    # TCP
  source_port_range           = "*"
  destination_port_range      = "22"                     # SSH
  source_address_prefix       = var.subnet_cidrs["bastion"]
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.app.name
}

resource "azurerm_network_security_rule" "app_deny_ssh_internet" {
  name                        = "deny-ssh-internet"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "Tcp"                    # TCP
  source_port_range           = "*"
  destination_port_range      = "22"                     # SSH
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.app.name
}

# §4.1: Perimeter → Application, 8443 (AppGW → AKS, End-to-End TLS)
resource "azurerm_network_security_rule" "app_allow_from_gw" {
  name                        = "allow-from-gw-8443"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"                    # TCP
  source_port_range           = "*"
  destination_port_range      = "8443"
  source_address_prefix       = var.subnet_cidrs["perimeter"]
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.app.name
}

# §4.1: Admin Portal → Application, 8443
resource "azurerm_network_security_rule" "app_allow_from_admin" {
  name                        = "allow-from-admin-8443"  # Admin UI → Admin API
  priority                    = 210
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"                    # TCP
  source_port_range           = "*"
  destination_port_range      = "8443"
  source_address_prefix       = var.subnet_cidrs["admin"]
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.app.name
}

resource "azurerm_network_security_rule" "app_allow_kafka_response" {
  name                        = "allow-kafka-response-9093"
  priority                    = 300
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"                    # TCP
  source_port_range           = "*"
  destination_port_range      = "9093"
  source_address_prefix       = var.subnet_cidrs["messaging"]
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.app.name
}

# --- Admin Portal NSG ---
resource "azurerm_network_security_group" "admin" {
  name                = "${var.project_prefix}-nsg-admin"               # nsc-nsg-admin
  resource_group_name = var.resource_group_name
  location            = var.location                     # Korea Central
  tags                = var.tags
}

# §4.1: Perimeter → Admin Portal, 443
resource "azurerm_network_security_rule" "admin_allow_from_appgw" {
  name                        = "allow-from-appgw-443"   # AppGW → Admin UI
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"                    # TCP
  source_port_range           = "*"
  destination_port_range      = "443"                    # HTTPS
  source_address_prefix       = var.subnet_cidrs["perimeter"]
  destination_address_prefix  = "*"                      # Admin UI
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.admin.name
}

# --- Messaging NSG ---
resource "azurerm_network_security_group" "messaging" {
  name                = "${var.project_prefix}-nsg-messaging"           # nsc-nsg-messaging
  resource_group_name = var.resource_group_name
  location            = var.location                     # Korea Central
  tags                = var.tags
}

# §4.1: Application → Messaging, 9093 (Kafka TLS)
resource "azurerm_network_security_rule" "messaging_allow_kafka" {
  name                        = "allow-kafka-9093"       # AKS → Event Hubs Kafka
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"                    # TCP
  source_port_range           = "*"
  destination_port_range      = "9093"
  source_address_prefix       = var.subnet_cidrs["app"]
  destination_address_prefix  = "*"                      # Event Hubs PE
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.messaging.name
}

# --- Data NSG ---
resource "azurerm_network_security_group" "data" {
  name                = "${var.project_prefix}-nsg-data"                # nsc-nsg-data
  resource_group_name = var.resource_group_name
  location            = var.location                     # Korea Central
  tags                = var.tags
}

resource "azurerm_network_security_rule" "data_deny_all_inbound" {
  name                        = "deny-all-inbound"
  priority                    = 4096
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.data.name
}

resource "azurerm_network_security_group" "bastion" {
  name                = "${var.project_prefix}-nsg-bastion"             # nsc-nsg-bastion
  resource_group_name = var.resource_group_name
  location            = var.location                     # Korea Central
  tags                = var.tags
}

resource "azurerm_network_security_rule" "bastion_inbound_https" {
  name                        = "allow-https-inbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"                    # TCP
  source_port_range           = "*"
  destination_port_range      = "443"                    # HTTPS
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"                      # Bastion
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.bastion.name
}

resource "azurerm_network_security_rule" "bastion_inbound_gw_mgr" {
  name                        = "allow-gateway-manager"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"                    # TCP
  source_port_range           = "*"
  destination_port_range      = "443"                    # HTTPS
  source_address_prefix       = "GatewayManager"
  destination_address_prefix  = "*"                      # Bastion
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.bastion.name
}

resource "azurerm_network_security_rule" "bastion_inbound_lb" {
  name                        = "allow-azure-lb"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"                    # TCP
  source_port_range           = "*"
  destination_port_range      = "443"                    # HTTPS
  source_address_prefix       = "AzureLoadBalancer"
  destination_address_prefix  = "*"                      # Bastion
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.bastion.name
}

resource "azurerm_network_security_rule" "bastion_inbound_data_plane" {
  name                        = "allow-bastion-data-plane"
  priority                    = 130
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_ranges     = ["8080", "5701"]
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.bastion.name
}

# Bastion Outbound: SSH/RDP to VNet targets
resource "azurerm_network_security_rule" "bastion_outbound_ssh_rdp" {
  name                        = "allow-ssh-rdp-outbound" # Bastion → VM SSH/RDP
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"                    # TCP
  source_port_range           = "*"
  destination_port_ranges     = ["22", "3389"]           # SSH + RDP
  source_address_prefix       = "*"                      # Bastion
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.bastion.name
}

resource "azurerm_network_security_rule" "bastion_outbound_azure" {
  name                        = "allow-azure-cloud"
  priority                    = 110
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"                    # TCP
  source_port_range           = "*"
  destination_port_range      = "443"                    # HTTPS
  source_address_prefix       = "*"                      # Bastion
  destination_address_prefix  = "AzureCloud"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.bastion.name
}

resource "azurerm_network_security_rule" "bastion_outbound_data_plane" {
  name                        = "allow-bastion-data-plane-out"
  priority                    = 120
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_ranges     = ["8080", "5701"]
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.bastion.name
}

# =============================================================================
# =============================================================================

resource "azurerm_subnet_network_security_group_association" "perimeter" {
  subnet_id                 = azurerm_subnet.perimeter.id
  network_security_group_id = azurerm_network_security_group.perimeter.id  # Perimeter NSG
}

resource "azurerm_subnet_network_security_group_association" "bastion" {
  subnet_id                 = azurerm_subnet.bastion.id
  network_security_group_id = azurerm_network_security_group.bastion.id    # Bastion NSG
}

resource "azurerm_subnet_network_security_group_association" "app" {
  subnet_id                 = azurerm_subnet.app.id
  network_security_group_id = azurerm_network_security_group.app.id        # Application NSG
}

resource "azurerm_subnet_network_security_group_association" "admin" {
  subnet_id                 = azurerm_subnet.admin.id
  network_security_group_id = azurerm_network_security_group.admin.id      # Admin NSG
}

resource "azurerm_subnet_network_security_group_association" "messaging" {
  subnet_id                 = azurerm_subnet.messaging.id
  network_security_group_id = azurerm_network_security_group.messaging.id  # Messaging NSG
}

resource "azurerm_subnet_network_security_group_association" "data" {
  subnet_id                 = azurerm_subnet.data.id
  network_security_group_id = azurerm_network_security_group.data.id       # Data NSG
}

# --- Security NSG (CKV2_AZURE_31 fix) ---
resource "azurerm_network_security_group" "security" {
  name                = "${var.project_prefix}-nsg-security"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_network_security_rule" "security_deny_all_inbound" {
  name                        = "deny-all-inbound"
  priority                    = 4096
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.security.name
}

resource "azurerm_subnet_network_security_group_association" "security" {
  subnet_id                 = azurerm_subnet.security.id
  network_security_group_id = azurerm_network_security_group.security.id
}

