# azure-policy-poc

In this repository we will describe the process of defining and assigning 
custom policies for you Azure services.

## Build a custom policy
There are two steps in enforcing a policy to your services. The first step is to
define that policy. In case you would like to use one of the many Azure
builtin policies, you can skip this step. After you have created your policy
(or chosen a builtin policy) you need to *assign* it to a scope in your
organization structure. The policy can only be assigned to resources below the
scope which the original policy was defined at. For example if you define a
policy in a subscription which is a child of a management group, you will not
be able to assign that policy to that specific management group.
There are multiple methods to define new policies. In this section we will 
cover Azure CLI and how to define custom-built policies and assign them to 
resources.

### Policy to enforce geo-location (region) for virtual machines

#### Custom policy definition
In this section we would like to define a policy for enforcing virtual
machines to be built in specific regions. First we need to create a policy
definition using the following command:

```
az policy definition create --name policy-location-vm --description 'This policy can be applied to virtual machines preventing it from being created in any region not specified here.' --display-name 'Virtual machine region policy' --rules policy-location-vm.json --params policy-location-parameters.json --mode All
```

Other than the two JSON files specified in the command above you need to 
specify the name and mode of the policy. It is a good practice to follow 
a naming convention for your policies as well. Policies in Azure can be 
created in two modes, *All* and *indexed*. If the indexed mode is selected the
policy will only be applied to resources which take tags. You can read the
complete documentation [here](https://docs.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure).

While not required, it is good practice to also specify a *displayName* and
*description* when creating a new policy. The displayName will be shown in the
main policy table. The description will help others understand what the policy
does.

Our first policy enforces resources to be created in one of the specified
regions. We define the policy using two JSONs. The first json
(policy-location-vm.json) defines the conditions and the second json
(policy-location-parameters.json) specifies the values which the conditions
should be checked with.

policy-location-vm.json:

```
{
    "if": {
        "allOf": [
            {
                "field": "type",
                "equals": "Microsoft.Compute/virtualMachines"
            },
            {
                "not": {
                    "field": "location",
                    "in": "[parameters('allowedLocations')]"
                }
            }
        ]
    },
    "then": {
      "effect": "deny"
    }
}
```

policy-location-parameters.json:

```
{
    "allowedLocations": {
      "type": "Array",
      "metadata": {
        "displayName": "Allowed locations",
        "description": "The list of allowed locations for resources.",
        "strongType": "location"
      },
      "allowedValues": [
        "eastus2",
        "eastus",
        "westus2",
        "westus"
      ],
      "defaultValue": [
        "eastus"
      ]
    }
}


```

#### Policy assignment
After the policy is built, it will not take effect until you assign it to your
required scope. We will assign the policy we defined above to a sample
resource group.

```
az policy assignment create --display-name 'Enforce virtual machine locations for resource group 1' --name pa-location-vm-rg1 --policy policy-location-general --scope "/subscriptions/<subscriptionID>/resourceGroups/<resourcegroupname>"
```

By using the command above we assign the location policy we defined above to
the resource group in the command. After assigning the policy virtual machines
can only be created in the locations specified by the policy (if they are
created in the respective resource group).
Keep in mind that each policy has both a **deny** and **audit** effect. With
deny the operation will not be permitted, but with audit it will be allowed
but show as a non-compliance in the user interface.

### Policy to enforce naming convention
Following a standard namin convention is suggested as a best practice by
Microsoft. It helps keep your resources organized and well maintained. In this
section we will create a policy to enforce a naming convention where each
resource must have a specific prefix and suffix to be built.

#### Custom policy definition
We will use the Azure CLI to create this policy. The command we will use is
the following:

```
az policy definition create --name policy-naming-rg --description 'This policy enforces a prefix to all resource groups created in the scope which it is
assigned to.' --display-name 'Resource group naming policy' --rules policy-naming-resourcegroup.json  --mode All
```

In this policy we would like all resource groups generated under one of our
subscriptions to follow the pattern *rg-<region>-<env>-*. We only apply the
naming policy to resource groups.
Similar to the previous policy we need to specify the name and mode. We also
specify one JSON file for the rule.
For this specific naming policy we do not need parameters, but using
parameters is similar to the previous example.

policy-naming-resourcegroup.json:

```
{
    "if": {
        "allOf": [
            {
                "field": "type",
                "equals": "Microsoft.Resources/subscriptions/resourceGroups"
            },

            {
                "not": {
                    "field": "name",
                    "like": "[concat('rg-cus-prod', '*')]"
                }
            },
            {
                "not": {
                    "field": "name",
                    "like": "[concat('rg-cus-nonprod', '*')]"
                }
            },
            {
                "not": {
                    "field": "name",
                    "like": "[concat('rg-scus-prod', '*')]"
                }
            },
            {
                "not": {
                    "field": "name",
                    "like": "[concat('rg-scus-nonprod', '*')]"
                }
            }
        ]
    },
    "then": {
        "effect": "deny"
    }
}
```


Now we can assign this policy to a specific subscription.

#### Policy assignment
After the policy is built, it will not take effect until you assign it to your
required scope. We will assign the policy we defined above to a sample
subscription.

```
az policy assignment create --display-name 'Enforce resource group naming policy for subscription 1' --name pa-naming-resourcegrp-sub1 --policy policy-naming-rg --scope "/subscriptions/<subscriptionID>"
```

In this command we have the same name and display name options. These
represent the name of the *assignment* and not the *policy*. It might seem
confusing, but a policy assignment is an entity itself as well.
Using the *--policy* we specify which policy we would like to assign. We can
specify which resources we would like to assign this policy to by using the 
*--scope* argument. In this case we have specified one of our subscriptions.
```
