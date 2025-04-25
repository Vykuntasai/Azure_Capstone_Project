#Azure Capstone Project 2025
## Project Overview
```
This project automates the deployment of a secure, monitored infrastructure on Microsoft Azure using **Terraform** and **Azure DevOps**, designed for the Central India region.
```
It includes:
- A Web Application with Private Endpoint
- A Virtual Machine (Ubuntu 22.04 LTS)
- Diagnostic Settings, Monitoring, Alerts
- Security and Deletion Locks
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
  name                 = "snet-dev-web"
  resource_group_name  = azurerm_resource_group.network_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.0.0/22"]
}

resource "azurerm_network_security_group" "web_nsg" {
  name                = "web-nsg"
  location            = "Central India"
  resource_group_name = azurerm_resource_group.network_rg.name
}

resource "azurerm_subnet" "snet_app" {
  name                 = "snet-dev-app"
  resource_group_name  = azurerm_resource_group.network_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.4.0/22"]
}

resource "azurerm_network_security_group" "app_nsg" {
  name                = "app-nsg"
  location            = "Central India"
  resource_group_name = azurerm_resource_group.network_rg.name
}

resource "azurerm_subnet" "snet_data" {
  name                 = "snet-dev-data"
  resource_group_name  = azurerm_resource_group.network_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.8.0/22"]
}

resource "azurerm_network_security_group" "data_nsg" {
  name                = "data-nsg"
  location            = "Central India"
  resource_group_name = azurerm_resource_group.network_rg.name
}

resource "azurerm_subnet" "snet_pep" {
  name                 = "snet-dev-pep"
  resource_group_name  = azurerm_resource_group.network_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.12.0/22"]
  
}

resource "azurerm_network_security_group" "pep_nsg" {
  name                = "pep-nsg"
  location            = "Central India"
  resource_group_name = azurerm_resource_group.network_rg.name
}
```

