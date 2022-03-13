terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.99.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "2.19.1"
    }
  }

  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

provider "azuread" {

}

data "azurerm_subscription" "current" {}

data "azuread_client_config" "current" {}

resource "azurerm_resource_group" "default" {
  name     = "default"
  location = var.region
}