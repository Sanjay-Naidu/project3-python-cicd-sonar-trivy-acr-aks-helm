# =============================================================================
# Project : Project 3 - Python App CI/CD on Azure AKS
# Author  : Sanjay Naidu
# File    : terraform/modules/aks/main.tf - AKS cluster (cost-optimised, prod-shaped)
# =============================================================================
# Key decisions (each one is an interview talking point):
#   sku_tier Free        : $0 control plane; Standard ($73/mo) only adds the
#                          uptime SLA - unnecessary for a demo.
#   B2s + autoscaler 1-2 : cheapest viable nodes; scales to 2 under load and
#                          back to 1 when idle. 2 x B2s fits the free-trial
#                          4 vCPU quota exactly.
#   CNI Overlay          : pods get IPs from an overlay CIDR, not the subnet -
#                          modern AKS default, no subnet IP exhaustion.
#   OIDC + workload identity : enabled (free) so pods can later authenticate
#                          to Azure services without secrets.
#   web_app_routing      : Azure's MANAGED nginx ingress controller - no
#                          manual ingress-nginx install/upgrade to maintain.
#   No Log Analytics     : deliberate cost trade-off (~$2.30/GB ingested);
#                          `kubectl logs` + Prometheus /metrics cover a demo.

resource "azurerm_kubernetes_cluster" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.name

  sku_tier           = "Free"
  kubernetes_version = var.kubernetes_version

  # Auto-apply security patches within the same minor version.
  automatic_upgrade_channel = "patch"

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  role_based_access_control_enabled = true

  default_node_pool {
    name                 = "system"
    vm_size              = var.node_vm_size
    auto_scaling_enabled = true
    min_count            = var.min_node_count
    max_count            = var.max_node_count
    node_count           = var.min_node_count
    os_disk_size_gb      = 32 # default 128 GiB is oversized + costs more
    vnet_subnet_id       = var.subnet_id

    # Allows in-place VM size changes without destroying the cluster.
    temporary_name_for_rotation = "systemtmp"

    upgrade_settings {
      max_surge = "10%"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    pod_cidr            = "192.168.0.0/16"
    service_cidr        = "172.16.0.0/16" # must not overlap the VNet (10.0.0.0/16)
    dns_service_ip      = "172.16.0.10"
    load_balancer_sku   = "standard"
    outbound_type       = "loadBalancer"
  }

  # Managed nginx ingress (app routing add-on). Empty dns_zone_ids = no Azure
  # DNS zone; we reach the app via the public IP (or nip.io) to avoid buying
  # a domain for a demo.
  web_app_routing {
    dns_zone_ids = []
  }

  lifecycle {
    # The autoscaler owns node_count at runtime; without this, every plan
    # would try to reset the count Terraform last saw.
    ignore_changes = [default_node_pool[0].node_count]
  }

  tags = var.tags
}
