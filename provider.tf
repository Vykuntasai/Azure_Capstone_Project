provider "azurerm" {
  features {}
  subscription_id = "6ebcabc593774fnnnv97"
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
