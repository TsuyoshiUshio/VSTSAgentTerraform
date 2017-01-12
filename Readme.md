VSTS Agent Server with docker, kubectl, Azure CLI 2.0
===

This Terraform files enable you to create an VSTS Build Agent Server.

# Getting Started

## 1. Install Terraform 

Download Terraform from [Terraform](https://www.terraform.io/) web site.
It is a single binary. Just add it to your path.

## 2. Edit Setting files

You need to create `terraform.tfvar` file and `vsts.tfvar` file.
You can refer the format by `terraform.tfvar.example` and `vsts.tfvar` respectively.

NOTE: On current version, you need to change strage account name on `terraform.tfvar` file when
you deploy repeatedly. Azure strage account is not removed immediately. It takes 1 or 2 hours, after
it looks removed.

You need a Service Prinicple for terraform, and a [personal access token](https://www.visualstudio.com/en-us/docs/integrate/get-started/auth/overview) of VSTS, 
and VSTS account name to write this setting files.

You can see a document for Service Principle in [here](https://docs.microsoft.com/ja-jp/azure/container-service/container-service-kubernetes-service-principal). 

Also you might need to change the domain name of `terraform.tf` file.

```
resource "azurerm_public_ip" "test" {
  name                         = "BuildSV8"
  location                     = "Japan East"
  resource_group_name          = "${azurerm_resource_group.test.name}"
  public_ip_address_allocation = "static"
  domain_name_label            = "sabuilds2"  <---  change this

  tags {
    environment = "Production"
  }
}
```

## 3. Download your config file of Kubernetes

Download your .kube/config file from Kubernetes Master node. 
This is added in `.gitignore` file. 

```
scp azureuser@{YOUR K8S Master}.{Region}.cloudapp.azure.com:.kube/config .
```

You can refer [Microsoft Azure Container Service Engine - Kubernetes Walkthrough](https://github.com/Azure/acs-engine/blob/master/docs/kubernetes.md).

## 4. Provision your Build Server

You can  verify your source code by this command.

```
terraform plan -var-file vsts.tfvars
```

If it is OK, let's provision it. 

```
terraform apply -var-file vsts.tfvars
```

Enjoy coding




