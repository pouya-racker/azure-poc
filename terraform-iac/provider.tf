# Microsoft Azure Resource Manager Provider
# We recommend pinning to the specific version of the Azure Provider you're using
# since new versions are released frequently

provider "azurerm" {
  version = "=2.5.0"
  features {}
}


## Uncomment and update this section if your'e using a remote storage for tracking state
#terraform {
#  backend "azurerm" {
#    resource_group_name   = "tstate"
#    storage_account_name  = "tstate24734"  #Update the $RANDOM
#    container_name        = "tstate"
#    key                   = "terraform.tfstate"
#  }
#}

# More information on the authentication methods supported by
# the AzureRM Provider can be found here:
# http://terraform.io/docs/providers/azurerm/index.html
