terraform {
  backend "azurerm" {}

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.110"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azurerm" {
  alias                      = "hub"
  skip_provider_registration = "true"
  features {}
  subscription_id = local.hub[var.hub].subscription
}
