# Module 02: Remote State, Variables, and Modules

## Overview

In this module, you will learn three essential Terraform concepts:

1. **Remote State** - Store state in Azure Storage for team collaboration and locking
2. **Variables** - Make configurations flexible with typed inputs and validation
3. **Modules** - Organize code into reusable components

You will deploy an **Azure App Service (Linux)** using these concepts.

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

- Module 00: Prerequisites (Terraform, Azure CLI installed)
- Module 01: Basics (understand init, plan, apply, destroy)
- Authenticated to Azure with `az login --tenant <tenant-id>`

Set your Azure environment variables in PowerShell:

```powershell
$env:ARM_SUBSCRIPTION_ID = (az account show --query id -o tsv)
$env:ARM_TENANT_ID = (az account show --query tenantId -o tsv)
```

---

## Hands-On Lab

## Part 1: Create Remote State Storage

### Why Remote State?

In Module 01, Terraform stored state locally in `terraform.tfstate`. This works for learning, but has problems for real projects:

| Local State Problem | Impact                                      |
| ------------------- | ------------------------------------------- |
| No collaboration    | Team members can't share state              |
| No locking          | Concurrent runs can corrupt state           |
| No backup           | Losing the file = losing track of resources |

**Remote state** stores your state file in Azure Storage. Terraform automatically locks the file during operations, preventing team members from making conflicting changes.

---

### Action 1: Set Variables for State Storage

Open PowerShell and set these variables. The storage account name must be globally unique, so we append a random number:

```powershell
$RESOURCE_GROUP = "rg-tfstate"
$STORAGE_ACCOUNT = "sttfstate$(Get-Random -Maximum 9999)"
$CONTAINER = "tfstate"
$LOCATION = "canadacentral"
```

### Action 2: Create the Storage Resources

Run each command one at a time:

```powershell
az group create --name $RESOURCE_GROUP --location $LOCATION
```

```powershell
az storage account create --name $STORAGE_ACCOUNT --resource-group $RESOURCE_GROUP --location $LOCATION --sku Standard_LRS --kind StorageV2
```

```powershell
az storage container create --name $CONTAINER --account-name $STORAGE_ACCOUNT --auth-mode login
```

### Action 3: Assign Storage Permissions

Terraform uses Azure AD authentication to access the storage account. You need the **Storage Blob Data Contributor** role:

```powershell
$USER_ID = az ad signed-in-user show --query id -o tsv
$SUBSCRIPTION_ID = az account show --query id -o tsv
```

```powershell
az role assignment create --role "Storage Blob Data Contributor" --assignee $USER_ID --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT"
```

Wait 30-60 seconds for the role assignment to propagate.

### Action 4: Save Your Values

Write down these values - you will need them later:

```powershell
Write-Host "Resource Group: $RESOURCE_GROUP"
Write-Host "Storage Account: $STORAGE_ACCOUNT"
Write-Host "Container: $CONTAINER"
```

---

## Part 2: Create the Project Structure

### Action 5: Create the Working Directory

Create a folder for this module on your Desktop:

```powershell
New-Item -ItemType Directory -Path "$env:USERPROFILE\Desktop\Terraform-Training-Workspace\02-intermediate" -Force
cd "$env:USERPROFILE\Desktop\Terraform-Training-Workspace\02-intermediate"
```

### Action 6: Create the Module Folder

Create the folder structure for the App Service module:

```powershell
New-Item -ItemType Directory -Path "modules\appservice" -Force
```

Your folder now looks like this:

```
02-intermediate/
└── modules/
    └── appservice/
```

---

## Part 3: Create the Terraform Files

We will now create each file. Pay attention to **where** each file should be created.

### Action 7: Create versions.tf

**Location:** `02-intermediate/versions.tf`

Create a new file named `versions.tf` in the `02-intermediate` folder with this content:

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

**What this does:** Pins the Terraform version and Azure provider version. This ensures everyone on the team uses compatible versions.

Your folder now looks like this:

```
02-intermediate/
├── versions.tf
└── modules/
    └── appservice/
```

---

### Action 8: Create main.tf

**Location:** `02-intermediate/main.tf`

