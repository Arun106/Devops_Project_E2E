variable "prefix" {
  description = "Name prefix for Azure resources."
  type        = string
  default     = "devops-e2e"
}

variable "location" {
  description = "Azure region override. Leave null to use the selected deployment option."
  type        = string
  default     = null

  validation {
    condition = var.location == null || contains([
      "eastus",
      "eastus2",
      "eastasia",
      "centralus",
      "westus",
      "westus2",
      "westus3"
    ], var.location)
    error_message = "location must be null or one of: eastus, eastus2, eastasia, centralus, westus, westus2, westus3."
  }
}

variable "admin_username" {
  description = "Linux VM administrator username."
  type        = string
  default     = "azureuser"
}

variable "vm_size" {
  description = "Azure VM size override. Leave null to use the first recommended size for the selected location."
  type        = string
  default     = null
}

variable "deployment_option_index" {
  description = "Index from deployment_options to use when location or vm_size is not overridden."
  type        = number
  default     = 0
}

variable "deployment_options" {
  description = "Ordered location and VM size combinations to try when Azure capacity or quota blocks a run."
  type = list(object({
    location = string
    vm_size  = string
  }))
  default = [
    {
      location = "eastasia"
      vm_size  = "Standard_D2s_v3"
    },
    {
      location = "eastasia"
      vm_size  = "Standard_B2s"
    },
    {
      location = "westus"
      vm_size  = "Standard_D2s_v3"
    },
    {
      location = "westus2"
      vm_size  = "Standard_B2s"
    },
    {
      location = "eastus2"
      vm_size  = "Standard_B2s"
    },
    {
      location = "centralus"
      vm_size  = "Standard_D2s_v3"
    },
    {
      location = "westus3"
      vm_size  = "Standard_B2s"
    },
    {
      location = "eastus"
      vm_size  = "Standard_D2s_v3"
    }
  ]
}

variable "resource_suffix" {
  description = "Optional suffix for Azure resource names. Set a new value to avoid collisions with failed partial deployments."
  type        = string
  default     = "run04"
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key used for VM login."
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "ssh_public_key" {
  description = "SSH public key content used for VM login. Set this in Terraform Cloud for remote runs."
  type        = string
  default     = null
  sensitive   = true
}

resource "random_string" "suffix" {
  length  = 6
  lower   = true
  numeric = true
  special = false
  upper   = false
}

locals {
  selected_deployment = var.deployment_options[var.deployment_option_index]
  selected_location   = var.location != null ? var.location : local.selected_deployment.location
  selected_vm_size    = var.vm_size != null ? var.vm_size : local.selected_deployment.vm_size
  resource_suffix     = var.resource_suffix != null ? var.resource_suffix : random_string.suffix.result
  name                = "${var.prefix}-${local.resource_suffix}"
  storage_name        = substr(replace(lower("${var.prefix}${local.resource_suffix}"), "/[^a-z0-9]/", ""), 0, 24)
}

resource "azurerm_resource_group" "main" {
  name     = "${local.name}-rg"
  location = local.selected_location
}

resource "azurerm_virtual_network" "main" {
  name                = "${local.name}-vnet"
  address_space       = ["10.10.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "main" {
  name                 = "${local.name}-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.10.1.0/24"]
}

resource "azurerm_network_security_group" "main" {
  name                = "${local.name}-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_network_security_rule" "ssh" {
  name                        = "Allow-SSH"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.main.name
}

resource "azurerm_network_security_rule" "tomcat" {
  name                        = "Allow-Tomcat"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "8080"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.main.name
}

resource "azurerm_public_ip" "main" {
  name                = "${local.name}-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "main" {
  name                = "${local.name}-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }
}

resource "azurerm_network_interface_security_group_association" "main" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}

resource "azurerm_linux_virtual_machine" "main" {
  name                = "${local.name}-vm"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  size                = local.selected_vm_size
  admin_username      = var.admin_username
  network_interface_ids = [
    azurerm_network_interface.main.id
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key != null ? var.ssh_public_key : file(pathexpand(var.ssh_public_key_path))
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

resource "azurerm_storage_account" "main" {
  name                     = local.storage_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "main" {
  name                  = "artifacts"
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = "private"
}

output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "vm_public_ip" {
  value = azurerm_public_ip.main.ip_address
}

output "selected_vm_size" {
  value = local.selected_vm_size
}

output "selected_location" {
  value = local.selected_location
}

output "selected_deployment" {
  value = {
    index    = var.deployment_option_index
    location = local.selected_location
    vm_size  = local.selected_vm_size
  }
}

output "deployment_options" {
  value = var.deployment_options
}

output "resource_suffix" {
  value = local.resource_suffix
}

output "storage_account_name" {
  value = azurerm_storage_account.main.name
}
