# Variables
variable "prefix" {
  default = "Vykuntasai"
  type    = string
}
 
# Resource Group for Networking
resource "azurerm_resource_group" "network" {
  name     = "${var.prefix}-rg-dev-network"
  location = "Central India"
}
# Resource Group for Application
resource "azurerm_resource_group" "application" {
  name     = "${var.prefix}-rg-dev-application"
  location = "Central India"
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-vnet-dev"
  address_space       = ["10.1.0.0/20"]
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
}
 
# Subnets
resource "azurerm_subnet" "web" {
  name                 = "${var.prefix}-snet-dev-web"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.0.0/22"]
}
 
resource "azurerm_subnet" "app" {
  name                 = "${var.prefix}-snet-dev-app"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.4.0/22"]
}
 
resource "azurerm_subnet" "data" {
  name                 = "${var.prefix}-snet-dev-data"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.8.0/22"]
}
 
resource "azurerm_subnet" "pep" {
  name                 = "${var.prefix}-snet-dev-pep-01"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.12.0/22"]
}
 
 
 
resource "azurerm_network_security_group" "web_nsg" {
  name                = "${var.prefix}-nsg-snet-dev-web-01"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
}
 
resource "azurerm_network_security_group" "app_nsg" {
  name                = "${var.prefix}-nsg-snet-dev-app-01"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
}
resource "azurerm_network_security_rule" "allow_ssh_from_my_ip" {
  name                        = "Allow-SSH-From-My-IP"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "13.71.3.96" #your ip address
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.network.name
  network_security_group_name = azurerm_network_security_group.web_nsg.name
}
 
resource "azurerm_network_security_rule" "deny_other_ssh" {
  name                        = "Deny-Other-SSH"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.network.name
  network_security_group_name = azurerm_network_security_group.web_nsg.name
}
resource "azurerm_network_security_group" "data_nsg" {
  name                = "${var.prefix}-nsg-snet-dev-data-01"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
}
 
resource "azurerm_network_security_group" "pep_nsg" {
  name                = "${var.prefix}-nsg-snet-dev-pep-01"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
}
 
 
 
# Associate NSGs with subnets
resource "azurerm_subnet_network_security_group_association" "web" {
  subnet_id                 = azurerm_subnet.web.id
  network_security_group_id = azurerm_network_security_group.web_nsg.id
}
 
resource "azurerm_subnet_network_security_group_association" "app" {
  subnet_id                 = azurerm_subnet.app.id
  network_security_group_id = azurerm_network_security_group.app_nsg.id
}
 
resource "azurerm_subnet_network_security_group_association" "data" {
  subnet_id                 = azurerm_subnet.data.id
  network_security_group_id = azurerm_network_security_group.data_nsg.id
}
 
resource "azurerm_subnet_network_security_group_association" "pep" {
  subnet_id                 = azurerm_subnet.pep.id
  network_security_group_id = azurerm_network_security_group.pep_nsg.id
}
 
 
 
# Public IP for VM
resource "azurerm_public_ip" "vm_ip" {
  name                = "${var.prefix}-pip-dev-vm-01"
  location            = azurerm_resource_group.application.location
  resource_group_name = azurerm_resource_group.application.name
  allocation_method   = "Static"
  sku                 = "Basic"
}
 
# NIC for VM
resource "azurerm_network_interface" "dev_vm_nic" {
  name                = "${var.prefix}-nic-dev-vm-01"
  location            = azurerm_resource_group.application.location
  resource_group_name = azurerm_resource_group.application.name
 
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_ip.id
  }
}
 
# VM
resource "azurerm_linux_virtual_machine" "dev_vm" {
  name                  = "${var.prefix}-dev-vm-01"
  location              = azurerm_resource_group.application.location
  resource_group_name   = azurerm_resource_group.application.name
  network_interface_ids = [azurerm_network_interface.dev_vm_nic.id]
  size                  = "Standard_B1s"
  admin_username        = "azureuser"
  disable_password_authentication = true
   identity {
    type = "SystemAssigned"
   }
  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
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
 
  custom_data = fileexists("docker-install.sh") ? filebase64("docker-install.sh") : null
}
 
# App service plan
 
resource "azurerm_service_plan" "asp" {
  name                = "${var.prefix}-asp-01"
  resource_group_name = azurerm_resource_group.application.name
  location            =  azurerm_resource_group.application.location
  os_type             = "Linux"
  sku_name            = "S1"
}
 
