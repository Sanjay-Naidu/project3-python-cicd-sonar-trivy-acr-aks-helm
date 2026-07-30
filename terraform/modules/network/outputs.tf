# =============================================================================
# Project : Project 3 - Python App CI/CD on Azure AKS
# Author  : Sanjay Naidu
# File    : terraform/modules/network/outputs.tf
# =============================================================================

output "vnet_id" {
  description = "VNet resource id."
  value       = azurerm_virtual_network.this.id
}

output "aks_subnet_id" {
  description = "Subnet id the AKS node pool attaches to."
  value       = azurerm_subnet.aks.id
}
