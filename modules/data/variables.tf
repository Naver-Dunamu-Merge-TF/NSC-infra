# =============================================================================
# Data Module — Variables
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

variable "tenant_id" {
  type = string
}

variable "current_object_id" {
  type = string
}

variable "pg_admin_password" {
  description = "PostgreSQL 초기 관리자 비밀번호"
  type        = string
  sensitive   = true
}

variable "tags" {
  type = map(string)
}
