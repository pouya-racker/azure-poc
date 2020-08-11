################################################################
#    _   ___                 _ _____     _    _   _ _          #
#   | | / / |               | |_   _|   | |  | | (_) |         #
#   | |/ /| | ___  _   _  __| | | | __ _| | _| |_ _| | _____   #
#   |    \| |/ _ \| | | |/ _` | | |/ _` | |/ / __| | |/ / __|  #
#   | |\  \ | (_) | |_| | (_| | | | (_| |   <| |_| |   <\__ \  #
#   \_| \_/_|\___/ \__,_|\__,_| \_/\__,_|_|\_\\__|_|_|\_\___/  #
#                                                              #
################################################################
# Provisioning AS, VMs and the nsg assigned to the VMs

resource "azurerm_availability_set" "availability_set1" {
  name                        = "as-${var.env_name}-${var.custom_location_abbreviate}-01"
  location                    = azurerm_resource_group.resource_group1.location
  resource_group_name         = azurerm_resource_group.resource_group1.name
}

resource "azurerm_network_security_group" "nsg1" {
  name                        = "nsg-${var.env_name}-${var.custom_location_abbreviate}-01"
  resource_group_name = azurerm_resource_group.resource_group1.name
  location                    = azurerm_resource_group.resource_group1.location
}

resource "azurerm_subnet_network_security_group_association" "nsg-associate1" {
  subnet_id                   = azurerm_subnet.subnet1.id
  network_security_group_id   = azurerm_network_security_group.nsg1.id
}

# NOTE: this allows HTTP from any network
resource "azurerm_network_security_rule" "http" {
  name                        = "http"
  resource_group_name         = azurerm_resource_group.resource_group1.name
  network_security_group_name = azurerm_network_security_group.nsg1.name
  priority                    = 102
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

# NOTE: this allows HTTPS from any network
resource "azurerm_network_security_rule" "https" {
  name                        = "https"
  resource_group_name         = azurerm_resource_group.resource_group1.name
  network_security_group_name = azurerm_network_security_group.nsg1.name
  priority                    = 103
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_windows_virtual_machine" "vm1" {
  name                        = "${var.env_name}${var.app_name}${var.custom_location_abbreviate}01"
  resource_group_name         = azurerm_resource_group.resource_group1.name
  location                    = azurerm_resource_group.resource_group1.location
  size                        = var.vm1size
  admin_username              = var.admin_username
  admin_password              = var.admin_password
  availability_set_id         = azurerm_availability_set.availability_set1.id
  network_interface_ids       = [azurerm_network_interface.interface1.id]
  os_disk {
    caching                   = "ReadWrite"
    storage_account_type      = "Standard_LRS"
  }

  source_image_reference {
    publisher                 = var.os_publisher
    offer                     = var.os_offer
    sku                       = var.os_sku
    version                   = var.os_version
  }
}

resource "azurerm_windows_virtual_machine" "vm2" {
  name                        = "${var.env_name}${var.app_name}${var.custom_location_abbreviate}02"
  resource_group_name         = azurerm_resource_group.resource_group1.name
  location                    = azurerm_resource_group.resource_group1.location
  size                        = var.vm2size
  admin_username              = var.admin_username
  admin_password              = var.admin_password
  availability_set_id         = azurerm_availability_set.availability_set1.id
  network_interface_ids       = [azurerm_network_interface.interface2.id]
  os_disk {
    caching                   = "ReadWrite"
    storage_account_type      = "Standard_LRS"
  }

  source_image_reference {
    publisher                 = var.os_publisher
    offer                     = var.os_offer
    sku                       = var.os_sku
    version                   = var.os_version
  }
}

resource "azurerm_virtual_machine_extension" "startup-script-vm1" {
  name                 = "hostname"
  virtual_machine_id   = azurerm_windows_virtual_machine.vm1.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

  protected_settings = <<SETTINGS
    {
        "commandToExecute": "powershell -command \"[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('${base64encode(data.template_file.startup-script.rendered)}')) | Out-File -filepath startup-script.ps1\" && powershell -ExecutionPolicy Unrestricted -File startup-script.ps1"
    }
SETTINGS

  tags = {
    environment = "PoC"
  }
}


resource "azurerm_virtual_machine_extension" "startup-script-vm2" {
  name                 = "hostname"
  virtual_machine_id   = azurerm_windows_virtual_machine.vm2.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

  protected_settings = <<SETTINGS
    {
        "commandToExecute": "powershell -command \"[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('${base64encode(data.template_file.startup-script.rendered)}')) | Out-File -filepath startup-script.ps1\" && powershell -ExecutionPolicy Unrestricted -File startup-script.ps1"
    }
SETTINGS

  tags = {
    environment = "PoC"
  }
}

data "template_file" "startup-script" {
    template = "${file("startup-script.ps1")}"
}


//////////////////////////////////////////////////////////////////////////////
//  Example of pulling and using powershell script that is checked into Github
//////////////////////////////////////////////////////////////////////////////

//   protected_settings = <<PROTECTED_SETTINGS
//     {
//       "commandToExecute": "powershell.exe -Command \"./test.ps1; exit 0;\""
//     }
//   PROTECTED_SETTINGS
//
//   settings = <<SETTINGS
//     {
//         "fileUris": [
//           "https://gist.githubusercontent.com/mytest/test.ps1"
//         ]
//     }
//   SETTINGS


//////////////////////////////////////////////////////////////////////////////
//  Example of inline powershell script
//////////////////////////////////////////////////////////////////////////////

//resource "azurerm_virtual_machine_extension" "startup-script" {
//  name                 = "hostname"
//  virtual_machine_id   = azurerm_windows_virtual_machine.vm1.id
//  publisher            = "Microsoft.Compute"
//  type                 = "CustomScriptExtension"
//  type_handler_version = "1.9"
//
//  protected_settings = <<SETTINGS
//    {
//        "commandToExecute": "powershell.exe -ExecutionPolicy Unrestricted -Command {Install-WindowsFeature -name Web-Server -IncludeManagementTools}"
//    }
//SETTINGS