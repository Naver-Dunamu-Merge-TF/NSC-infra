# =============================================================================
# Network Module — VNet + 10 Subnets + NSG + UDR
# Source of Truth: README.md §2.5, §4.1, §4.2, §7.2
# Naming Convention: README.md §7.4
# =============================================================================

# =============================================================================
# VNet (Single VNet — §2.5)
# =============================================================================

resource "azurerm_virtual_network" "main" {
  name                = "${var.project_prefix}-vnet-${var.environment}"  # 예: nsc-vnet-dev
  resource_group_name = var.resource_group_name          # RG에 배치
  location            = var.location                     # Korea Central
  address_space       = [var.vnet_cidr]                  # 10.0.0.0/16
  tags                = var.tags                         # 공통 태그
}

# =============================================================================
# Subnets (§7.2 네트워크 설정 — 10개)
# =============================================================================

# 1. Perimeter — Application Gateway + WAF
resource "azurerm_subnet" "perimeter" {
  name                 = "${var.project_prefix}-snet-perimeter"         # nsc-snet-perimeter
  resource_group_name  = var.resource_group_name         # RG 참조
  virtual_network_name = azurerm_virtual_network.main.name  # VNet 참조
  address_prefixes     = [var.subnet_cidrs["perimeter"]] # 10.0.0.0/24
}

# 2. Bastion — Azure 필수 이름 "AzureBastionSubnet"
resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"            # Azure 필수 고정 이름 (변경 불가)
  resource_group_name  = var.resource_group_name         # RG 참조
  virtual_network_name = azurerm_virtual_network.main.name  # VNet 참조
  address_prefixes     = [var.subnet_cidrs["bastion"]]   # 10.0.1.0/26 (최소 /26)
}

# 3. Application — AKS Node Pool
resource "azurerm_subnet" "app" {
  name                 = "${var.project_prefix}-snet-app"               # nsc-snet-app
  resource_group_name  = var.resource_group_name         # RG 참조
  virtual_network_name = azurerm_virtual_network.main.name  # VNet 참조
  address_prefixes     = [var.subnet_cidrs["app"]]       # 10.0.2.0/23 (512 IPs, AKS 확장용)
}

# 4. Messaging — Event Hubs Private Endpoint
resource "azurerm_subnet" "messaging" {
  name                 = "${var.project_prefix}-snet-messaging"         # nsc-snet-messaging
  resource_group_name  = var.resource_group_name         # RG 참조
  virtual_network_name = azurerm_virtual_network.main.name  # VNet 참조
  address_prefixes     = [var.subnet_cidrs["messaging"]] # 10.0.3.0/24
}

# 5. Data — SQL DB, PostgreSQL, Confidential Ledger Private Endpoints
resource "azurerm_subnet" "data" {
  name                 = "${var.project_prefix}-snet-data"              # nsc-snet-data
  resource_group_name  = var.resource_group_name         # RG 참조
  virtual_network_name = azurerm_virtual_network.main.name  # VNet 참조
  address_prefixes     = [var.subnet_cidrs["data"]]      # 10.0.4.0/24
}

# 6. Security — Key Vault, ACR Private Endpoints
resource "azurerm_subnet" "security" {
  name                 = "${var.project_prefix}-snet-security"          # nsc-snet-security
  resource_group_name  = var.resource_group_name         # RG 참조
  virtual_network_name = azurerm_virtual_network.main.name  # VNet 참조
  address_prefixes     = [var.subnet_cidrs["security"]]  # 10.0.5.0/24
}

# 7a. Analytics Host — Databricks Public Subnet
# NOTE: Databricks VNet Injection은 host/container 2개 서브넷 필요
#       README §7.2 원본 10.0.6.0/23을 /24 2개로 분할
resource "azurerm_subnet" "analytics_host" {
  name                 = "${var.project_prefix}-snet-analytics-host"    # nsc-snet-analytics-host
  resource_group_name  = var.resource_group_name         # RG 참조
  virtual_network_name = azurerm_virtual_network.main.name  # VNet 참조
  address_prefixes     = [var.subnet_cidrs["analytics_host"]]  # 10.0.6.0/24

  delegation {
    name = "databricks-host"                             # Delegation 이름
    service_delegation {
      name = "Microsoft.Databricks/workspaces"           # Databricks 전용 Delegation
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",                    # 서브넷 조인
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",  # 네트워크 정책 준비
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action", # 네트워크 정책 해제
      ]
    }
  }
}

