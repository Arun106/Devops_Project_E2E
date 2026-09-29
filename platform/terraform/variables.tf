variable "subscription_id" {
  type = string
}

variable "location" {
  type    = string
  default = "germanywestcentral"
}

variable "prefix" {
  type    = string
  default = "arun-platform"
}

variable "node_vm_size" {
  type    = string
  default = "Standard_D2s_v5"
}
