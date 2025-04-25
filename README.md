## Azure DevOps & Terraform Integration for Web App and VM Deployment
## Project Overview
```
This project automates the deployment of a secure, monitored infrastructure on Microsoft Azure using **Terraform** and **Azure DevOps**, designed for the Central India region.
It includes:
- A Web Application with Private Endpoint
- A Virtual Machine (Ubuntu 22.04 LTS)
- Diagnostic Settings, Monitoring, Alerts
- Security and Deletion Locks
```
## Region
All resources are deployed in the `Central India` region.
## providers.tf
```
provider "azurerm" {
  features {}
}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
  }
  required_version = ">= 1.3.0"
}
```
## main.tf
```
resource "azurerm_resource_group" "network_rg" {
  name     = "rg-dev-network-01"
  location = "Central India"
}

resource "azurerm_resource_group" "app_rg" {
  name     = "rg-dev-application-01"
  location = "Central India"
}

// Create Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-dev-01"
  address_space       = ["10.1.0.0/20"]
  location            = azurerm_resource_group.network_rg.location
  resource_group_name = azurerm_resource_group.network_rg.name
}

// Subnets
resource "azurerm_subnet" "snet_web" {
  name                 = "snet-dev-web1"
  resource_group_name  = azurerm_resource_group.network_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.0.0/22"]
}

resource "azurerm_network_security_group" "web_nsg" {
  name                = "web-nsg1"
  location            = "Central India"
  resource_group_name = azurerm_resource_group.network_rg.name

}

resource "azurerm_subnet" "snet_app" {
  name                 = "snet-dev-app1"
  resource_group_name  = azurerm_resource_group.network_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.4.0/22"]
}

resource "azurerm_network_security_group" "app_nsg" {
  name                = "app-nsg1"
  location            = "Central India"
  resource_group_name = azurerm_resource_group.network_rg.name
}

resource "azurerm_subnet" "snet_data" {
  name                 = "snet-dev-data1"
  resource_group_name  = azurerm_resource_group.network_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.8.0/22"]
}

resource "azurerm_network_security_group" "data_nsg" {
  name                = "data-nsg1"
  location            = "Central India"
  resource_group_name = azurerm_resource_group.network_rg.name
}

resource "azurerm_subnet" "snet_pep" {
  name                 = "snet-dev-pep1"
  resource_group_name  = azurerm_resource_group.network_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.12.0/22"]
  
}

resource "azurerm_network_security_group" "pep_nsg" {
  name                = "pep-nsg1"
  location            = "Central India"
  resource_group_name = azurerm_resource_group.network_rg.name
}

resource "azurerm_public_ip" "vm_ip" {
  name                = "pip-dev-vm1"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
  allocation_method   = "Dynamic"
  sku                 = "Basic"
}
 
resource "azurerm_network_interface" "dev_vm_nic" {
  name                = "nic-dev-vm1"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
 
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_ip.id
  }
}
 
resource "azurerm_linux_virtual_machine" "dev_vm" {
  name                            = "dev-vm-1"
  location                        = azurerm_resource_group.network.location
  resource_group_name             = azurerm_resource_group.network.name
  network_interface_ids           = [azurerm_network_interface.dev_vm_nic.id]
  size                            = "Standard_B1s"
  admin_username                  = "azureuser"
  disable_password_authentication = true
 
  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")  # Point to your public key
  }
 
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    name                 = "dev-os-disk"
  }
 
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
 
  custom_data = filebase64("docker-install.sh")
}
```