Create a new file named `main.tf` in the `02-intermediate` folder:

```hcl
terraform {
  backend "azurerm" {
    use_azuread_auth = true
  }
}

provider "azurerm" {
  features {}
}

locals {
  resource_prefix = "${var.project_name}-${var.environment}"
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_resource_group" "main" {
  name     = "rg-${local.resource_prefix}"
  location = var.location
  tags     = local.common_tags
}

module "appservice" {
  source = "./modules/appservice"

  app_name            = "${local.resource_prefix}-app"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku_name            = var.app_service_sku
  tags                = local.common_tags
}
```

**What this does:**

- Configures the Azure Storage backend for remote state
- Creates a resource group with consistent naming
- Calls the App Service module (which we will create next)

> **Why No Variables in the Backend Block?**
>
> You might wonder why we don't use variables like `var.storage_account_name` in the backend configuration. The reason is that **the backend is loaded before the rest of your Terraform configuration**—before variables, before providers, before any modules.
>
> Terraform needs to know where the state lives so it can even begin evaluating variables. That means **backend configuration must be static**.
>
> If you need flexibility, you pass parameters through `-backend-config` during `terraform init` (as we do in Action 15). This is a very common confusion point, so remember: **backend loading happens first**. This design allows the same Terraform code to serve many environments just by supplying different `-backend-config` parameters.

Your folder now looks like this:

```
02-intermediate/
├── versions.tf
├── main.tf
└── modules/
    └── appservice/
```

---

### Action 9: Create variables.tf

**Location:** `02-intermediate/variables.tf`

Create a new file named `variables.tf` in the `02-intermediate` folder:

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
  default     = "canadacentral"
}

variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
  default     = "tftraining"
}

variable "app_service_sku" {
  description = "App Service Plan SKU"
  type        = string
  default     = "B1"

  validation {
    condition     = contains(["F1", "B1", "B2", "S1"], var.app_service_sku)
    error_message = "SKU must be one of: F1, B1, B2, S1."
  }
}
```

**What this does:** Defines input variables with:

- `type` - Enforces the data type (string, number, bool, list, map)
- `default` - Optional default value
- `validation` - Custom rules with error messages

---

### Action 10: Create outputs.tf

**Location:** `02-intermediate/outputs.tf`

Create a new file named `outputs.tf` in the `02-intermediate` folder:

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

**What this does:** Exposes useful information after `terraform apply` completes.

---

### Action 11: Create dev.tfvars

**Location:** `02-intermediate/dev.tfvars`

Create a new file named `dev.tfvars` in the `02-intermediate` folder:

```hcl
environment     = "dev"
location        = "canadacentral"
project_name    = "tftraining"
app_service_sku = "B1"
```

**What this does:** Provides values for the development environment. You can create different `.tfvars` files for test and prod.

Your folder now looks like this:

```
02-intermediate/
├── versions.tf
├── main.tf
├── variables.tf
├── outputs.tf
├── dev.tfvars
└── modules/
    └── appservice/
```

---

## Part 4: Create the App Service Module

Modules are reusable packages of Terraform code. We will create a module that deploys an App Service Plan and Linux Web App.

### Action 12: Create modules/appservice/variables.tf

**Location:** `02-intermediate/modules/appservice/variables.tf`

Create this file inside the `modules/appservice` folder:

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
  default     = "B1"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
```

---

### Action 13: Create modules/appservice/main.tf

**Location:** `02-intermediate/modules/appservice/main.tf`

Create this file inside the `modules/appservice` folder:

```hcl
resource "azurerm_service_plan" "main" {
  name                = "asp-${var.app_name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = var.sku_name
  tags                = var.tags
}

locals {
  is_free_tier = contains(["F1", "D1"], var.sku_name)
}

resource "azurerm_linux_web_app" "main" {
  name                = var.app_name
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.main.id
  https_only          = true

  site_config {
    always_on = local.is_free_tier ? false : true

    application_stack {
      node_version = "22-lts"
    }
  }

  tags = var.tags
}
```

**Note:** The `always_on` setting is disabled for Free tier (F1) because it's not supported.

---

### Action 14: Create modules/appservice/outputs.tf

