# =============================================================================
# Network Module — Variables
# =============================================================================

variable "resource_group_name" {
  type = string                                         # RG 이름 (root에서 전달)
}

variable "location" {
  type = string                                         # Azure 리전 (root에서 전달)
}

variable "project_prefix" {
  type = string                                         # 네이밍 접두어: nsc
}

variable "environment" {
  type = string                                         # 환경: dev / stg / prod
}

variable "vnet_cidr" {
  type = string                                         # VNet 주소 공간: 10.0.0.0/16
}

variable "subnet_cidrs" {
  type = map(string)                                    # 서브넷 CIDR 맵 (§7.2)
}

variable "firewall_private_ip" {
  description = "Firewall Private IP for UDR next hop"
  type        = string                                  # UDR next hop 주소
}

variable "tags" {
  type = map(string)                                    # 공통 태그
}
