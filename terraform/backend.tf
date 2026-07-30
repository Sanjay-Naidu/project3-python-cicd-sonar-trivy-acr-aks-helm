# =============================================================================
# Project : Project 3 - Python App CI/CD on Azure AKS
# Author  : Sanjay Naidu
# File    : terraform/backend.tf - remote state in Azure Storage
# =============================================================================
# WHY remote state: local state files get lost, leak secrets, and cannot be
# shared with CI. Azure Storage gives durable, locked (lease-based) state for
# pennies per month.
#
# WHY the block is empty: the storage account name is unique per person, so
# concrete values live in backend.hcl (bootstrap steps in docs/SETUP.md):
#
#   terraform init -backend-config=backend.hcl
#
# NOTE (chicken-and-egg): the state storage account itself is created once
# with the Azure CLI, NOT by this Terraform - Terraform cannot store its
# state in a storage account it has not created yet.

terraform {
  backend "azurerm" {}
}