**Location:** `02-intermediate/modules/appservice/outputs.tf`

Create this file inside the `modules/appservice` folder:

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

Your complete folder structure:

```
02-intermediate/
├── versions.tf
├── main.tf
├── variables.tf
├── outputs.tf
├── dev.tfvars
└── modules/
    └── appservice/
        ├── variables.tf
        ├── main.tf
        └── outputs.tf
```

---

## Part 5: Deploy with Remote State

### Action 15: Initialize Terraform

Replace `YOUR_STORAGE_ACCOUNT` with the storage account name from Action 4:

```powershell
terraform init -backend-config="resource_group_name=rg-tfstate" -backend-config="storage_account_name=YOUR_STORAGE_ACCOUNT" -backend-config="container_name=tfstate" -backend-config="key=dev/appservice.tfstate"
```

**Expected output:**

```
Initializing the backend...
Successfully configured the backend "azurerm"!

Initializing modules...
- appservice in modules\appservice

Terraform has been successfully initialized!
```

---

### Action 16: Validate Your Configuration

Check for syntax errors:

```powershell
terraform validate
```

If there are errors, review your files and fix them.

---

### Action 17: Plan the Deployment

**Before running plan, predict what Terraform will create:**

1. 1 Resource Group
2. 1 App Service Plan
3. 1 Linux Web App

Now run plan to verify:

```powershell
terraform plan -var-file="dev.tfvars"
```

Does the output match your prediction?

---

### Action 18: Apply the Configuration

Deploy the resources:

```powershell
terraform apply -var-file="dev.tfvars"
```

Type `yes` when prompted.

After completion, Terraform displays the outputs:

```
Outputs:

app_service_url = "https://tftraining-dev-app.azurewebsites.net"
resource_group_name = "rg-tftraining-dev"
```

Open the URL in your browser to verify the deployment.

---

## Part 6: Deploy Your Application

Now that the infrastructure is ready, let's deploy a simple landing page to your App Service!

### Action 19: Download the App Folder

The `app` folder contains a pre-built Node.js application. Download it to your workspace using one of these methods:

**Option A: Download from GitHub (Recommended)**

Download the files directly from the training repository:

```powershell
# Navigate to your workspace
cd "$env:USERPROFILE\Desktop\Terraform-Training-Workspace\02-intermediate"

# Create the app folder structure
New-Item -ItemType Directory -Path "app\public" -Force

# Download the application files
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/DFRZ7/TerraformTraining/main/02-intermediate/app/server.js" -OutFile "app\server.js"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/DFRZ7/TerraformTraining/main/02-intermediate/app/package.json" -OutFile "app\package.json"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/DFRZ7/TerraformTraining/main/02-intermediate/app/public/index.html" -OutFile "app\public\index.html"
```

**Option B: Copy from Cloned Repository**

If you already cloned the training repository locally:

```powershell
# Replace the path with where you cloned the repo
$RepoPath = "C:\Users\YourName\TerraformTraining"

# Copy the app folder to your workspace
Copy-Item -Path "$RepoPath\02-intermediate\app" -Destination "$env:USERPROFILE\Desktop\Terraform-Training-Workspace\02-intermediate\app" -Recurse
```

**Option C: Create Files Manually**

Create the files yourself. First, create the folder structure:

```powershell
cd "$env:USERPROFILE\Desktop\Terraform-Training-Workspace\02-intermediate"
New-Item -ItemType Directory -Path "app\public" -Force
```

Then create three files with the content provided by your instructor:

- `app/server.js`
- `app/package.json`
- `app/public/index.html`

---

**Verify the app folder structure:**

```powershell
Get-ChildItem -Path "app" -Recurse
```

You should see:

```
app/
├── server.js          # Native Node.js web server (no dependencies!)
├── package.json       # Node.js configuration
└── public/
    └── index.html     # Landing page (edit this!)
```

### Action 20: Deploy the Application

First, create a zip file of the application, then deploy it:

```powershell
# Make sure you're in the 02-intermediate folder
cd "$env:USERPROFILE\Desktop\Terraform-Training-Workspace\02-intermediate"

# Create a zip file from the app folder
Compress-Archive -Path "app\*" -DestinationPath "app.zip" -Force

# Deploy to App Service
az webapp deploy --resource-group rg-tftraining-dev --name tftraining-dev-app --src-path "app.zip" --type zip
```

