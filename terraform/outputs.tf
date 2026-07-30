# =============================================================================
# Project : Project 3 - Python App CI/CD on Azure AKS
# Author  : Sanjay Naidu
# File    : terraform/outputs.tf - values consumed by pipelines and humans
# =============================================================================
# After `terraform apply`, copy these into the GitHub repository variables
# (ACR_NAME, AKS_CLUSTER_NAME, AKS_RESOURCE_GROUP) - see docs/SETUP.md Phase 5.

output "resource_group_name" {
  description = "Workload resource group."
  value       = azurerm_resource_group.this.name
}

output "acr_name" {
  description = "Container registry name (GitHub variable: ACR_NAME)."
  value       = module.acr.name
}

output "acr_login_server" {
  description = "Registry login server, used as the image repository prefix."
  value       = module.acr.login_server
}

output "aks_cluster_name" {
  description = "AKS cluster name (GitHub variable: AKS_CLUSTER_NAME)."
  value       = module.aks.name
}

output "aks_oidc_issuer_url" {
  description = "Cluster OIDC issuer - needed if you later add workload identity for pods."
  value       = module.aks.oidc_issuer_url
}

output "get_credentials_command" {
  description = "Convenience: command to fetch kubeconfig."
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.this.name} --name ${module.aks.name}"
}
