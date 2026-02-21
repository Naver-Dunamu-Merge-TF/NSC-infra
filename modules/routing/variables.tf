# =============================================================================
# Routing Module — Variables
# =============================================================================

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "project_prefix" {
  type = string
}

variable "firewall_private_ip" {
  description = "Firewall Private IP for UDR next hop"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet ID map from Network module"
  type        = map(string)
}

variable "tags" {
  type = map(string)
}
