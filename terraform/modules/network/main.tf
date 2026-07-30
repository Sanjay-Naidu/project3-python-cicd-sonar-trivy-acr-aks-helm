# =============================================================================
# Project : Project 3 - Python App CI/CD on Azure AKS
# Author  : Sanjay Naidu
# File    : terraform/modules/network/main.tf - VNet + AKS subnet
# =============================================================================
# WHY a custom VNet (instead of the AKS-managed default): you control the CIDR
# plan, can add subnets later (app gateway, private endpoints, jumpbox) and it
# mirrors how real estates are built. Costs nothing - VNets are free.

resource "azurerm_virtual_network" "this" {
  name                = "vnet-${var.name_prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = [var.vnet_address_space]
  tags                = var.tags
}

resource "azurerm_subnet" "aks" {
  name                 = "snet-${var.name_prefix}-aks"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.aks_subnet_cidr]
}
