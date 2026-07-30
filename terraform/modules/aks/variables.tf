# =============================================================================
# Project : Project 3 - Python App CI/CD on Azure AKS
# Author  : Sanjay Naidu
# File    : terraform/modules/aks/variables.tf
# =============================================================================

variable "name" {
  description = "AKS cluster name."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group for the cluster."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version (null = AKS default)."
  type        = string
  default     = null
}

variable "node_vm_size" {
  description = "Node VM size."
  type        = string
}

variable "min_node_count" {
  description = "Autoscaler minimum node count."
  type        = number
}

variable "max_node_count" {
  description = "Autoscaler maximum node count."
  type        = number
}

variable "subnet_id" {
  description = "Subnet the node pool attaches to."
  type        = string
}

variable "tags" {
  description = "Resource tags."
  type        = map(string)
  default     = {}
}
