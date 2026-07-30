# =============================================================================
# Project : Project 3 - Python App CI/CD on Azure AKS
# Author  : Sanjay Naidu
# File    : terraform/modules/acr/variables.tf
# =============================================================================

variable "name" {
  description = "Registry name - globally unique, alphanumeric only."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9]{5,50}$", var.name))
    error_message = "ACR name must be 5-50 alphanumeric characters (no hyphens)."
  }
}

variable "resource_group_name" {
  description = "Resource group for the registry."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "sku" {
  description = "Registry SKU. Basic is the cost-optimised choice for this project."
  type        = string
  default     = "Basic"
}

variable "tags" {
  description = "Resource tags."
  type        = map(string)
  default     = {}
}
