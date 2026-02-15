# =============================================================================
# Monitoring Module — Variables
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

variable "tags" {
  type = map(string)                                    # 공통 태그
}