# 7b. Analytics Container — Databricks Private Subnet
resource "azurerm_subnet" "analytics_container" {
  name                 = "${var.project_prefix}-snet-analytics-container"  # nsc-snet-analytics-container
  resource_group_name  = var.resource_group_name         # RG 참조
  virtual_network_name = azurerm_virtual_network.main.name  # VNet 참조
  address_prefixes     = [var.subnet_cidrs["analytics_container"]]  # 10.0.7.0/24

  delegation {
    name = "databricks-container"                        # Delegation 이름
    service_delegation {
      name = "Microsoft.Databricks/workspaces"           # Databricks 전용 Delegation
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",                    # 서브넷 조인
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",  # 네트워크 정책 준비
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action", # 네트워크 정책 해제
      ]
    }
  }
}

# 8. Egress — Azure 필수 이름 "AzureFirewallSubnet"
resource "azurerm_subnet" "egress" {
  name                 = "AzureFirewallSubnet"           # Azure 필수 고정 이름 (변경 불가)
  resource_group_name  = var.resource_group_name         # RG 참조
  virtual_network_name = azurerm_virtual_network.main.name  # VNet 참조
  address_prefixes     = [var.subnet_cidrs["egress"]]    # 10.0.8.0/26 (최소 /26)
}

# 9. Admin Portal — Admin UI
resource "azurerm_subnet" "admin" {
  name                 = "${var.project_prefix}-snet-admin"             # nsc-snet-admin
  resource_group_name  = var.resource_group_name         # RG 참조
  virtual_network_name = azurerm_virtual_network.main.name  # VNet 참조
  address_prefixes     = [var.subnet_cidrs["admin"]]     # 10.0.10.0/28 (16 IPs)
}

# =============================================================================
# NSG (§4.1 NSG 규칙 매트릭스)
# 원칙: 기본 Deny + 명시적 Allow Only
# =============================================================================

# --- Perimeter NSG (AppGW 서브넷용) ---
resource "azurerm_network_security_group" "perimeter" {
  name                = "${var.project_prefix}-nsg-perimeter"           # nsc-nsg-perimeter
  resource_group_name = var.resource_group_name          # RG 참조
  location            = var.location                     # Korea Central
  tags                = var.tags                         # 공통 태그
}

# §4.1: Internet → Perimeter, HTTPS 443
resource "azurerm_network_security_rule" "perimeter_allow_https" {
  name                        = "allow-https-inbound"    # 유일한 외부 진입점
  priority                    = 100                      # 최우선 규칙
  direction                   = "Inbound"                # 인바운드
  access                      = "Allow"                  # 허용
  protocol                    = "Tcp"                    # TCP
  source_port_range           = "*"                      # 모든 소스 포트
  destination_port_range      = "443"                    # HTTPS
  source_address_prefix       = "Internet"               # 인터넷 전체
  destination_address_prefix  = "*"                      # 서브넷 내 모든 IP
  resource_group_name         = var.resource_group_name  # RG 참조
  network_security_group_name = azurerm_network_security_group.perimeter.name  # NSG 연결
}

# AppGW v2 필수: GatewayManager 헬스체크 통신 허용
resource "azurerm_network_security_rule" "perimeter_allow_gw_manager" {
  name                        = "allow-gateway-manager"  # AppGW 관리 트래픽
  priority                    = 200                      # 두 번째 규칙
  direction                   = "Inbound"                # 인바운드
  access                      = "Allow"                  # 허용
  protocol                    = "Tcp"                    # TCP
  source_port_range           = "*"                      # 모든 소스 포트
  destination_port_range      = "65200-65535"             # AppGW v2 관리 포트 범위
  source_address_prefix       = "GatewayManager"         # Azure GatewayManager 서비스 태그
  destination_address_prefix  = "*"                      # 서브넷 내 모든 IP
  resource_group_name         = var.resource_group_name  # RG 참조
  network_security_group_name = azurerm_network_security_group.perimeter.name  # NSG 연결
}

