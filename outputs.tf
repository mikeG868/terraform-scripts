output "resource_group_id" {
  value = azurerm_resource_group.rg.id
}

output "public_ip" {
  value = azurerm_linux_virtual_machine.vm.public_ip_address
}
