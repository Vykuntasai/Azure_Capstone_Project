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
Refer to main.tf file
```
## Installation for Docker
```
Refer to docker_install.sh
```
