variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "gw_subnet_id" {
  type = string
}

variable "backend_subnet_id" {
  type = string
}

variable "vm_size" {
  type    = string
  default = "Standard_B2s_v2"
}

variable "admin_username" {
  type = string
}

variable "ssh_public_key_path" {
  type    = string
  default = "~/.ssh/lfcs-lab.pub"
}