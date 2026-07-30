# =============================================================================
# Project : Project 3 - Python App CI/CD on Azure AKS
# Author  : Sanjay Naidu
# File    : terraform/modules/acr/outputs.tf
# =============================================================================

output "id" {
  description = "Registry resource id (used for the AcrPull role assignment)."
  value       = azurerm_container_registry.this.id
}

output "name" {
  description = "Registry name."
  value       = azurerm_container_registry.this.name
}

output "login_server" {
  description = "Registry login server (e.g. acrproject3xyz.azurecr.io)."
  value       = azurerm_container_registry.this.login_server
}
