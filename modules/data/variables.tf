# =============================================================================
# Data Module — Variables
# =============================================================================

variable "resource_group_name" {
  type = string                                         # RG 이름
}

variable "location" {
  type = string                                         # Azure 리전
}

variable "project_prefix" {
  type = string                                         # nsc
}

variable "environment" {
  type = string                                         # dev/stg/prod
}

variable "tenant_id" {
  type = string                                         # AAD 테넌트 ID
}

variable "current_object_id" {
  type = string                                         # 현재 사용자 Object ID
}

variable "pg_admin_password" {
  description = "PostgreSQL 초기 관리자 비밀번호"
  type        = string                                  # Key Vault에서 관리
  sensitive   = true                                    # 민감 정보
}

variable "tags" {
  type = map(string)
}
