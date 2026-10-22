# =============================================================================
# Project : Project 3 - Python App CI/CD on Azure AKS
# Author  : Sanjay Naidu
# File    : terraform/versions.tf - version pinning for reproducible infra
# =============================================================================
# WHY pin versions: an unpinned provider can introduce breaking changes on the
# next `terraform init`. Pessimistic (~>) pins allow patch/minor updates while
# blocking surprise major upgrades.

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.10"
    }
  }
}
