# =============================================================================
# Project : Project 3 - Python App CI/CD on Azure AKS
# Author  : Sanjay Naidu
# File    : terraform/modules/aks/outputs.tf
# =============================================================================

output "name" {
  description = "Cluster name."
  value       = azurerm_kubernetes_cluster.this.name
}

output "id" {
  description = "Cluster resource id."
  value       = azurerm_kubernetes_cluster.this.id
}

output "kubelet_object_id" {
  description = "Kubelet managed identity object id (granted AcrPull on the registry)."
  value       = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL for future workload identity federation."
  value       = azurerm_kubernetes_cluster.this.oidc_issuer_url
}

output "node_resource_group" {
  description = "Auto-created RG holding node VMs, load balancer and public IP."
  value       = azurerm_kubernetes_cluster.this.node_resource_group
}
