# =============================================================================
# Perimeter Module — AppGW + WAF + Bastion + Firewall
# Source of Truth: README.md §5.3, §7.1, §7.2
# =============================================================================

# =============================================================================
# =============================================================================

resource "azurerm_public_ip" "agw" {
  name                = "${var.project_prefix}-pip-agw"        # nsc-pip-agw
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]                  # Zone Redundant
  tags                = var.tags
}

resource "azurerm_public_ip" "bastion" {
  name                = "${var.project_prefix}-pip-bas"        # nsc-pip-bas
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_public_ip" "firewall" {
  name                = "${var.project_prefix}-pip-fw"         # nsc-pip-fw
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"                         # Firewall SNAT
  sku                 = "Standard"
  zones               = ["1", "2", "3"]                  # Zone Redundant
  tags                = var.tags
}

# =============================================================================
# WAF Policy (§5.3.1: OWASP CRS 3.2, Prevention Mode)
# =============================================================================

resource "azurerm_web_application_firewall_policy" "main" {
  name                = "${var.project_prefix}-waf-${var.environment}"  # nsc-waf-dev
  resource_group_name = var.resource_group_name
  location            = var.location

  policy_settings {
    enabled                     = true
    mode                        = "Prevention"
    max_request_body_size_in_kb = 128
    file_upload_limit_in_mb     = 100
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"                                  # OWASP Core Rule Set
      version = "3.2"                                    # §5.3.1: CRS 3.2
    }
  }

  tags = var.tags
}

# =============================================================================
# Application Gateway (§7.1: WAF_v2, AutoScale 2-10, Zone Redundant)
# =============================================================================

resource "azurerm_application_gateway" "main" {
  name                = "${var.project_prefix}-agw-${var.environment}"  # nsc-agw-dev
  resource_group_name = var.resource_group_name
  location            = var.location
  firewall_policy_id  = azurerm_web_application_firewall_policy.main.id
  zones               = ["1", "2", "3"]                  # Zone Redundant
  enable_http2        = true

  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20220101"               # TLS 1.2 minimum
  }

  sku {
    name = "WAF_v2"                                      # §7.1: WAF_v2 SKU
    tier = "WAF_v2"                                      # WAF_v2 Tier
  }

  autoscale_configuration {
    min_capacity = 2
    max_capacity = 10
  }

  gateway_ip_configuration {
    name      = "gateway-ip"
    subnet_id = var.perimeter_subnet_id
  }

  frontend_ip_configuration {
    name                 = "frontend-public-ip"
    public_ip_address_id = azurerm_public_ip.agw.id
  }

  frontend_port {
    name = "http-port"
    port = 80
  }

  backend_address_pool {
    name = "aks-backend-pool"
  }

  backend_http_settings {
    name                  = "aks-http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 8443
    protocol              = "Https"                      # End-to-End TLS
    request_timeout       = 30
  }

  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "frontend-public-ip"
    frontend_port_name             = "http-port"
    protocol                       = "Http"              # TODO: Https + SSL Cert
  }

  request_routing_rule {
    name                       = "default-routing-rule"
    priority                   = 100
    rule_type                  = "Basic"
    http_listener_name         = "http-listener"
    backend_address_pool_name  = "aks-backend-pool"
    backend_http_settings_name = "aks-http-settings"
  }

  tags = var.tags
}

# =============================================================================
# Bastion (§7.1: Standard, 2 Instances)
# =============================================================================

resource "azurerm_bastion_host" "main" {
  name                = "${var.project_prefix}-bas-${var.environment}"  # nsc-bas-dev
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"                       # §7.1: Standard SKU
  scale_units         = 2                                # §7.1: 2 Instances

  ip_configuration {
    name                 = "bastion-ip-config"
    subnet_id            = var.bastion_subnet_id         # AzureBastionSubnet
    public_ip_address_id = azurerm_public_ip.bastion.id  # Public IP
  }

  tags = var.tags
}

# =============================================================================
# Firewall (§7.1: Standard, Zone Redundant, Threat Intel Alert)
# =============================================================================

