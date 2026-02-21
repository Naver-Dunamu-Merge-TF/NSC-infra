# =============================================================================
# Routing Module — UDR (User Defined Routes)
# Source of Truth: README.md §4.2
# Extracted from Network Module to break circular dependency (network ↔ perimeter)
# =============================================================================

# --- Application Subnet → Firewall ---
resource "azurerm_route_table" "app" {
  name                = "${var.project_prefix}-udr-app"                 # nsc-udr-app
  resource_group_name = var.resource_group_name
  location            = var.location                     # Korea Central
  tags                = var.tags
}

resource "azurerm_route" "app_to_firewall" {
  name                   = "route-to-firewall"
  resource_group_name    = var.resource_group_name
  route_table_name       = azurerm_route_table.app.name  # Application UDR
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"            # Firewall = Virtual Appliance
  next_hop_in_ip_address = var.firewall_private_ip       # Firewall Private IP
}

resource "azurerm_subnet_route_table_association" "app" {
  subnet_id      = var.subnet_ids["app"]
  route_table_id = azurerm_route_table.app.id            # Application UDR
}

# --- Data Subnet → Firewall ---
resource "azurerm_route_table" "data" {
  name                = "${var.project_prefix}-udr-data"                # nsc-udr-data
  resource_group_name = var.resource_group_name
  location            = var.location                     # Korea Central
  tags                = var.tags
}

resource "azurerm_route" "data_to_firewall" {
  name                   = "route-to-firewall"
  resource_group_name    = var.resource_group_name
  route_table_name       = azurerm_route_table.data.name # Data UDR
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"            # Firewall = Virtual Appliance
  next_hop_in_ip_address = var.firewall_private_ip       # Firewall Private IP
}

resource "azurerm_subnet_route_table_association" "data" {
  subnet_id      = var.subnet_ids["data"]
  route_table_id = azurerm_route_table.data.id           # Data UDR
}

# --- Analytics Subnets → Firewall ---
resource "azurerm_route_table" "analytics" {
  name                = "${var.project_prefix}-udr-analytics"           # nsc-udr-analytics
  resource_group_name = var.resource_group_name
  location            = var.location                     # Korea Central
  tags                = var.tags
}

resource "azurerm_route" "analytics_to_firewall" {
  name                   = "route-to-firewall"
  resource_group_name    = var.resource_group_name
  route_table_name       = azurerm_route_table.analytics.name  # Analytics UDR
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"            # Firewall = Virtual Appliance
  next_hop_in_ip_address = var.firewall_private_ip       # Firewall Private IP
}

resource "azurerm_subnet_route_table_association" "analytics_host" {
  subnet_id      = var.subnet_ids["analytics_host"]
  route_table_id = azurerm_route_table.analytics.id
}

resource "azurerm_subnet_route_table_association" "analytics_container" {
  subnet_id      = var.subnet_ids["analytics_container"]
  route_table_id = azurerm_route_table.analytics.id
}