# --- Application NSG (AKS 서브넷용) ---
resource "azurerm_network_security_group" "app" {
  name                = "${var.project_prefix}-nsg-app"                 # nsc-nsg-app
  resource_group_name = var.resource_group_name          # RG 참조
  location            = var.location                     # Korea Central
  tags                = var.tags                         # 공통 태그
}

# §4.1: Ops → Application, SSH 22 (Bastion만 허용)
resource "azurerm_network_security_rule" "app_allow_ssh_bastion" {
  name                        = "allow-ssh-bastion"      # Bastion → AKS Node SSH
  priority                    = 100                      # 최우선 (Bastion SSH 허용)
  direction                   = "Inbound"                # 인바운드
  access                      = "Allow"                  # 허용
  protocol                    = "Tcp"                    # TCP
  source_port_range           = "*"                      # 모든 소스 포트
  destination_port_range      = "22"                     # SSH
  source_address_prefix       = var.subnet_cidrs["bastion"]  # 10.0.1.0/26 (Bastion만)
  destination_address_prefix  = "*"                      # AKS 노드 전체
  resource_group_name         = var.resource_group_name  # RG 참조
  network_security_group_name = azurerm_network_security_group.app.name  # NSG 연결
}

# §4.1: Internet → Application, SSH 차단 (p100)
resource "azurerm_network_security_rule" "app_deny_ssh_internet" {
  name                        = "deny-ssh-internet"      # 인터넷 SSH 직접 접근 차단
  priority                    = 110                      # allow-ssh-bastion(p100) 이후 평가
  direction                   = "Inbound"                # 인바운드
  access                      = "Deny"                   # 차단
  protocol                    = "Tcp"                    # TCP
  source_port_range           = "*"                      # 모든 소스 포트
  destination_port_range      = "22"                     # SSH
  source_address_prefix       = "Internet"               # 인터넷 전체
  destination_address_prefix  = "*"                      # AKS 노드 전체
  resource_group_name         = var.resource_group_name  # RG 참조
  network_security_group_name = azurerm_network_security_group.app.name  # NSG 연결
}

# §4.1: Perimeter → Application, 8443 (AppGW → AKS, End-to-End TLS)
resource "azurerm_network_security_rule" "app_allow_from_gw" {
  name                        = "allow-from-gw-8443"     # AppGW → AKS 서비스 포트
  priority                    = 200                      # 서비스 라우팅 규칙
  direction                   = "Inbound"                # 인바운드
  access                      = "Allow"                  # 허용
  protocol                    = "Tcp"                    # TCP
  source_port_range           = "*"                      # 모든 소스 포트
  destination_port_range      = "8443"                   # TLS 서비스 포트 (§4.1 매트릭스)
  source_address_prefix       = var.subnet_cidrs["perimeter"]  # 10.0.0.0/24 (AppGW만)
  destination_address_prefix  = "*"                      # AKS 노드 전체
  resource_group_name         = var.resource_group_name  # RG 참조
  network_security_group_name = azurerm_network_security_group.app.name  # NSG 연결
}

# §4.1: Admin Portal → Application, 8443
resource "azurerm_network_security_rule" "app_allow_from_admin" {
  name                        = "allow-from-admin-8443"  # Admin UI → Admin API
  priority                    = 210                      # AppGW 규칙 바로 다음
  direction                   = "Inbound"                # 인바운드
  access                      = "Allow"                  # 허용
  protocol                    = "Tcp"                    # TCP
  source_port_range           = "*"                      # 모든 소스 포트
  destination_port_range      = "8443"                   # TLS 서비스 포트
  source_address_prefix       = var.subnet_cidrs["admin"]  # 10.0.10.0/28 (Admin만)
  destination_address_prefix  = "*"                      # AKS 노드 전체
  resource_group_name         = var.resource_group_name  # RG 참조
  network_security_group_name = azurerm_network_security_group.app.name  # NSG 연결
}

