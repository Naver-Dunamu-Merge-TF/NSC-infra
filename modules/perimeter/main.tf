# =============================================================================
# Perimeter Module — AppGW + WAF + Bastion + Firewall
# Source of Truth: README.md §5.3, §7.1, §7.2
# =============================================================================

# =============================================================================
# Public IPs (§7.2: 3개)
# =============================================================================

resource "azurerm_public_ip" "agw" {
  name                = "${var.project_prefix}-pip-agw"        # nsc-pip-agw
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"                         # AppGW v2 필수
  sku                 = "Standard"                       # Zone Redundant 필수
  zones               = ["1", "2", "3"]                  # Zone Redundant
  tags                = var.tags
}

resource "azurerm_public_ip" "bastion" {
  name                = "${var.project_prefix}-pip-bas"        # nsc-pip-bas
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"                         # Bastion 필수
  sku                 = "Standard"                       # Standard SKU 필수
  tags                = var.tags
}

resource "azurerm_public_ip" "firewall" {
  name                = "${var.project_prefix}-pip-fw"         # nsc-pip-fw
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"                         # Firewall SNAT
  sku                 = "Standard"                       # Standard SKU 필수
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
    enabled                     = true                   # WAF 활성화
    mode                        = "Prevention"           # §5.3.1: Prevention 모드
    max_request_body_size_in_kb = 128                    # 최대 요청 본문 128KB
    file_upload_limit_in_mb     = 100                    # 파일 업로드 100MB
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
  firewall_policy_id  = azurerm_web_application_firewall_policy.main.id  # WAF 연결
  zones               = ["1", "2", "3"]                  # Zone Redundant
  enable_http2        = true                             # HTTP/2 활성화

  sku {
    name = "WAF_v2"                                      # §7.1: WAF_v2 SKU
    tier = "WAF_v2"                                      # WAF_v2 Tier
  }

  autoscale_configuration {
    min_capacity = 2                                     # §7.1: AutoScale 최소 2
    max_capacity = 10                                    # §7.1: AutoScale 최대 10
  }

  gateway_ip_configuration {
    name      = "gateway-ip"                             # 게이트웨이 IP 구성
    subnet_id = var.perimeter_subnet_id                  # Perimeter 서브넷
  }

  frontend_ip_configuration {
    name                 = "frontend-public-ip"          # 프론트엔드 IP
    public_ip_address_id = azurerm_public_ip.agw.id      # Public IP 연결
  }

  frontend_port {
    name = "http-port"                                   # HTTP 포트 (TLS 인증서 추가 시 443 전환)
    port = 80                                            # TODO: 운영 시 443 + TLS
  }

  backend_address_pool {
    name = "aks-backend-pool"                            # AKS 백엔드 풀
  }

  backend_http_settings {
    name                  = "aks-http-settings"          # 백엔드 HTTP 설정
    cookie_based_affinity = "Disabled"                   # 세션 어피니티 비활성화
    port                  = 8443                         # §4.1: AKS TLS 포트
    protocol              = "Https"                      # End-to-End TLS
    request_timeout       = 30                           # 30초 타임아웃
  }

  http_listener {
    name                           = "http-listener"     # HTTP 리스너
    frontend_ip_configuration_name = "frontend-public-ip"
    frontend_port_name             = "http-port"
    protocol                       = "Http"              # TODO: Https + SSL Cert
  }

  request_routing_rule {
    name                       = "default-routing-rule"  # 기본 라우팅
    priority                   = 100                     # 최우선 규칙
    rule_type                  = "Basic"                 # Basic 라우팅
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
    name                 = "bastion-ip-config"           # IP 구성
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
  sku_name            = "AZFW_VNet"                      # VNet 방화벽
  sku_tier            = "Standard"                       # Standard Tier
  firewall_policy_id  = azurerm_firewall_policy.main.id  # 정책 연결
  zones               = ["1", "2", "3"]                  # Zone Redundant

  ip_configuration {
    name                 = "fw-ip-config"                # IP 구성
    subnet_id            = var.egress_subnet_id          # AzureFirewallSubnet
    public_ip_address_id = azurerm_public_ip.firewall.id # SNAT Public IP
  }

  tags = var.tags
}

# =============================================================================
# Firewall Rules (§5.3.2)
# =============================================================================

resource "azurerm_firewall_policy_rule_collection_group" "main" {
  name               = "nsc-rcg-default"                 # 기본 규칙 그룹
  firewall_policy_id = azurerm_firewall_policy.main.id
  priority           = 100                               # 최우선 그룹

  # §5.3.2 Application Rules (FQDN 기반)
  application_rule_collection {
    name     = "allow-fqdn"                              # FQDN Allowlist
    priority = 100
    action   = "Allow"

    rule {
      name              = "allow-azure-auth"             # Azure 인증
      source_addresses  = [var.app_subnet_cidr]          # App 서브넷
      destination_fqdns = ["login.microsoftonline.com"]  # AAD 로그인
      protocols {
        type = "Https"
        port = 443
      }
    }

    rule {
      name              = "allow-acr"                    # Container Registry
      source_addresses  = [var.app_subnet_cidr]
      destination_fqdns = ["*.azurecr.io"]               # ACR 도메인
      protocols {
        type = "Https"
        port = 443
      }
    }

    rule {
      name              = "allow-mcr"                    # Microsoft Container Registry
      source_addresses  = [var.app_subnet_cidr]
      destination_fqdns = ["mcr.microsoft.com"]          # 공식 이미지
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
      destination_fqdns = ["api.upbit.com"]              # 거래소 API
      protocols {
        type = "Https"
        port = 443
      }
    }

    rule {
      name              = "allow-naver-api"              # §5.3.2: Naver API
      source_addresses  = [var.app_subnet_cidr]
      destination_fqdns = ["openapi.naver.com"]          # 네이버 API
      protocols {
        type = "Https"
        port = 443
      }
    }

    rule {
      name              = "allow-databricks-control"     # Databricks Control Plane
      source_addresses  = [var.analytics_subnet_cidr]
      destination_fqdns = ["*.azuredatabricks.net"]      # Databricks 컨트롤 플레인
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

  # §5.3.2 Network Rules (IP/포트 기반)
  network_rule_collection {
    name     = "allow-network"                           # 네트워크 규칙
    priority = 200
    action   = "Allow"

    rule {
      name                  = "allow-dns"                # DNS 해석
      source_addresses      = [var.vnet_cidr]            # VNet 전체
      destination_addresses = ["168.63.129.16"]          # Azure DNS
      destination_ports     = ["53"]                     # DNS 포트
      protocols             = ["UDP"]
    }

    rule {
      name                  = "allow-ntp"                # 시간 동기화
      source_addresses      = [var.vnet_cidr]
      destination_addresses = ["*"]                      # NTP 서버
      destination_ports     = ["123"]                    # NTP 포트
      protocols             = ["UDP"]
    }
  }
}