Wait 1-2 minutes for the deployment to complete, then refresh your browser to see the landing page!

### Action 21: Customize Your Page (Student Exercise)

Open `app/public/index.html` in VS Code and make changes:

1. Change the greeting message
2. Update the colors
3. Add your name

Then redeploy:

```powershell
Compress-Archive -Path "app\*" -DestinationPath "app.zip" -Force
az webapp deploy --resource-group rg-tftraining-dev --name tftraining-dev-app --src-path "app.zip" --type zip
```

Refresh the browser to see your changes!

---

## Part 7: View Remote State

### Action 22: Check the State File in Azure

Verify that your state file is stored in Azure Storage. Replace `YOUR_STORAGE_ACCOUNT`:

```powershell
az storage blob list --account-name YOUR_STORAGE_ACCOUNT --container-name tfstate --auth-mode login --output table
```

You should see `dev/appservice.tfstate` listed.

### Action 23: View State Contents

You can view the state file contents with this command:

```powershell
terraform show
```

This displays all resources tracked in the state file.

---

## Part 8: Clean Up

### Action 24: Destroy Resources

Remove all resources created by Terraform:

```powershell
terraform destroy -var-file="dev.tfvars"
```

Type `yes` when prompted.

### Action 25: Delete State Storage (Optional)

If you no longer need the state storage:

```powershell
az group delete --name rg-tfstate --yes
```

---

## Summary

In this module, you learned:

| Concept          | What You Did                                         |
| ---------------- | ---------------------------------------------------- |
| **Remote State** | Stored state in Azure Storage with automatic locking |
| **Variables**    | Defined typed inputs with validation rules           |
| **Modules**      | Created a reusable App Service component             |
| **Environments** | Used tfvars files for environment-specific values    |
| **App Deploy**   | Deployed a custom landing page to App Service        |

---

## Key Commands Reference

| Command                                                     | Purpose                        |
| ----------------------------------------------------------- | ------------------------------ |
| `terraform init -backend-config=...`                        | Initialize with remote backend |
| `terraform validate`                                        | Check configuration syntax     |
| `terraform plan -var-file=dev.tfvars`                       | Preview changes                |
| `terraform apply -var-file=dev.tfvars`                      | Deploy resources               |
| `terraform show`                                            | View current state             |
| `terraform destroy -var-file=dev.tfvars`                    | Remove all resources           |
| `Compress-Archive -Path "app\*" -DestinationPath "app.zip"` | Create zip from app folder     |
| `az webapp deploy --src-path "app.zip" --type zip`          | Deploy app code to App Service |

---

## Troubleshooting

**Error: 403 Authorization Permission Mismatch**

- You need the Storage Blob Data Contributor role. See Action 3.

**Error: Backend configuration changed**

- Run `terraform init -reconfigure` to update the backend.

**Error: App Service Status shows Quota Exceeded**

- This could prevent the app service from running, we recommend to scale up or change region.

---

### Enabling Terraform Debug Logs

If you encounter unexpected errors, enable detailed logging to help diagnose the issue:

**Windows (PowerShell)**

Use the `$env:` prefix to set these for your current session:

```powershell
$env:TF_LOG="TRACE"
$env:TF_LOG_PATH="terraform-debug.log"
terraform plan
```

**Linux / macOS (Bash/Zsh)**

Use the `export` command to set them for your current session:

```bash
export TF_LOG="TRACE"
export TF_LOG_PATH="terraform-debug.log"
terraform plan
```

**One-Liner (Linux/macOS):** Run without changing your session permanently:

```bash
TF_LOG=TRACE TF_LOG_PATH=terraform-debug.log terraform plan
```

**Windows (Command Prompt / CMD)**

Use the `set` command:

```cmd
set TF_LOG=TRACE
set TF_LOG_PATH=terraform-debug.log
terraform plan
```

> **Tip:** After running, check the `terraform-debug.log` file in your working directory for detailed trace information.

---

**Version:** 1.0  
**Last Updated:** January 2026
