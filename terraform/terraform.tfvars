# =============================================================================
# Project : Project 3 - Python App CI/CD on Azure AKS
# Author  : Sanjay Naidu
# File    : terraform/terraform.tfvars - environment values (no secrets)
# =============================================================================
# Only two values REQUIRE editing before first apply: acr_name (globally
# unique) and budget_alert_email. Everything else has sensible cheap defaults.

# eastus rejected AKS cluster creation with "AKSCapacityHeavyUsage" (a
# transient regional capacity throttle, not a quota problem) - switched to
# westus2, a large/well-provisioned region less prone to this.
location            = "westus2"
resource_group_name = "rg-project3-aks"

acr_name         = "acrproject3sanjay01"
aks_cluster_name = "aks-project3"

# Standard_B2s (burstable) is NOT allowed on this subscription's quota in
# eastus - Azure rejected it with a 400 listing only D/E/F-v7 families as
# available. Standard_D2as_v7 is the cheapest of those (~$66/mo/node vs the
# ~$30/mo B2s would have cost) - verified via the Azure Retail Prices API.
node_vm_size   = "Standard_D2as_v7"
min_node_count = 1
max_node_count = 2

budget_amount      = 80
budget_alert_email = "raghumanda24@gmail.com"
budget_start_date  = "2026-08-01T00:00:00Z"
