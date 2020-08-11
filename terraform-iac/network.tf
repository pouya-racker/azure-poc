# Provisioning Resource Group, vNet, Subnet and interfaces for VMs

resource "azurerm_resource_group" "resource_group1" {
  name                            = "rg-${var.custom_location_abbreviate}-${var.env_name}-${var.app_name}"
  location                        = var.resource_group_location
}

resource "azurerm_virtual_network" "virtual_network1" {
  name                            = "vnet-${var.env_name}-${var.custom_location_abbreviate}-01"
  address_space                   = [var.address_prefix]
  location                        = azurerm_resource_group.resource_group1.location
  resource_group_name             = azurerm_resource_group.resource_group1.name
}

resource "azurerm_subnet" "subnet1" {
  name                            = "snet-${var.env_name}-${var.custom_location_abbreviate}-01"
  resource_group_name             = azurerm_virtual_network.virtual_network1.resource_group_name
  virtual_network_name            = azurerm_virtual_network.virtual_network1.name
  address_prefix                  = var.subnet_prefix
}

resource "azurerm_network_interface" "interface1" {
  name                            = "netif-${var.env_name}-${var.custom_location_abbreviate}-001"
  location                        = azurerm_virtual_network.virtual_network1.location
  resource_group_name             = azurerm_virtual_network.virtual_network1.resource_group_name

  ip_configuration {
    name                          = "pvip-${var.env_name}-${var.custom_location_abbreviate}-01"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "interface2" {
  name                            = "netif-${var.env_name}-${var.custom_location_abbreviate}-002"
  location                        = azurerm_virtual_network.virtual_network1.location
  resource_group_name             = azurerm_virtual_network.virtual_network1.resource_group_name

  ip_configuration {
    name                          = "pvip-${var.env_name}-${var.custom_location_abbreviate}-01"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
  }
}