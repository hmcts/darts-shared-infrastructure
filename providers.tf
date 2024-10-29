terraform {
  backend "azurerm" {}

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 1.15.0"
    }
  }
}