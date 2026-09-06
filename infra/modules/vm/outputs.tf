output "gateway_name" {
  value = azurerm_linux_virtual_machine.gateway.name
}

output "backend_name" {
  value = azurerm_linux_virtual_machine.backend.name
}

output "gateway_public_ip" {
  value = azurerm_public_ip.gateway.ip_address
}

output "backend_public_ip" {
  value = azurerm_public_ip.backend.ip_address
}

output "gateway_vm_id" {
  value = azurerm_linux_virtual_machine.gateway.id
}

output "backend_vm_id" {
  value = azurerm_linux_virtual_machine.backend.id
}

output "admin_username" {
  value = var.admin_username
}
