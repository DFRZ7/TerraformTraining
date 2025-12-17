# Configure the Azure Provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
  required_version = ">= 1.0"
}

provider "azurerm" {
  features {}
}

# Create a Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-terraform-basics"
  location = "Central US"

  tags = {
    Environment = "Training"
    Module      = "01-basics"
    ManagedBy   = "Terraform"
  }
}
