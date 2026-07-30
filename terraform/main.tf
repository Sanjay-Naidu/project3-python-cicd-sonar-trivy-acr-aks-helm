# =============================================================================
# Project : Project 3 - Python App CI/CD on Azure AKS
# Author  : Sanjay Naidu
# File    : terraform/main.tf - root composition: RG + network + ACR + AKS
# =============================================================================
# WHY modules: each concern (network / registry / cluster) is isolated,
# reusable and independently reviewable - the same layout scales to real
# multi-environment estates by calling the modules with different inputs.

resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

module "network" {
  source = "./modules/network"

  name_prefix         = "project3"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  vnet_address_space  = var.vnet_address_space
  aks_subnet_cidr     = var.aks_subnet_cidr
  tags                = var.tags
}

module "acr" {
  source = "./modules/acr"

  name                = var.acr_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tags                = var.tags
}

module "aks" {
  source = "./modules/aks"

  name                = var.aks_cluster_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  kubernetes_version  = var.kubernetes_version
  node_vm_size        = var.node_vm_size
  min_node_count      = var.min_node_count
  max_node_count      = var.max_node_count
  subnet_id           = module.network.aks_subnet_id
  tags                = var.tags
}

# Grant the cluster's kubelet identity pull access on ACR.
# WHY: this replaces registry passwords/imagePullSecrets entirely - nodes
# authenticate to ACR with their managed identity.
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                            = module.acr.id
  role_definition_name             = "AcrPull"
  principal_id                     = module.aks.kubelet_object_id
  skip_service_principal_aad_check = true
}

# Cost guardrail: email alerts at 50% / 80% actual and 100% forecasted spend.
# WHY: on a free trial, a forgotten cluster is the #1 way to burn the credit.
resource "azurerm_consumption_budget_resource_group" "this" {
  name              = "budget-${azurerm_resource_group.this.name}"
  resource_group_id = azurerm_resource_group.this.id

  amount     = var.budget_amount
  time_grain = "Monthly"

  time_period {
    start_date = var.budget_start_date
  }

  notification {
    enabled        = true
    threshold      = 50.0
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = [var.budget_alert_email]
  }

  notification {
    enabled        = true
    threshold      = 80.0
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = [var.budget_alert_email]
  }

  notification {
    enabled        = true
    threshold      = 100.0
    operator       = "GreaterThan"
    threshold_type = "Forecasted"
    contact_emails = [var.budget_alert_email]
  }
}
