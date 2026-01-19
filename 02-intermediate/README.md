# Module 02: Remote State, Variables, and Modules

## Overview

In this module, you will build on your Terraform basics knowledge by learning three essential concepts:

1. **Remote State** - Store state in Azure Storage for team collaboration
2. **Variables** - Make configurations flexible and reusable
3. **Modules** - Organize code into reusable components

You will deploy an **Azure App Service (Linux)** running a simple web application.

**Duration:** 45-60 minutes

**Learning Objectives:**

- Configure Terraform remote state with Azure Storage backend
- Understand state locking and why it matters for teams
- Define variables with types, descriptions, and validation
- Create and use a reusable Terraform module
- Deploy a Linux Web App to Azure

---

## Prerequisites

Before starting, ensure you have completed:

- Module 00: Prerequisites (Terraform, Azure CLI, Git installed)
- Module 01: Basics (understand init, plan, apply, destroy)
- Authenticated to Azure with `az login`

Set your Azure environment variables:

```powershell
$env:ARM_SUBSCRIPTION_ID = (az account show --query id -o tsv)
$env:ARM_TENANT_ID = (az account show --query tenantId -o tsv)
```

---

## Part 1: Understanding Remote State

### Why Remote State?

In Module 01, Terraform stored state locally in `terraform.tfstate`. This works for learning, but has problems for real projects:

| Local State Problem | Impact                                      |
| ------------------- | ------------------------------------------- |
| No collaboration    | Team members can't share state              |
| No locking          | Concurrent runs can corrupt state           |
| No backup           | Losing the file = losing track of resources |

**Remote state** solves these problems by storing state in Azure Storage with automatic locking.

---

### Action 1: Create the Remote State Storage

First, create the Azure Storage account that will hold your Terraform state.

**Choose unique names** (storage accounts must be globally unique):

```powershell
# Set your variables (customize these!)
$RESOURCE_GROUP = "rg-tfstate"
$STORAGE_ACCOUNT = "sttfstate$(Get-Random -Maximum 9999)"  # e.g., sttfstate1234
$CONTAINER = "tfstate"
$LOCATION = "centralus"

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create storage account
az storage account create `
  --name $STORAGE_ACCOUNT `
  --resource-group $RESOURCE_GROUP `
  --location $LOCATION `
  --sku Standard_LRS `
  --kind StorageV2

# Create blob container
az storage container create `
  --name $CONTAINER `
  --account-name $STORAGE_ACCOUNT
```

**Write down your storage account name!** You'll need it in the next step.

```powershell
# Display your values
Write-Host "Resource Group: $RESOURCE_GROUP"
Write-Host "Storage Account: $STORAGE_ACCOUNT"
Write-Host "Container: $CONTAINER"
```

---

## Part 2: Create the Project Structure

### Action 2: Set Up the Working Directory

Navigate to the module folder and create the file structure:

```powershell
cd C:\Users\$env:USERNAME\Desktop\TerraformTraining\02-intermediate

# Create the module folder structure
New-Item -ItemType Directory -Path "modules\appservice" -Force
```

Your folder should look like this:

```
02-intermediate/
├── main.tf              (you will create)
├── variables.tf         (you will create)
├── outputs.tf           (you will create)
├── dev.tfvars           (you will create)
└── modules/
    └── appservice/
        ├── main.tf      (you will create)
        ├── variables.tf (you will create)
        └── outputs.tf   (you will create)
```

---

### Action 3: Create versions.tf

Create a new file `versions.tf` with the following content:

```hcl
terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}
```

This pins the Terraform and provider versions for consistency.

---

### Action 4: Create main.tf with Remote Backend

Create `main.tf` with the backend configuration:

```hcl
# Configure remote state backend
terraform {
  backend "azurerm" {
    use_azuread_auth = true
    # Other values provided via -backend-config during init
  }
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
}

# Local values for naming
locals {
  resource_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Module      = "02-intermediate"
  }
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-${local.resource_prefix}"
  location = var.location
  tags     = local.common_tags
}

# Call the App Service module
module "appservice" {
  source = "./modules/appservice"

  app_name            = "${local.resource_prefix}-app"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku_name            = var.app_service_sku
  tags                = local.common_tags
}
```

---

### Action 5: Create variables.tf

Create `variables.tf` to define your input variables:

```hcl
variable "environment" {
  description = "Environment name (dev, test, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "Environment must be: dev, test, or prod."
  }
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "Central US"
}

variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
  default     = "tftraining"
}

variable "app_service_sku" {
  description = "App Service Plan SKU"
  type        = string
  default     = "F1"

  validation {
    condition     = contains(["F1", "B1", "B2", "S1"], var.app_service_sku)
    error_message = "SKU must be one of: F1, B1, B2, S1."
  }
}
```

**Key Concepts:**

- `type` - Enforces the variable type (string, number, bool, list, map)
- `default` - Optional default value
- `validation` - Custom validation rules with error messages

---

### Action 6: Create outputs.tf

Create `outputs.tf` to expose useful information:

```hcl
output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.main.name
}

output "app_service_url" {
  description = "URL of the deployed web app"
  value       = "https://${module.appservice.hostname}"
}
```

---

### Action 7: Create dev.tfvars

Create `dev.tfvars` for your development environment values:

```hcl
environment     = "dev"
location        = "Central US"
project_name    = "tftraining"
app_service_sku = "F1"
```

---

## Part 3: Create the App Service Module

Modules are reusable packages of Terraform configuration. Let's create one for App Service.

### Action 8: Create modules/appservice/main.tf

```hcl
# App Service Plan
resource "azurerm_service_plan" "main" {
  name                = "asp-${var.app_name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = var.sku_name
  tags                = var.tags
}

