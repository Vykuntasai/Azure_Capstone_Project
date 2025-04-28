# To create resource_group
 
resource "azurerm_resource_group" "network" {
  name     = "rg-dev-network-01"
  location = "Central India"
}
 
 
# To create virtual_network
 
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-dev-01"
  address_space       = ["10.1.0.0/20"]
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
}
 
# To create snet-dev-web(Subnet for web)
 
resource "azurerm_subnet" "web" {
  name                 = "snet-dev-web-01"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.0.0/22"]
}
# To create nsg-snet-dev-web(network_security_group for web)
 
resource "azurerm_network_security_group" "web_nsg" {
  name                = "nsg-snet-dev-web-01"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
}
 
# To create snet-dev-app(Subnet for app)
 
resource "azurerm_subnet" "app" {
  name                 = "snet-dev-app-01"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.4.0/22"]
}
 
# To create nsg-snet-dev-app(network_security_group for app)
 
resource "azurerm_network_security_group" "app_nsg" {
  name                = "nsg-snet-dev-app-01"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
}
 
# To create snet-dev-data(Subnet for data)
resource "azurerm_subnet" "data" {
  name                 = "snet-dev-data-01"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.8.0/22"]
}
# To create nsg-snet-dev-app(network_security_group for data)
resource "azurerm_network_security_group" "data_nsg" {
  name                = "nsg-snet-dev-data-01"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
}
 
# To create snet-dev-pep(Subnet for pep)
resource "azurerm_subnet" "pep" {
  name                 = "snet-dev-pep-01"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.12.0/22"]
}
 
# To create nsg-snet-dev-pep(network_security_group for pep)
resource "azurerm_network_security_group" "pep_nsg" {
  name                = "nsg-snet-dev-pep-01"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
}
 
 
# To create virtual machine in web subnet
 
<!-- Every Azure Virtual Machine MUST be connected to a Network Interface Card (NIC).The NIC is the resource that actually attaches
     the VM to a subnet inside a Virtual Network (VNet).The subnet itself is like a network "area," but NIC is what carries the IP address,
     handles communication, security groups, etc. -->
 
resource "azurerm_public_ip" "vm_ip" {
  name                = "pip-dev-vm-01"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
  allocation_method   = "Dynamic"
  sku                 = "Basic"
}
 
resource "azurerm_network_interface" "dev_vm_nic" {
  name                = "nic-dev-vm-01"
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
  name                            = "dev-vm-01"
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
 
 
# After creating Virtual in Web subnet we are going to install the docker by using docker_install.sh file
 
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
 
  custom_data = filebase64("docker-install.sh")     # Create a docker_install.sh file in same folder(docker_install.sh is they in github files)
}