resource "azurerm_firewall_policy" "main" {
  name                     = "${var.project_prefix}-fwp-${var.environment}"  # nsc-fwp-dev
  resource_group_name      = var.resource_group_name
  location                 = var.location
  sku                      = "Standard"                  # §7.1: Standard
  threat_intelligence_mode = "Alert"                     # §7.1: Threat Intel Alert
  tags                     = var.tags
}

resource "azurerm_firewall" "main" {
  name                = "${var.project_prefix}-fw-${var.environment}"   # nsc-fw-dev
  resource_group_name = var.resource_group_name
  location            = var.location
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"                       # Standard Tier
  firewall_policy_id  = azurerm_firewall_policy.main.id
  zones               = ["1", "2", "3"]                  # Zone Redundant

  ip_configuration {
    name                 = "fw-ip-config"
    subnet_id            = var.egress_subnet_id          # AzureFirewallSubnet
    public_ip_address_id = azurerm_public_ip.firewall.id # SNAT Public IP
  }

  tags = var.tags
}

# =============================================================================
# Firewall Rules (§5.3.2)
# =============================================================================

resource "azurerm_firewall_policy_rule_collection_group" "main" {
  name               = "nsc-rcg-default"
  firewall_policy_id = azurerm_firewall_policy.main.id
  priority           = 100

  application_rule_collection {
    name     = "allow-fqdn"                              # FQDN Allowlist
    priority = 100
    action   = "Allow"

    rule {
      name              = "allow-azure-auth"
      source_addresses  = [var.app_subnet_cidr]
      destination_fqdns = ["login.microsoftonline.com"]
      protocols {
        type = "Https"
        port = 443
      }
    }

    rule {
      name              = "allow-acr"                    # Container Registry
      source_addresses  = [var.app_subnet_cidr]
      destination_fqdns = ["*.azurecr.io"]
      protocols {
        type = "Https"
        port = 443
      }
    }

    rule {
      name              = "allow-mcr"                    # Microsoft Container Registry
      source_addresses  = [var.app_subnet_cidr]
      destination_fqdns = ["mcr.microsoft.com"]
      protocols {
        type = "Https"
        port = 443
      }
    }

    rule {
      name              = "allow-azure-mgmt"             # Azure Management
      source_addresses  = [var.app_subnet_cidr]
      destination_fqdns = ["management.azure.com"]       # ARM API
      protocols {
        type = "Https"
        port = 443
      }
    }

    rule {
      name              = "allow-upbit-api"              # §5.3.2: Upbit API
      source_addresses  = [var.app_subnet_cidr]
      destination_fqdns = ["api.upbit.com"]
      protocols {
        type = "Https"
        port = 443
      }
    }

    rule {
      name              = "allow-naver-api"              # §5.3.2: Naver API
      source_addresses  = [var.app_subnet_cidr]
      destination_fqdns = ["openapi.naver.com"]
      protocols {
        type = "Https"
        port = 443
      }
    }

    rule {
      name              = "allow-databricks-control"     # Databricks Control Plane
      source_addresses  = [var.analytics_subnet_cidr]
      destination_fqdns = ["*.azuredatabricks.net"]
      protocols {
        type = "Https"
        port = 443
      }
    }

    rule {
      name              = "allow-databricks-storage"     # Databricks DBFS
      source_addresses  = [var.analytics_subnet_cidr]
      destination_fqdns = ["*.blob.core.windows.net"]    # Blob Storage
      protocols {
        type = "Https"
        port = 443
      }
    }
  }

  network_rule_collection {
    name     = "allow-network"
    priority = 200
    action   = "Allow"

    rule {
      name                  = "allow-dns"
      source_addresses      = [var.vnet_cidr]
      destination_addresses = ["168.63.129.16"]          # Azure DNS
      destination_ports     = ["53"]
      protocols             = ["UDP"]
    }

    rule {
      name                  = "allow-ntp"
      source_addresses      = [var.vnet_cidr]
      destination_addresses = ["*"]
      destination_ports     = ["123"]
      protocols             = ["UDP"]
    }
  }
}