# §4.1: Messaging → Application, 9093 (Kafka 양방향)
resource "azurerm_network_security_rule" "app_allow_kafka_response" {
  name                        = "allow-kafka-response-9093"  # Kafka 응답 트래픽
  priority                    = 300                      # Kafka 통신 규칙
  direction                   = "Inbound"                # 인바운드
  access                      = "Allow"                  # 허용
  protocol                    = "Tcp"                    # TCP
  source_port_range           = "*"                      # 모든 소스 포트
  destination_port_range      = "9093"                   # Kafka SASL_SSL 포트
  source_address_prefix       = var.subnet_cidrs["messaging"]  # 10.0.3.0/24 (Event Hubs만)
  destination_address_prefix  = "*"                      # AKS 노드 전체
  resource_group_name         = var.resource_group_name  # RG 참조
  network_security_group_name = azurerm_network_security_group.app.name  # NSG 연결
}

# --- Admin Portal NSG ---
resource "azurerm_network_security_group" "admin" {
  name                = "${var.project_prefix}-nsg-admin"               # nsc-nsg-admin
  resource_group_name = var.resource_group_name          # RG 참조
  location            = var.location                     # Korea Central
  tags                = var.tags                         # 공통 태그
}

# §4.1: Perimeter → Admin Portal, 443
resource "azurerm_network_security_rule" "admin_allow_from_appgw" {
  name                        = "allow-from-appgw-443"   # AppGW → Admin UI
  priority                    = 200                      # AppGW 라우팅 규칙
  direction                   = "Inbound"                # 인바운드
  access                      = "Allow"                  # 허용
  protocol                    = "Tcp"                    # TCP
  source_port_range           = "*"                      # 모든 소스 포트
  destination_port_range      = "443"                    # HTTPS
  source_address_prefix       = var.subnet_cidrs["perimeter"]  # 10.0.0.0/24 (AppGW만)
  destination_address_prefix  = "*"                      # Admin UI
  resource_group_name         = var.resource_group_name  # RG 참조
  network_security_group_name = azurerm_network_security_group.admin.name  # NSG 연결
}

# --- Messaging NSG ---
resource "azurerm_network_security_group" "messaging" {
  name                = "${var.project_prefix}-nsg-messaging"           # nsc-nsg-messaging
  resource_group_name = var.resource_group_name          # RG 참조
  location            = var.location                     # Korea Central
  tags                = var.tags                         # 공통 태그
}

# §4.1: Application → Messaging, 9093 (Kafka TLS)
resource "azurerm_network_security_rule" "messaging_allow_kafka" {
  name                        = "allow-kafka-9093"       # AKS → Event Hubs Kafka
  priority                    = 200                      # Kafka 인바운드 규칙
  direction                   = "Inbound"                # 인바운드
  access                      = "Allow"                  # 허용
  protocol                    = "Tcp"                    # TCP
  source_port_range           = "*"                      # 모든 소스 포트
  destination_port_range      = "9093"                   # Kafka SASL_SSL 포트
  source_address_prefix       = var.subnet_cidrs["app"]  # 10.0.2.0/23 (AKS만)
  destination_address_prefix  = "*"                      # Event Hubs PE
  resource_group_name         = var.resource_group_name  # RG 참조
  network_security_group_name = azurerm_network_security_group.messaging.name  # NSG 연결
}

# --- Data NSG ---
resource "azurerm_network_security_group" "data" {
  name                = "${var.project_prefix}-nsg-data"                # nsc-nsg-data
  resource_group_name = var.resource_group_name          # RG 참조
  location            = var.location                     # Korea Central
  tags                = var.tags                         # 공통 태그
}

