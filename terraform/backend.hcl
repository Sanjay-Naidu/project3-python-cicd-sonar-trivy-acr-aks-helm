# =============================================================================
# Project : Project 3 - Python App CI/CD on Azure AKS
# Author  : Sanjay Naidu
# File    : terraform/backend.hcl - backend values (no secrets, safe to commit)
# =============================================================================
# Created manually once via Azure CLI - see docs/SETUP.md Phase 1.
# Storage account names are GLOBALLY unique: change it to your own.

resource_group_name  = "rg-project3-tfstate"
storage_account_name = "stp3tfstatesanjay01"
container_name       = "tfstate"
key                  = "project3.terraform.tfstate"

# Use Entra ID (RBAC) auth for the state blob instead of storage account keys.
# Requires "Storage Blob Data Contributor" on the storage account for both
# your user and the GitHub OIDC service principal (commands in docs/SETUP.md).
use_azuread_auth = true
