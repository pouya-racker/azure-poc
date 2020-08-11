# Default values of Azure resources are configured in this file.
# They could be changed by the user's policies and preferences.
####################### Naming Policy ###########################
app_name                     = "app1"
env_name                     = "prod"
##################### Resource Group ###########################
resource_group_location      = "centralus"
custom_location_abbreviate   = "cus"
########################## vNet ################################
address_prefix               = "10.0.0.0/16"
subnet_prefix                = "10.0.0.0/24"
########################## VMs #################################
vm1size                      = "Standard_F2"
vm2size                      = "Standard_F2"
######################## OS Images #############################
os_publisher                 = "MicrosoftWindowsServer"
os_offer                     = "WindowsServer"
os_sku                       = "2019-Datacenter"
os_version                   = "latest"
################################################################