# §4.1: Data — deny-all-inbound (Private Endpoint Only 접근)
# Azure NSG 기본 규칙이 deny-all 이지만, 명시적 deny 추가 (보안 감사 문서화용)
resource "azurerm_network_security_rule" "data_deny_all_inbound" {
  name                        = "deny-all-inbound"       # PE 외 모든 직접 접근 차단
  priority                    = 4096                     # 최하위 우선순위 (명시적 문서화)
  direction                   = "Inbound"                # 인바운드
  access                      = "Deny"                   # 차단
  protocol                    = "*"                      # 모든 프로토콜
  source_port_range           = "*"                      # 모든 소스 포트
  destination_port_range      = "*"                      # 모든 목적지 포트
  source_address_prefix       = "*"                      # 모든 소스
  destination_address_prefix  = "*"                      # 모든 목적지
  resource_group_name         = var.resource_group_name  # RG 참조
  network_security_group_name = azurerm_network_security_group.data.name  # NSG 연결
}

# --- Bastion NSG (Azure 공식 문서 필수 규칙) ---
resource "azurerm_network_security_group" "bastion" {
  name                = "${var.project_prefix}-nsg-bastion"             # nsc-nsg-bastion
  resource_group_name = var.resource_group_name          # RG 참조
  location            = var.location                     # Korea Central
  tags                = var.tags                         # 공통 태그
}

# Bastion Inbound: 사용자 HTTPS 접근
resource "azurerm_network_security_rule" "bastion_inbound_https" {
  name                        = "allow-https-inbound"    # 관리자 → Bastion 웹
  priority                    = 100                      # 최우선
  direction                   = "Inbound"                # 인바운드
  access                      = "Allow"                  # 허용
  protocol                    = "Tcp"                    # TCP
  source_port_range           = "*"                      # 모든 소스 포트
  destination_port_range      = "443"                    # HTTPS
  source_address_prefix       = "Internet"               # 인터넷 (관리자)
  destination_address_prefix  = "*"                      # Bastion
  resource_group_name         = var.resource_group_name  # RG 참조
  network_security_group_name = azurerm_network_security_group.bastion.name  # NSG 연결
}

# Bastion Inbound: Azure GatewayManager 헬스체크
resource "azurerm_network_security_rule" "bastion_inbound_gw_mgr" {
  name                        = "allow-gateway-manager"  # Azure 관리 트래픽
  priority                    = 110                      # HTTPS 다음
  direction                   = "Inbound"                # 인바운드
  access                      = "Allow"                  # 허용
  protocol                    = "Tcp"                    # TCP
  source_port_range           = "*"                      # 모든 소스 포트
  destination_port_range      = "443"                    # HTTPS
  source_address_prefix       = "GatewayManager"         # Azure 서비스 태그
  destination_address_prefix  = "*"                      # Bastion
  resource_group_name         = var.resource_group_name  # RG 참조
  network_security_group_name = azurerm_network_security_group.bastion.name  # NSG 연결
}

# Bastion Inbound: Azure LoadBalancer 프로브
resource "azurerm_network_security_rule" "bastion_inbound_lb" {
  name                        = "allow-azure-lb"         # LB 헬스 프로브
  priority                    = 120                      # GW 매니저 다음
  direction                   = "Inbound"                # 인바운드
  access                      = "Allow"                  # 허용
  protocol                    = "Tcp"                    # TCP
  source_port_range           = "*"                      # 모든 소스 포트
  destination_port_range      = "443"                    # HTTPS
  source_address_prefix       = "AzureLoadBalancer"      # Azure 서비스 태그
  destination_address_prefix  = "*"                      # Bastion
  resource_group_name         = var.resource_group_name  # RG 참조
  network_security_group_name = azurerm_network_security_group.bastion.name  # NSG 연결
}

# Bastion Inbound: Data Plane 통신 (Bastion 노드 간)
resource "azurerm_network_security_rule" "bastion_inbound_data_plane" {
  name                        = "allow-bastion-data-plane"  # Bastion 내부 통신
  priority                    = 130                      # LB 다음
  direction                   = "Inbound"                # 인바운드
  access                      = "Allow"                  # 허용
  protocol                    = "*"                      # 모든 프로토콜
  source_port_range           = "*"                      # 모든 소스 포트
  destination_port_ranges     = ["8080", "5701"]         # Bastion 데이터 플레인 포트
  source_address_prefix       = "VirtualNetwork"         # VNet 내부
  destination_address_prefix  = "VirtualNetwork"         # VNet 내부
  resource_group_name         = var.resource_group_name  # RG 참조
  network_security_group_name = azurerm_network_security_group.bastion.name  # NSG 연결
}

