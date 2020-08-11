# Defining variables which will be used in .tf scripts


variable "resource_group_location" {
  description = "Azure region used for resource deployment"
  }

variable "custom_location_abbreviate" {
  description = "A custom abbreviation for location which is going to be used for naming convention"
  }

variable "app_name"{
  description = "Then short name of the application that is going to be hosted in this Azure resource group"
  }

variable "env_name"{
  description = "The short name representing the environment type of this resource group, .eg prod,stage,test "
  }

variable "address_prefix"{
  description = "IP address range assigned to the vNet"
  }

variable "subnet_prefix"{
  description = "IP address range assigned to the subnet_name under address_prefix"
  }

variable "vm1size"{
  description = "The amount of compute resources configured for VM1 in terms of Azure compute plans"
  }

variable "vm2size"{
  description = "The amount of compute resources configured for VM2 in terms of Azure compute plans"
  }

variable "admin_username" {
  description = "User name to be used for the Virtual Machine"
  }

variable "admin_password" {
  description = "Password for the admin_username of the Virtual Machine."
  }

variable "os_publisher"{
  description = "The publisher of the Operating System choosen for VM"
  }
    
variable "os_offer"{
  description = "The OS family chosen for VM"
  }
    
variable "os_sku"{
  description = "Azure SKU assigned to chosen os_offer"
  }
    
variable "os_version"{
  description = "Specific version of os_offer"
  }
