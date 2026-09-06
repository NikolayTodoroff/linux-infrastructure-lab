output "gateway_public_ip" {
  value = module.vm.gateway_public_ip
}

output "backend_public_ip" {
  value = module.vm.backend_public_ip
}

output "ssh_gateway_command" {
  description = "SSH command for gateway VM"
  value       = "ssh ${var.admin_username}@${module.vm.gateway_public_ip}"
}

output "ssh_backend_command" {
  description = "SSH command for backend VM"
  value       = "ssh ${var.admin_username}@${module.vm.backend_public_ip}"
}

output "vm_start_command" {
  description = "Start both VMs"
  value = "az vm start -g ${azurerm_resource_group.main.name} -n ${module.vm.gateway_name} --no-wait && az vm start -g ${azurerm_resource_group.main.name} -n ${module.vm.backend_name} --no-wait"
}

output "vm_deallocate_command" {
  description = "Deallocate both VMs"
  value       = "az vm deallocate -g ${azurerm_resource_group.main.name} -n ${module.vm.gateway_name} --no-wait && az vm deallocate -g ${azurerm_resource_group.main.name} -n ${module.vm.backend_name} --no-wait"
}
