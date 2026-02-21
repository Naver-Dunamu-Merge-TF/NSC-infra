# =============================================================================
# Messaging Module — Variables
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

variable "tags" {
  type = map(string)
}
