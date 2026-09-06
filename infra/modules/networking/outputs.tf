output "gw_subnet_id" {
  value = azurerm_subnet.gateway.id
}

output "backend_subnet_id" {
  value = azurerm_subnet.backend.id
}

output "gw_nsg_id" {
  value = azurerm_network_security_group.gateway.id
}

output "backend_nsg_id" {
  value = azurerm_network_security_group.backend.id
}
