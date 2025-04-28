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
 
  custom_data = filebase64("docker_install.sh")     # Create a docker_install.sh file in same folder(docker_install.sh is they in github files)
}

# 8. App Service Plan
resource "azurerm_app_service_plan" "appserviceplan" {
  name                = "appserviceplan-dev-01"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name

  sku {
    tier = "Basic"
    size = "B1"
  }

  reserved = true  # Linux App Service
}

# 9. Web App
resource "azurerm_linux_web_app" "webapp" {
  name                = "webapp-dev-01"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
  service_plan_id     = azurerm_app_service_plan.appserviceplan.id

  site_config {
    always_on = true
    linux_fx_version = "DOCKER|mcr.microsoft.com/azuredocs/aci-helloworld:latest"  # Sample Docker image
  }

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "WEBSITE_RUN_FROM_PACKAGE"            = "1"
  }
}

# 10. Private Endpoint for Web App
resource "azurerm_private_endpoint" "webapp_private_endpoint" {
  name                = "pep-webapp-dev-01"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
  subnet_id           = azurerm_subnet.pep.id

  private_service_connection {
    name                           = "psc-webapp-dev-01"
    private_connection_resource_id = azurerm_linux_web_app.webapp.id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }
}

# 11. Private DNS Zone for Web App
resource "azurerm_private_dns_zone" "webapp_dns" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = azurerm_resource_group.network.name
}

# 12. Virtual Network Link to Private DNS Zone
resource "azurerm_private_dns_zone_virtual_network_link" "webapp_dns_link" {
  name                  = "webappdnslink"
  resource_group_name   = azurerm_resource_group.network.name
  private_dns_zone_name = azurerm_private_dns_zone.webapp_dns.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

# 13. A Record for Web App inside Private DNS
resource "azurerm_private_dns_a_record" "webapp_dns_a" {
  name                = azurerm_linux_web_app.webapp.name
  zone_name           = azurerm_private_dns_zone.webapp_dns.name
  resource_group_name = azurerm_resource_group.network.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.webapp_private_endpoint.private_service_connection[0].private_ip_address]
}


