# =============================================================================
# Messaging Module — Variables
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

variable "tags" {
  type = map(string)
}