#Add Application Insights ---> For web app monitoring
 
resource "azurerm_application_insights" "webapp_insights" {
  name                = "${var.prefix}-appinsights-01"
  location            = azurerm_resource_group.application.location
  resource_group_name = azurerm_resource_group.application.name
  application_type    = "web"  # For web applications
  workspace_id        = azurerm_log_analytics_workspace.monitoring.id  # Add this if you have LA
}

#Create Log Analytics Workspace ---> Required for both Application Insights and VM monitoring
resource "azurerm_log_analytics_workspace" "monitoring" {
  name                = "${var.prefix}-law-01"
  location            = azurerm_resource_group.application.location
  resource_group_name = azurerm_resource_group.application.name
  sku                 = "PerGB2018"  # Free tier eligible
  retention_in_days   = 30
}
 
# Web app
resource "azurerm_linux_web_app" "webapp" {
  name                = "${var.prefix}-webapp-01"
  resource_group_name = azurerm_resource_group.application.name
  location            = azurerm_service_plan.asp.location
  service_plan_id     = azurerm_service_plan.asp.id
 
  site_config {
    application_stack {
      dotnet_version = "8.0" #Using dotnet for deploying web application
    }
  }
 
  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    # Application Insights Integration
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.webapp_insights.instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.webapp_insights.connection_string
    "ApplicationInsightsAgent_EXTENSION_VERSION" = "~3"  # Auto-instrumentation
    "XDT_MicrosoftApplicationInsights_Mode" = "recommended"
    # For .NET Core apps
    "ASPNETCORE_HOSTINGSTARTUPASSEMBLIES" = "Microsoft.ApplicationInsights.StartupBootstrapper"
  }
  public_network_access_enabled = false
}
  
# Private DNS Zone for Web App
resource "azurerm_private_dns_zone" "webapp_dns" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = azurerm_resource_group.network.name
}

# Link Private DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "webapp_dns_link" {
  name                  = "${var.prefix}-webapp-dns-link-01"
  resource_group_name   = azurerm_resource_group.network.name
  private_dns_zone_name = azurerm_private_dns_zone.webapp_dns.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

# Private Endpoint for Web App
resource "azurerm_private_endpoint" "webapp_pe" {
  name                = "${var.prefix}-pe-webapp-01"
  location            = azurerm_resource_group.application.location
  resource_group_name = azurerm_resource_group.application.name
  subnet_id           = azurerm_subnet.pep.id
 
  private_service_connection {
    name                           = "${var.prefix}-psc-webapp-01"
    private_connection_resource_id = azurerm_linux_web_app.webapp.id
    is_manual_connection           = false
    subresource_names              = ["sites"]
  }
 
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.webapp_dns.id]
  }
}
  
# from GitHub we are pulling the repo and runnning the web app
 
resource "azurerm_app_service_source_control" "scm" {
  app_id    = azurerm_linux_web_app.webapp.id
  repo_url  = "https://github.com/Vykuntasai/Vykuntasai-capstone"  
  branch    = "main"
}
 
# Output the private endpoint FQDN for web app access
output "webapp_private_fqdn" {
  value = "${azurerm_linux_web_app.webapp.name}.azurewebsites.net"
}
 
output "webapp_private_endpoint_ip" {
  value = azurerm_private_endpoint.webapp_pe.private_service_connection[0].private_ip_address
}
 
output "vm_public_ip" {
  value = azurerm_public_ip.vm_ip.ip_address
}
 
output "ssh_command" {
  value = "ssh azureuser@${azurerm_public_ip.vm_ip.ip_address}"
}
  
