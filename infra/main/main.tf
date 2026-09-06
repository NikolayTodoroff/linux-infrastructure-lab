resource "azurerm_resource_group" "main" {
  name     = "rg-lfcs-lab"
  location = var.location
}

module "networking" {
  source                          = "../modules/networking"
  location                        = var.location
  resource_group_name             = azurerm_resource_group.main.name
  gw_subnet_address_prefixes     = ["10.0.1.0/24"]
  backend_subnet_address_prefixes = ["10.0.2.0/24"]
  admin_ip                        = var.admin_ip
}

module "vm" {
  source              = "../modules/vm"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  gw_subnet_id        = module.networking.gw_subnet_id
  backend_subnet_id   = module.networking.backend_subnet_id
  admin_username      = var.admin_username
  vm_size             = "Standard_B2s_v2"
}