# =============================================================================
# 전역 변수 — README.md §7.2, §7.4 기반
# =============================================================================

variable "location" {
  description = "Azure region"
  type        = string
  default     = "Korea Central"                         # 한국 중부 리전
}

variable "project_prefix" {
  description = "리소스 네이밍 접두어 (§7.4)"
  type        = string
  default     = "nsc"                                   # Next-generation Standard Commerce
}

variable "environment" {
  description = "환경 (dev / stg / prod)"
  type        = string
  default     = "dev"                                   # 개발 환경
}

variable "vnet_cidr" {
  description = "VNet 주소 공간"
  type        = string
  default     = "10.0.0.0/16"                           # 65,536 IPs
}

variable "subnet_cidrs" {
  description = "서브넷 CIDR 블록 (§7.2 네트워크 설정)"
  type        = map(string)
  default = {
    perimeter           = "10.0.0.0/24"                 # AppGW + WAF (256 IPs)
    bastion             = "10.0.1.0/26"                 # Azure Bastion (64 IPs)
    app                 = "10.0.2.0/23"                 # AKS Node Pool (512 IPs)
    messaging           = "10.0.9.0/24"                 # Event Hubs PE (256 IPs)
    data                = "10.0.4.0/24"                 # SQL/PG/Ledger PE (256 IPs)
    security            = "10.0.5.0/24"                 # KV/ACR PE (256 IPs)
    analytics_host      = "10.0.6.0/24"                 # Databricks Host (/23 분할)
    analytics_container = "10.0.7.0/24"                 # Databricks Container (/23 분할)
    egress              = "10.0.8.0/26"                 # Azure Firewall (64 IPs)
    admin               = "10.0.10.0/28"                # Admin UI (16 IPs)
  }
}

variable "pg_admin_password" {
  description = "PostgreSQL 초기 관리자 비밀번호"
  type        = string                                  # terraform.tfvars 또는 TF_VAR_
  sensitive   = true                                    # 민감 정보 마스킹
}

variable "tags" {
  description = "공통 태그"
  type        = map(string)
  default = {
    Project     = "NSC-Platform"                        # 프로젝트 식별
    Environment = "dev"                                 # 환경 식별
    ManagedBy   = "Terraform"                           # IaC 관리 표시
  }
}
