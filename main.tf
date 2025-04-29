# Resource Group for Network
resource "azurerm_resource_group" "network" {
  name     = "rg-dev-network-01"
  location = "Central India"
}

# Virtual Network (vnet)
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-dev-01"
  address_space       = ["10.1.0.0/20"]
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
}

# Subnet for Web
resource "azurerm_subnet" "web" {
  name                 = "snet-dev-web-01"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.0.0/22"]
}

# NSG for Web Subnet
resource "azurerm_network_security_group" "web_nsg" {
  name                = "nsg-snet-dev-web-01"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
}

# Subnet for App
resource "azurerm_subnet" "app" {
  name                 = "snet-dev-app-01"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.4.0/22"]
}

# NSG for App Subnet
resource "azurerm_network_security_group" "app_nsg" {
  name                = "nsg-snet-dev-app-01"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
}

# Subnet for Data
resource "azurerm_subnet" "data" {
  name                 = "snet-dev-data-01"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.8.0/22"]
}

# NSG for Data Subnet
resource "azurerm_network_security_group" "data_nsg" {
  name                = "nsg-snet-dev-data-01"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
}

# Subnet for PEP (Private Endpoint)
resource "azurerm_subnet" "pep" {
  name                 = "snet-dev-pep-01"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.12.0/22"]
}

# NSG for PEP Subnet
resource "azurerm_network_security_group" "pep_nsg" {
  name                = "nsg-snet-dev-pep-01"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
}

# Resource Group for Application
resource "azurerm_resource_group" "rg" {
  name     = "rg-dev-application-02"
  location = "Central India"
}

# Public IP for VM
resource "azurerm_public_ip" "vm_ip" {
  name                = "pip-dev-vm-01"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
  sku                 = "Basic"
}

# Network Interface for VM
resource "azurerm_network_interface" "dev_vm_nic" {
  name                = "nic-dev-vm-01"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_ip.id
  }
}

# Linux VM Setup
resource "azurerm_linux_virtual_machine" "dev_vm" {
  name                            = "dev-vm-01"
  location                        = azurerm_resource_group.rg.location
  resource_group_name             = azurerm_resource_group.rg.name
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

  custom_data = filebase64("docker_install.sh")  # Docker install script
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "log_workspace" {
  name                = "law-dev-monitoring-01"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Application Insights (linked to Log Analytics Workspace)
resource "azurerm_application_insights" "app_insights" {
  name                = "appi-dev-monitoring-01"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "other"  # "other" because it's not a web app directly
  workspace_id        = azurerm_log_analytics_workspace.log_workspace.id

  retention_in_days   = 30  # Optional, aligns with the workspace retention
}

