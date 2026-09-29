resource "random_string" "suffix" {
  length  = 6
  lower   = true
  upper   = false
  numeric = true
  special = false
}

locals {
  stem    = "${var.prefix}-${random_string.suffix.result}"
  compact = substr(replace(var.prefix, "-", ""), 0, 12)
}

resource "azurerm_resource_group" "platform" {
  name     = "${local.stem}-rg"
  location = var.location
}

resource "azurerm_virtual_network" "platform" {
  name                = "${local.stem}-vnet"
  resource_group_name = azurerm_resource_group.platform.name
  location            = azurerm_resource_group.platform.location
  address_space       = ["10.40.0.0/16"]
}

resource "azurerm_subnet" "aks" {
  name                 = "aks-nodes"
  resource_group_name  = azurerm_resource_group.platform.name
  virtual_network_name = azurerm_virtual_network.platform.name
  address_prefixes     = ["10.40.1.0/24"]
}

resource "azurerm_container_registry" "platform" {
  name                = "${local.compact}${random_string.suffix.result}acr"
  resource_group_name = azurerm_resource_group.platform.name
  location            = azurerm_resource_group.platform.location
  sku                 = "Basic"
  admin_enabled       = false
}

resource "azurerm_key_vault" "platform" {
  name                      = "${substr(local.compact, 0, 12)}-${random_string.suffix.result}-kv"
  resource_group_name       = azurerm_resource_group.platform.name
  location                  = azurerm_resource_group.platform.location
  tenant_id                 = data.azurerm_client_config.current.tenant_id
  sku_name                  = "standard"
  enable_rbac_authorization = true
  purge_protection_enabled  = false # lab only; revisit before production
}

data "azurerm_client_config" "current" {}

resource "azurerm_log_analytics_workspace" "platform" {
  name                = "${local.stem}-logs"
  resource_group_name = azurerm_resource_group.platform.name
  location            = azurerm_resource_group.platform.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_user_assigned_identity" "aks_control_plane" {
  name                = "${local.stem}-identity"
  resource_group_name = azurerm_resource_group.platform.name
  location            = azurerm_resource_group.platform.location
}

resource "azurerm_role_assignment" "aks_network" {
  scope                = azurerm_subnet.aks.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks_control_plane.principal_id
}

resource "azurerm_kubernetes_cluster" "platform" {
  name                      = "${local.stem}-aks"
  resource_group_name       = azurerm_resource_group.platform.name
  location                  = azurerm_resource_group.platform.location
  dns_prefix                = local.stem
  sku_tier                  = "Free"
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  default_node_pool {
    name                        = "system"
    vm_size                     = var.node_vm_size
    vnet_subnet_id              = azurerm_subnet.aks.id
    auto_scaling_enabled        = true
    min_count                   = 1
    max_count                   = 2
    temporary_name_for_rotation = "tempnode"
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks_control_plane.id]
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    pod_cidr            = "10.244.0.0/16"
    service_cidr        = "10.2.0.0/16"
    dns_service_ip      = "10.2.0.10"
  }

  oms_agent { log_analytics_workspace_id = azurerm_log_analytics_workspace.platform.id }

  depends_on = [azurerm_role_assignment.aks_network]
}

resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.platform.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.platform.kubelet_identity[0].object_id
}
