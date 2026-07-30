# =============================================================================
# Project : Project 3 - Python App CI/CD on Azure AKS
# Author  : Sanjay Naidu
# File    : terraform/modules/network/variables.tf
# =============================================================================

variable "name_prefix" {
  description = "Prefix for network resource names."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group for the network."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "vnet_address_space" {
  description = "VNet CIDR."
  type        = string
}

variable "aks_subnet_cidr" {
  description = "AKS node subnet CIDR."
  type        = string
}

variable "tags" {
  description = "Resource tags."
  type        = map(string)
  default     = {}
}
