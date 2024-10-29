provider "azurerm" {
  features {}
}

variable "location" {
  default = "East US"
}

resource "azurerm_resource_group" "rg-koren" {
  name     = "koren-resources"
  location = var.location
}

resource "azurerm_virtual_network" "vnet-koren" {
  name                = "koren-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg-koren.name
}

resource "azurerm_subnet" "subnet-koren" {
  name                 = "koren-subnet"
  resource_group_name  = azurerm_resource_group.rg-koren.name
  virtual_network_name = azurerm_virtual_network.vnet-koren.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "pip-koren" {
  name                = "koren-pip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg-koren.name
  allocation_method   = "Dynamic"  # Dynamic IP allocation for Basic SKU
  sku = "Basic"  
}

# Use Basic SKU (Stock Keeping Unit - azure tiers) for dynamic IP

resource "azurerm_network_interface" "nic-koren" {
  name                = "koren-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg-koren.name

  ip_configuration {
    name                          = "koren-ipconfig"
    subnet_id                     = azurerm_subnet.subnet-koren.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip-koren.id
  }
}

variable "vm_size" {
  default = "Standard_B1ms"
}

variable "admin_username" {
  default = "adminuser-koren"
}

variable "admin_password" {
  default = "Password123!"
}


resource "azurerm_linux_virtual_machine" "vm-koren" {
  name                  = "koren-vm"
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg-koren.name
  network_interface_ids = [azurerm_network_interface.nic-koren.id]
  size                  = var.vm_size

  os_disk {
    name              = "koren-os-disk"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_username = var.admin_username
  admin_password = var.admin_password

  disable_password_authentication = false

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name = "koren-vm"
}

output "vm_public_ip" {
  value = azurerm_public_ip.pip-koren.ip_address
  description = "Public IP address of the VM"
}