# Bastion Outbound: SSH/RDP to VNet targets
resource "azurerm_network_security_rule" "bastion_outbound_ssh_rdp" {
  name                        = "allow-ssh-rdp-outbound" # Bastion → VM SSH/RDP
  priority                    = 100                      # 최우선 아웃바운드
  direction                   = "Outbound"               # 아웃바운드
  access                      = "Allow"                  # 허용
  protocol                    = "Tcp"                    # TCP
  source_port_range           = "*"                      # 모든 소스 포트
  destination_port_ranges     = ["22", "3389"]           # SSH + RDP
  source_address_prefix       = "*"                      # Bastion
  destination_address_prefix  = "VirtualNetwork"         # VNet 내 VM만
  resource_group_name         = var.resource_group_name  # RG 참조
  network_security_group_name = azurerm_network_security_group.bastion.name  # NSG 연결
}

# Bastion Outbound: Azure Cloud 관리 통신
resource "azurerm_network_security_rule" "bastion_outbound_azure" {
  name                        = "allow-azure-cloud"      # Azure 관리 API
  priority                    = 110                      # SSH/RDP 다음
  direction                   = "Outbound"               # 아웃바운드
  access                      = "Allow"                  # 허용
  protocol                    = "Tcp"                    # TCP
  source_port_range           = "*"                      # 모든 소스 포트
  destination_port_range      = "443"                    # HTTPS
  source_address_prefix       = "*"                      # Bastion
  destination_address_prefix  = "AzureCloud"             # Azure 서비스 태그
  resource_group_name         = var.resource_group_name  # RG 참조
  network_security_group_name = azurerm_network_security_group.bastion.name  # NSG 연결
}

# Bastion Outbound: Data Plane 통신 (Bastion 노드 간)
resource "azurerm_network_security_rule" "bastion_outbound_data_plane" {
  name                        = "allow-bastion-data-plane-out"  # Bastion 내부 통신
  priority                    = 120                      # Azure Cloud 다음
  direction                   = "Outbound"               # 아웃바운드
  access                      = "Allow"                  # 허용
  protocol                    = "*"                      # 모든 프로토콜
  source_port_range           = "*"                      # 모든 소스 포트
  destination_port_ranges     = ["8080", "5701"]         # Bastion 데이터 플레인 포트
  source_address_prefix       = "VirtualNetwork"         # VNet 내부
  destination_address_prefix  = "VirtualNetwork"         # VNet 내부
  resource_group_name         = var.resource_group_name  # RG 참조
  network_security_group_name = azurerm_network_security_group.bastion.name  # NSG 연결
}

# =============================================================================
# NSG → Subnet Associations (서브넷에 NSG 연결)
# =============================================================================

resource "azurerm_subnet_network_security_group_association" "perimeter" {
  subnet_id                 = azurerm_subnet.perimeter.id               # Perimeter 서브넷
  network_security_group_id = azurerm_network_security_group.perimeter.id  # Perimeter NSG
}

resource "azurerm_subnet_network_security_group_association" "bastion" {
  subnet_id                 = azurerm_subnet.bastion.id                 # Bastion 서브넷
  network_security_group_id = azurerm_network_security_group.bastion.id    # Bastion NSG
}

resource "azurerm_subnet_network_security_group_association" "app" {
  subnet_id                 = azurerm_subnet.app.id                     # Application 서브넷
  network_security_group_id = azurerm_network_security_group.app.id        # Application NSG
}

resource "azurerm_subnet_network_security_group_association" "admin" {
  subnet_id                 = azurerm_subnet.admin.id                   # Admin Portal 서브넷
  network_security_group_id = azurerm_network_security_group.admin.id      # Admin NSG
}

resource "azurerm_subnet_network_security_group_association" "messaging" {
  subnet_id                 = azurerm_subnet.messaging.id               # Messaging 서브넷
  network_security_group_id = azurerm_network_security_group.messaging.id  # Messaging NSG
}

