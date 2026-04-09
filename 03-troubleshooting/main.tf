# ============================================================
# LAB 03 — State & Dependency Conflicts
# ============================================================
# Deploy this FIRST. Then run break-state.ps1 to simulate drift.
# The prevent_destroy lifecycle makes cleanup tricky on purpose.
# ============================================================

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  # TODO: Replace with your own Azure subscription ID
  subscription_id = "<YOUR_SUBSCRIPTION_ID>"
}

resource "azurerm_resource_group" "lab03" {
  name     = "rg-lab03-state-test"
  location = "Canada Central"

  tags = {
    environment = "training"
    lab         = "03-state"
  }

  # This will block terraform destroy — intentional!
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_virtual_network" "lab03" {
  name                = "vnet-lab03"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.lab03.location
  resource_group_name = azurerm_resource_group.lab03.name

  tags = {
    environment = "training"
    lab         = "03-state"
  }
}

resource "azurerm_subnet" "lab03" {
  name                 = "subnet-lab03"
  resource_group_name  = azurerm_resource_group.lab03.name
  virtual_network_name = azurerm_virtual_network.lab03.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "lab03" {
  name                = "nsg-lab03"
  location            = azurerm_resource_group.lab03.location
  resource_group_name = azurerm_resource_group.lab03.name

  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "training"
    lab         = "03-state"
  }
}
