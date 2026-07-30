# =============================================================================
# Project : Project 3 - Python App CI/CD on Azure AKS
# Author  : Sanjay Naidu
# File    : terraform/variables.tf - input variables (values in terraform.tfvars)
# =============================================================================

variable "location" {
  description = "Azure region. eastus is usually cheapest/most available; if the free trial rejects it, try westus2, centralindia or southeastasia."
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "Resource group holding all workload resources (AKS, ACR, VNet)."
  type        = string
  default     = "rg-project3-aks"
}

variable "acr_name" {
  description = "Azure Container Registry name - GLOBALLY unique, 5-50 alphanumeric chars, no hyphens."
  type        = string
}

variable "aks_cluster_name" {
  description = "AKS cluster name."
  type        = string
  default     = "aks-project3"
}

variable "kubernetes_version" {
  description = "Kubernetes version. null = AKS default (a supported stable version), which avoids chasing patch releases."
  type        = string
  default     = null
}

variable "node_vm_size" {
  description = <<-EOT
    Node VM size. Standard_D2as_v7 (2 vCPU / 8 GiB, AMD) - the cheapest SKU
    available on this subscription's quota (~USD 66/month per node at the
    time this was checked via the Azure Retail Prices API). Burstable
    B-series (e.g. Standard_B2s, ~USD 30/month) is the usual go-to for a
    cost-optimised demo but is NOT allowed on every subscription/region
    combination - some free-trial subscriptions only have quota for modern
    D/E/F-v7 families. If you hit "VM size ... is not allowed in your
    subscription", the CreateOrUpdate error lists every SKU your
    subscription CAN use in that region - re-check the Azure Retail Prices
    API (https://prices.azure.com/api/retail/prices) for each candidate
    before picking one, since price does not correlate with SKU family the
    way you'd expect (D-series outpriced F-series here).
  EOT
  type        = string
  default     = "Standard_D2as_v7"
}

variable "min_node_count" {
  description = "Cluster autoscaler minimum. 1 keeps cost at a single VM when idle."
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Cluster autoscaler maximum. 2 stays inside the free-trial 4 vCPU quota (2 x B2s = 4 vCPU)."
  type        = number
  default     = 2
}

variable "vnet_address_space" {
  description = "VNet CIDR."
  type        = string
  default     = "10.0.0.0/16"
}

variable "aks_subnet_cidr" {
  description = "AKS node subnet CIDR. /24 is plenty for 2 nodes with CNI Overlay (pods use a separate overlay CIDR)."
  type        = string
  default     = "10.0.1.0/24"
}

variable "budget_amount" {
  description = "Monthly budget (USD) for the workload resource group; alert emails fire at 50/80/100%."
  type        = number
  default     = 80
}

variable "budget_alert_email" {
  description = "Email address that receives budget alerts."
  type        = string
}

variable "budget_start_date" {
  description = "Budget period start - must be the first day of a month, in RFC3339."
  type        = string
  default     = "2026-08-01T00:00:00Z"
}

variable "tags" {
  description = "Tags applied to every resource - makes cost analysis by project trivial."
  type        = map(string)
  default = {
    project    = "project3-python-cicd-aks"
    owner      = "sanjay.naidu"
    managed_by = "terraform"
  }
}
