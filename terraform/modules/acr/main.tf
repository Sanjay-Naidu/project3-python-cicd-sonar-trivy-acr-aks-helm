# =============================================================================
# Project : Project 3 - Python App CI/CD on Azure AKS
# Author  : Sanjay Naidu
# File    : terraform/modules/acr/main.tf - Azure Container Registry
# =============================================================================
# WHY Basic SKU : ~USD 5/month, 10 GiB storage - plenty for a demo project.
#                 (Standard/Premium add geo-replication, private link, more
#                 storage - not worth the cost here; easy upgrade later.)
# WHY admin_enabled = false : the admin account is a shared username/password
#                 - an anti-pattern. CI pushes via OIDC (Entra ID) and AKS
#                 pulls via its managed identity (AcrPull role), so no
#                 registry passwords exist anywhere in this project.

resource "azurerm_container_registry" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  admin_enabled       = false
  tags                = var.tags
}
