variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "vnet_address_space" {
  type    = list(string)
  default = ["10.0.0.0/16"]
}

variable "gw_subnet_address_prefixes" {
  type = list(string)
}

variable "backend_subnet_address_prefixes" {
  type = list(string)
}

variable "admin_ip" {
  description = "Public IP allowed for SSH access"
  type        = string
}