#Configure Diagnostic Settings ---> For all  resources 
# 1. WEB APP DIAGNOSTICS ---> HTTP logs + metrics
resource "azurerm_monitor_diagnostic_setting" "webapp_diag" {
  name                       = "webapp-diag-01"
  target_resource_id         = azurerm_linux_web_app.webapp.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.monitoring.id
  enabled_log {
    category = "AppServiceHTTPLogs"
  }
  metric {
    category = "AllMetrics"
  }
} 
# 2. VM DIAGNOSTICS ---> Metrics only (for basic VM monitoring)
resource "azurerm_monitor_diagnostic_setting" "vm_diag" {
  name                       = "vm-diag-01"
  target_resource_id         = azurerm_linux_virtual_machine.dev_vm.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.monitoring.id
  metric {
    category = "AllMetrics"
  }
} 
# Storage account for boot diagnostics
resource "azurerm_storage_account" "boot_diag" {
  name = replace("${lower(var.prefix)}-dev-boot-diag-01", "-", "")
  resource_group_name      = azurerm_resource_group.application.name
  location                = azurerm_resource_group.application.location
  account_tier            = "Standard"
  account_replication_type = "LRS"
} 
# Extension for Log Analytics agent to collect syslog and other logs
resource "azurerm_virtual_machine_extension" "log_analytics" {
  name                       = "OMSExtension-01"
  virtual_machine_id         = azurerm_linux_virtual_machine.dev_vm.id
  publisher                  = "Microsoft.EnterpriseCloud.Monitoring"
  type                       = "OmsAgentForLinux"
  type_handler_version       = "1.13"
  auto_upgrade_minor_version = true
 
  settings = jsonencode({
    "workspaceId" = azurerm_log_analytics_workspace.monitoring.workspace_id
  })
 
  protected_settings = jsonencode({
    "workspaceKey" = azurerm_log_analytics_workspace.monitoring.primary_shared_key
  })
} 
# 3. NETWORK SECURITY GROUP DIAGNOSTICS ---> Flow logs + rule counters
resource "azurerm_monitor_diagnostic_setting" "nsg_diag" {
  for_each = toset([
    azurerm_network_security_group.web_nsg.id,
    azurerm_network_security_group.app_nsg.id,
    azurerm_network_security_group.data_nsg.id
  ])
  name = "nsg-diag-01-${basename(each.key)}"
  target_resource_id         = each.value
  log_analytics_workspace_id = azurerm_log_analytics_workspace.monitoring.id
  enabled_log {
    category = "NetworkSecurityGroupEvent"
  }
  enabled_log {
    category = "NetworkSecurityGroupRuleCounter"
  }
}
# 4. PUBLIC IP DIAGNOSTICS ---> Metrics
resource "azurerm_monitor_diagnostic_setting" "public_ip_diag" {
  name                       = "pip-diag-01"
  target_resource_id         = azurerm_public_ip.vm_ip.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.monitoring.id
  metric {
    category = "AllMetrics"
  }
}
 
# Email action group
resource "azurerm_monitor_action_group" "email_alert" {
  name                = "${var.prefix}-email-alerts-01"
  resource_group_name = azurerm_resource_group.application.name
  short_name          = "emailalert"
 
  email_receiver {
    name          = "admin-email"
    email_address = "vykuntasai2104@gmail.com" # Replace with your email
  }
}
 
# VM shutdown alert
resource "azurerm_monitor_metric_alert" "vm_shutdown" {
  name                = "${var.prefix}-vm-shutdown-alert-01"
  resource_group_name = azurerm_resource_group.application.name
  scopes             = [azurerm_linux_virtual_machine.dev_vm.id]
  description        = "Alert when VM is shutdown"
 
  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 1  # Triggers when CPU <1% for 5 minutes
  }
 
  action {
    action_group_id = azurerm_monitor_action_group.email_alert.id
  }
}
# Resource Locks to prevent accidental deletion
resource "azurerm_management_lock" "vm_lock" {
  name       = "${var.prefix}-vm-lock-01"
  scope      = azurerm_linux_virtual_machine.dev_vm.id
  lock_level = "CanNotDelete"
  notes      = "This VM should not be deleted"
}
 
resource "azurerm_management_lock" "webapp_lock" {
  name       = "${var.prefix}-webapp-lock-01"
  scope      = azurerm_linux_web_app.webapp.id
  lock_level = "CanNotDelete"
  notes      = "This web app should not be deleted"
}
 
resource "azurerm_management_lock" "rg_network_lock" {
  name       = "${var.prefix}-network-rg-lock-01"
  scope      = azurerm_resource_group.network.id
  lock_level = "CanNotDelete"
  notes      = "This resource group should not be deleted"
}
 
resource "azurerm_management_lock" "rg_app_lock" {
  name       = "${var.prefix}-app-rg-lock-01"
  scope      = azurerm_resource_group.application.id
  lock_level = "CanNotDelete"
  notes      = "This resource group should not be deleted"
}
 
# ... (all your resource definitions above) ...
 
# Output the KQL query for viewing logs
output "kql_query" {
  value = <<EOT
// KQL query to view logs for last 24 hours
AzureActivity
| where TimeGenerated > ago(24h)
| project TimeGenerated, OperationName, Caller, ResourceGroup, Resource
| order by TimeGenerated desc
EOT
}

