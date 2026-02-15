# =============================================================================
# Perimeter Module — Variables
# =============================================================================

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "project_prefix" {
  type = string                                         # nsc
}

variable "environment" {
  type = string                                         # dev/stg/prod
}

variable "perimeter_subnet_id" {
  description = "AppGW 배치 서브넷"
  type        = string                                  # Perimeter 서브넷 ID
}

variable "bastion_subnet_id" {
  description = "Bastion 배치 서브넷"
  type        = string                                  # AzureBastionSubnet ID
}

variable "egress_subnet_id" {
  description = "Firewall 배치 서브넷"
  type        = string                                  # AzureFirewallSubnet ID
}

variable "app_subnet_cidr" {
  description = "Application 서브넷 CIDR (Firewall 규칙 소스)"
  type        = string                                  # 10.0.2.0/23
}

variable "analytics_subnet_cidr" {
  description = "Analytics 서브넷 CIDR (Firewall 규칙 소스)"
  type        = string                                  # 10.0.6.0/23
}

variable "vnet_cidr" {
  description = "VNet 전체 CIDR (Network Rule 소스)"
  type        = string                                  # 10.0.0.0/16
}

variable "tags" {
  type = map(string)
}
