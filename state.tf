terraform {
  backend "azurerm" {}

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.66"
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


provider "azurerm" {
  features {}
  skip_provider_registration = true
  alias                      = "postgres_network"
  subscription_id            = var.aks_subscription_id
}