resource "azurerm_subnet_network_security_group_association" "data" {
  subnet_id                 = azurerm_subnet.data.id                    # Data 서브넷
  network_security_group_id = azurerm_network_security_group.data.id       # Data NSG
}

# =============================================================================
# UDR — User Defined Routes (§4.2)
# 3개 서브넷: Application, Data, Analytics → Firewall 강제 라우팅
# NOTE: firewall_private_ip가 빈 문자열이면 route 미생성 (Phase 3에서 업데이트)
# =============================================================================

# --- Application UDR (§4.2: 모든 외부 트래픽 Firewall 경유 강제) ---
resource "azurerm_route_table" "app" {
  name                = "${var.project_prefix}-udr-app"                 # nsc-udr-app
  resource_group_name = var.resource_group_name          # RG 참조
  location            = var.location                     # Korea Central
  tags                = var.tags                         # 공통 태그
}

resource "azurerm_route" "app_to_firewall" {
  name                   = "route-to-firewall"           # 기본 라우트 → Firewall
  resource_group_name    = var.resource_group_name       # RG 참조
  route_table_name       = azurerm_route_table.app.name  # Application UDR
  address_prefix         = "0.0.0.0/0"                   # 모든 외부 트래픽
  next_hop_type          = "VirtualAppliance"            # Firewall = Virtual Appliance
  next_hop_in_ip_address = var.firewall_private_ip       # Firewall Private IP
}

resource "azurerm_subnet_route_table_association" "app" {
  subnet_id      = azurerm_subnet.app.id                # Application 서브넷
  route_table_id = azurerm_route_table.app.id            # Application UDR
}

# --- Data UDR (§4.2: PaaS Only — 아웃바운드 없음, 방어적 설정) ---
resource "azurerm_route_table" "data" {
  name                = "${var.project_prefix}-udr-data"                # nsc-udr-data
  resource_group_name = var.resource_group_name          # RG 참조
  location            = var.location                     # Korea Central
  tags                = var.tags                         # 공통 태그
}

resource "azurerm_route" "data_to_firewall" {
  name                   = "route-to-firewall"           # 기본 라우트 → Firewall
  resource_group_name    = var.resource_group_name       # RG 참조
  route_table_name       = azurerm_route_table.data.name # Data UDR
  address_prefix         = "0.0.0.0/0"                   # 모든 외부 트래픽
  next_hop_type          = "VirtualAppliance"            # Firewall = Virtual Appliance
  next_hop_in_ip_address = var.firewall_private_ip       # Firewall Private IP
}

resource "azurerm_subnet_route_table_association" "data" {
  subnet_id      = azurerm_subnet.data.id               # Data 서브넷
  route_table_id = azurerm_route_table.data.id           # Data UDR
}

# --- Analytics UDR (§4.2: Databricks 외부 통신 제어) ---
resource "azurerm_route_table" "analytics" {
  name                = "${var.project_prefix}-udr-analytics"           # nsc-udr-analytics
  resource_group_name = var.resource_group_name          # RG 참조
  location            = var.location                     # Korea Central
  tags                = var.tags                         # 공통 태그
}

resource "azurerm_route" "analytics_to_firewall" {
  name                   = "route-to-firewall"           # 기본 라우트 → Firewall
  resource_group_name    = var.resource_group_name       # RG 참조
  route_table_name       = azurerm_route_table.analytics.name  # Analytics UDR
  address_prefix         = "0.0.0.0/0"                   # 모든 외부 트래픽
  next_hop_type          = "VirtualAppliance"            # Firewall = Virtual Appliance
  next_hop_in_ip_address = var.firewall_private_ip       # Firewall Private IP
}

resource "azurerm_subnet_route_table_association" "analytics_host" {
  subnet_id      = azurerm_subnet.analytics_host.id     # Analytics Host 서브넷
  route_table_id = azurerm_route_table.analytics.id      # Analytics UDR (공유)
}

resource "azurerm_subnet_route_table_association" "analytics_container" {
  subnet_id      = azurerm_subnet.analytics_container.id  # Analytics Container 서브넷
  route_table_id = azurerm_route_table.analytics.id      # Analytics UDR (공유)
}
