resource "azurerm_public_ip" "gateway" {
  name                = "pip-gateway"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_public_ip" "backend" {
  name                = "pip-backend"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "gateway" {
  name                  = "nic-gateway"
  location              = var.location
  resource_group_name   = var.resource_group_name
  ip_forwarding_enabled = true

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.gw_subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.10"
    public_ip_address_id          = azurerm_public_ip.gateway.id
  }
}

resource "azurerm_network_interface" "backend" {
  name                = "nic-backend"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.backend_subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.2.11"
    public_ip_address_id          = azurerm_public_ip.backend.id
  }
}

resource "azurerm_linux_virtual_machine" "gateway" {
  name                            = "vm-gateway"
  location                        = var.location
  resource_group_name             = var.resource_group_name
  size                            = var.vm_size
  admin_username                  = var.admin_username
  network_interface_ids           = [azurerm_network_interface.gateway.id]
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}

resource "azurerm_linux_virtual_machine" "backend" {
  name                            = "vm-backend"
  location                        = var.location
  resource_group_name             = var.resource_group_name
  size                            = var.vm_size
  admin_username                  = var.admin_username
  network_interface_ids           = [azurerm_network_interface.backend.id]
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}

resource "azurerm_managed_disk" "lvm" {
  count                = 3
  name                 = "disk-backend-lvm-${count.index}"
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 5
}

resource "azurerm_managed_disk" "nfs" {
  name                 = "disk-backend-nfs"
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 10
}

resource "azurerm_virtual_machine_data_disk_attachment" "lvm" {
  count              = 3
  managed_disk_id    = azurerm_managed_disk.lvm[count.index].id
  virtual_machine_id = azurerm_linux_virtual_machine.backend.id
  lun                = count.index
  caching            = "None"
}

resource "azurerm_virtual_machine_data_disk_attachment" "nfs" {
  managed_disk_id    = azurerm_managed_disk.nfs.id
  virtual_machine_id = azurerm_linux_virtual_machine.backend.id
  lun                = 3
  caching            = "None"
}
