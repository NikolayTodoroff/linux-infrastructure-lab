terraform {
    backend "azurerm" {
    resource_group_name  = "rg-tfstate-westeurope"
    storage_account_name = "stlfcslabwesteurope"
    container_name       = "tfstate"
    key                  = "linux-infra-lab.tfstate"
  }
}
