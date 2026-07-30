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

  # virtual_network_name is a plain string (this provider version has no
  # virtual_network_id argument), so its VALUE never changes even when the
  # VNet is destroyed and recreated with the same name (e.g. a region move
  # forces RG/VNet replacement, but "vnet-project3" is still "vnet-project3").
  # Terraform then sees no attribute diff and leaves the subnet alone, even
  # though the real VNet underneath it is gone - hit exactly this once.
  # replace_triggered_by keys off the VNet's *id* instead of its name, so a
  # region move correctly forces the subnet to be replaced too.
  lifecycle {
    replace_triggered_by = [azurerm_virtual_network.this.id]
  }
}
