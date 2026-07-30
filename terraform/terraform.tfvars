# =============================================================================
# Project : Project 3 - Python App CI/CD on Azure AKS
# Author  : Sanjay Naidu
# File    : terraform/terraform.tfvars - environment values (no secrets)
# =============================================================================
# Only two values REQUIRE editing before first apply: acr_name (globally
# unique) and budget_alert_email. Everything else has sensible cheap defaults.

location            = "eastus"
resource_group_name = "rg-project3-aks"

acr_name         = "acrproject3sanjay01"
aks_cluster_name = "aks-project3"

node_vm_size   = "Standard_B2s"
min_node_count = 1
max_node_count = 2

budget_amount      = 80
budget_alert_email = "raghumanda24@gmail.com"
budget_start_date  = "2026-08-01T00:00:00Z"
