# =============================================================================
# terraform.tfvars — README.md §7.2, §7.4 실제 배포 값
# =============================================================================

location       = "Korea Central"                        # 한국 중부 리전
project_prefix = "nsc"                                  # 네이밍 접두어 (§7.4)
environment    = "dev"                                  # 개발 환경

vnet_cidr = "10.0.0.0/16"                               # Single VNet 주소 공간

# §7.2 서브넷 CIDR 블록
# Analytics는 Databricks VNet Injection 요구사항으로 host/container 2개로 분할
# (README §7.2 원본: 10.0.6.0/23 → 10.0.6.0/24 + 10.0.7.0/24)
subnet_cidrs = {
  perimeter           = "10.0.0.0/24"                   # Layer 2: AppGW + WAF
  bastion             = "10.0.1.0/26"                   # Layer 3: Azure Bastion
  app                 = "10.0.2.0/23"                   # Layer 3: AKS Node Pool
  messaging           = "10.0.9.0/24"                   # Layer 4: Event Hubs
  data                = "10.0.4.0/24"                   # Layer 5: SQL/PG/Ledger
  security            = "10.0.5.0/24"                   # Layer 6: KV/ACR/DNS
  analytics_host      = "10.0.6.0/24"                   # Layer 7: Databricks Host
  analytics_container = "10.0.7.0/24"                   # Layer 7: Databricks Container
  egress              = "10.0.8.0/26"                   # Layer 8: Azure Firewall
  admin               = "10.0.10.0/28"                  # Layer 3: Admin Portal
}

tags = {
  Project     = "NSC-Platform"                          # 프로젝트 식별자
  Environment = "dev"                                   # 환경 식별자
  ManagedBy   = "Terraform"                             # IaC 관리 표시
}
