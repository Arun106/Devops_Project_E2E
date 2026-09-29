output "resource_group" { value = azurerm_resource_group.platform.name }
output "aks_name" { value = azurerm_kubernetes_cluster.platform.name }
output "acr_name" { value = azurerm_container_registry.platform.name }
output "acr_login_server" { value = azurerm_container_registry.platform.login_server }
output "key_vault_name" { value = azurerm_key_vault.platform.name }
