# =============================================================================
# Project : Project 3 - Python App CI/CD on Azure AKS
# Author  : Sanjay Naidu
# File    : terraform/providers.tf - azurerm provider configuration
# =============================================================================
# Authentication is intentionally NOT hardcoded here:
#   - locally  : uses your `az login` session; set the subscription with
#                $env:ARM_SUBSCRIPTION_ID = "<subscription-id>"
#   - in CI    : GitHub Actions passes ARM_CLIENT_ID / ARM_TENANT_ID /
#                ARM_SUBSCRIPTION_ID / ARM_USE_OIDC=true (federated OIDC,
#                zero stored passwords - see .github/workflows/terraform.yml)

provider "azurerm" {
  features {
    resource_group {
      # Allow `terraform destroy` to clean up even if Azure leaves stray
      # hidden resources behind (important for tearing down to save cost).
      prevent_deletion_if_contains_resources = false
    }
  }
}
