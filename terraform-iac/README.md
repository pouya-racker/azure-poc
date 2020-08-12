# azure-terraform-poc
This is a proof of concept repository for testing, developing and running Terraform templates in Azure

## Prerequisites

Install Terraform from [here](https://learn.hashicorp.com/terraform/getting-started/install.html#install-terraform) or use Azure Cloud Shell.

Install Azure `az` CLI from [here](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) or use Azure Cloud Shell.

**Notes**:

You can run all following commands from the Azure Cloud Shell or your local terminal. If you run them locally
make sure you have installed the above prerequisites.  

## Infrastructure details

This repository provisions following resources using Terraform confi files:

- Resource Group
- Virtual Network
- Subnet
- NSG(attached to the subnet)
- Availability Set(consisting of 2 Windows VMs running IIS)

![Azure-arch](/terraform-iac/Azure-arch.png) 

## Running Terraform

You can run Terraform in 2 ways:

- Programmatically(non-interactive), e.g. inside a CI/CD pipeline

- Interactively, e.g. from local command line

### Running Terraform programmatically(non-interactive)

#### Create Azure Service Principal and log in

We are using authentication via Azure service 
principal for running Terraform programmatically, for example as part of the CI/CD pipeline. we'll create use az ad sp create-for-rbac to create a service principal with a Contributor role. T
he Contributor role (the default) has full permissions to read and write to an Azure account.

`az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/<subscription_id>"`

Notes:

- Upon successful completion, `az ad sp create-for-rbac` displays several values. The `name`, `password`, and `tenant` values are used in the next step.
- The password can't be retrieved if lost. As such, you should store your password in a safe place. If you forget your password, you'll need to [reset the service principal credentials](https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli?view=azure-cli-latest#reset-credentials).

**Log in using an Azure service principal**: In the following call to `az login`, replace the placeholders with the information from your service principal.

```azurecli
az login --service-principal -u <service_principal_name> -p "<service_principal_password>" --tenant "<service_principal_tenant>"
```

#### Set the current Azure subscription

A Microsoft account can be associated with multiple Azure subscriptions. The following steps outline how you can switch between your subscriptions:

1. To view the current Azure subscription, use `az account show`

    ```azurecli
    az account show
    ```

1. If you have access to multiple available Azure subscriptions, use `az account list`

    ```azurecli
    az account list --query "[].{name:name, subscriptionId:id}"
    ```

1. To use a specific Azure subscription for the current Cloud Shell session, use `az account set`

    ```azurecli
    az account set --subscription="<subscription_id>"
    ```

    Notes:

    - Calling `az account set` doesn't display the results of switching to the specified Azure subscription. However, you can use `az account show` to confirm that the current Azure subscription has changed.
 
### Running Terraform interactively

We are using authentication via Microsoft account to run Terraform interactively, for example via command line. 
Calling `az login` without any parameters displays a URL and a code. Browse to the URL, enter the code, and follow the instructions to log into Azure using your Microsoft account.
Once you're logged in, Terraform will use your account's Auth token to authenticate with Azure Resource Manager and provision resources.
Your account should have proper access(e.g. `Owner` or `Contributor`) set on the Subscription in which you're provisioning resources.  

**Notes**:

- Upon successful login, `az login` displays a list of the Azure subscriptions associated with the logged-in Microsoft account.
- A list of properties displays for each available Azure subscription. The `isDefault` property identifies which Azure subscription you're using. To learn how to switch to another Azure subscription, see the section, [Set the current Azure subscription](#set-the-current-azure-subscription).

### Tracking state

Terraform state is used to reconcile deployed resources with Terraform configurations. State allows Terraform to know what Azure resources to add, update, or delete.
State file `terraform.tfstate` can be kept on a local machine but this approach is not suitable for working as a team member. 

Recommended approach is storing and maintaining the state file in a remote storage so it can be shared between all the team members. 
Terraform supports the persisting of state in remote storage. One such supported back end is Azure Storage. This tutorial shows how to configure and use Azure Storage for this purpose.

Before you use Azure Storage as a back end, you must create a storage account. Use the following sample to configure the storage account with the Azure CLI.

```azurecli
#!/bin/bash

RESOURCE_GROUP_NAME=tstate
STORAGE_ACCOUNT_NAME=tstate$RANDOM
CONTAINER_NAME=tstate

# Create resource group
az group create --name $RESOURCE_GROUP_NAME --location eastus

# Create storage account
az storage account create --resource-group $RESOURCE_GROUP_NAME --name $STORAGE_ACCOUNT_NAME --sku Standard_LRS --encryption-services blob

# Get storage account key
ACCOUNT_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP_NAME --account-name $STORAGE_ACCOUNT_NAME --query [0].value -o tsv)

# Create blob container
az storage container create --name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME --account-key $ACCOUNT_KEY

echo "storage_account_name: $STORAGE_ACCOUNT_NAME"
echo "container_name: $CONTAINER_NAME"
echo "access_key: $ACCOUNT_KEY"
```

You can run the `create-storage-acc.sh` as follow:

`./create-storage-acc.sh`

Take note of the storage account name, container name, and storage access key. These values are needed when you configure the remote state.

#### Configure state backend 

The Terraform state back end is configured when you run the `terraform init` command. The following data is needed to configure the state back end:

- **storage_account_name**: The name of the Azure Storage account.
- **container_name**: The name of the blob container.
- **key**: The name of the state store file to be created.
- **access_key**: The storage access key.

Each of these values can be specified in the Terraform configuration file or on the command line. 
We recommend that you use an environment variable for the `access_key` value. 
Using an environment variable prevents the key from being written to disk.

Create an environment variable named `ARM_ACCESS_KEY` with the value of the Azure Storage access key.

```bash
export ARM_ACCESS_KEY=<storage access key>
```

The following example configures a Terraform backend.

Do not forget to Update the `provider.tf` file with the values you received from running the `create-storage-acc.sh` script.

```hcl
terraform {
  backend "azurerm" {
    resource_group_name   = "tstate"
    storage_account_name  = "tstate09762"
    container_name        = "tstate"
    key                   = "terraform.tfstate"
  }
}
```

Initialize the configuration by doing the following steps:

1. Run the `terraform init` command.
1. Run the `terraform plan` command.

You can now find the state file in the Azure Storage blob.

### Create and apply a Terraform execution plan

Once you create your configuration files, this section explains how to create an *execution plan* and apply it to your cloud infrastructure.

1. Initialize the Terraform deployment with `terraform init` if you haven't done already.

    ```bash
    terraform init
    ```

1. Terraform allows you to preview the actions to be completed with `terraform plan`.

    ```bash
    terraform plan
    ```

    Notes:

    - The `terraform plan` command creates an execution plan, but doesn't execute it. Instead, it determines what actions are necessary to create the configuration specified in your configuration files.
    - The `terraform plan` command enables you to verify whether the execution plan matches your expectations before making any changes to actual resources.
    - The optional `-out` parameter allows you to specify an output file for the plan. For more information on using the `-out` parameter.

1. Apply the execution plan with `terraform apply`.

    ```bash
    terraform apply
    ```

1. Terraform shows you what will happen if you apply the execution plan and requires you to confirm running it. Confirm the command by entering `yes` and pressing the **Enter** key.

### Sensitive variables

We don't recommend saving usernames and passwords to version control. You can create a local file with a name like `secret.tfvars` and use `-var-file` flag to load it.
Make sure you add this file to the `.gitignore` file to avoid checking in it into Git by mistake.
You can use multiple `-var-file` arguments in a single command, with some checked in to version control and others not checked in.

```bash
terraform apply -var-file="secret.tfvars" -var-file="production.tfvars"
```

**Notes**:

Alternatively you can declare sensitive variables in the `variables.tf` file without assigning values to them in the `*.tfvars` file. 
In this case Terraform will prompt you for missing values. This project is using this approach. 

### Additional resources

To see a full list of Terraform Azure resource definitions please see [Azure Provider](https://www.terraform.io/docs/providers/azurerm/index.html) 

For documents about Terraform in Azure please see [Terraform-on-Azure](https://docs.microsoft.com/en-us/azure/developer/terraform/) 