# Linux Web App
resource "azurerm_linux_web_app" "main" {
  name                = var.app_name
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.main.id
  https_only          = true

  site_config {
    application_stack {
      node_version = "18-lts"
    }
  }

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
  }

  tags = var.tags
}
```

---

### Action 9: Create modules/appservice/variables.tf

```hcl
variable "app_name" {
  description = "Name of the web application"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "sku_name" {
  description = "App Service Plan SKU"
  type        = string
  default     = "F1"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
```

---

### Action 10: Create modules/appservice/outputs.tf

```hcl
output "hostname" {
  description = "Default hostname of the web app"
  value       = azurerm_linux_web_app.main.default_hostname
}

output "app_id" {
  description = "ID of the web app"
  value       = azurerm_linux_web_app.main.id
}
```

---

## Part 4: Deploy with Remote State

### Action 11: Initialize with Remote Backend

Now initialize Terraform with your remote backend. **Replace the values** with your storage account details from Action 1:

```powershell
terraform init `
  -backend-config="resource_group_name=rg-tfstate" `
  -backend-config="storage_account_name=YOUR_STORAGE_ACCOUNT" `
  -backend-config="container_name=tfstate" `
  -backend-config="key=dev/appservice.tfstate"
```

**Expected output:**

```
Initializing the backend...
Successfully configured the backend "azurerm"!

Initializing modules...
- appservice in modules\appservice

Initializing provider plugins...
```

---

### Action 12: Validate Your Configuration

```powershell
terraform validate
```

If there are errors, check your file syntax and fix them.

---

### Action 13: Plan the Deployment

Before applying, predict what Terraform will create:

**Your prediction:**

1. 1 Resource Group
2. 1 App Service Plan
3. 1 Linux Web App

Now verify with plan:

```powershell
terraform plan -var-file="dev.tfvars"
```

Does the output match your prediction?

---

### Action 14: Apply the Configuration

```powershell
terraform apply -var-file="dev.tfvars"
```

Type `yes` when prompted.

After completion, Terraform shows your outputs:

```
Outputs:

app_service_url = "https://tftraining-dev-app.azurewebsites.net"
resource_group_name = "rg-tftraining-dev"
```

---

### Action 15: Verify the Deployment

Open the URL in your browser. You should see the Azure App Service default page.

You can also verify via Azure CLI:

```powershell
az webapp show --name "tftraining-dev-app" --resource-group "rg-tftraining-dev" --query state
```

---

## Part 5: Observe Remote State

### Action 16: View State in Azure Storage

Check that your state file is stored in Azure:

```powershell
az storage blob list `
  --account-name YOUR_STORAGE_ACCOUNT `
  --container-name tfstate `
  --output table
```

You should see `dev/appservice.tfstate` listed.

---

### Action 17: Understand State Locking

When Terraform runs, it creates a lock to prevent concurrent modifications.

Try this:

1. Start a `terraform plan` in one terminal
2. Quickly run `terraform plan` in another terminal

The second command will wait for the lock, showing:

```
Acquiring state lock. This may take a few moments...
```

This prevents team members from corrupting state with simultaneous operations.

---

## Part 6: Make Changes

### Action 18: Change the SKU

Edit `dev.tfvars` and change the SKU:

```hcl
app_service_sku = "B1"
```

**Predict:** What will Terraform do?

```powershell
terraform plan -var-file="dev.tfvars"
```

You should see an **in-place update** to the App Service Plan:

```
~ sku_name = "F1" -> "B1"

Plan: 0 to add, 1 to change, 0 to destroy.
```

**Apply the change:**

```powershell
terraform apply -var-file="dev.tfvars"
```

---

### Action 19: Test Variable Validation

Try setting an invalid SKU:

```powershell
terraform plan -var-file="dev.tfvars" -var="app_service_sku=INVALID"
```

Terraform rejects it with your custom error message:

```
Error: Invalid value for variable

SKU must be one of: F1, B1, B2, S1.
```

---

## Part 7: Clean Up

### Action 20: Destroy Resources

Remove all resources created by Terraform:

```powershell
terraform destroy -var-file="dev.tfvars"
```

Type `yes` when prompted.

**Optional:** Delete the state storage if no longer needed:

```powershell
az group delete --name rg-tfstate --yes
```

---

## Summary

In this module, you learned:

| Concept          | What You Did                                |
| ---------------- | ------------------------------------------- |
| **Remote State** | Stored state in Azure Storage with locking  |
| **Variables**    | Defined inputs with types and validation    |
| **Modules**      | Created reusable App Service component      |
| **Environments** | Used tfvars for environment-specific values |

---

## Key Commands Reference

| Command                                  | Purpose                         |
| ---------------------------------------- | ------------------------------- |
| `terraform init -backend-config=...`     | Initialize with remote backend  |
| `terraform plan -var-file=dev.tfvars`    | Plan with environment variables |
| `terraform apply -var-file=dev.tfvars`   | Apply configuration             |
| `terraform destroy -var-file=dev.tfvars` | Destroy all resources           |

---

## Next Steps

You're now ready for more advanced topics:

- Data sources and resource dependencies
- Workspaces for environment management
- CI/CD integration with GitHub Actions

---

## Troubleshooting

**Error: Backend configuration required**

- Ensure you passed all `-backend-config` values during init

**Error: Storage account not found**

- Verify the storage account exists: `az storage account show --name YOUR_ACCOUNT`

**Error: Access denied**

- Re-authenticate: `az login`

---

**Version:** 1.0  
**Last Updated:** January 2026
