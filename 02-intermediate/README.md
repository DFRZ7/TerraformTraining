# Module 02: Remote State, Variables, and Modules

## Overview

This module teaches advanced Terraform concepts by deploying an Azure App Service (Linux) that displays a "Hi, this is your Terraform training" message.

**Duration:** 45-60 minutes

**Learning Objectives:**

- Understand and configure Terraform remote state with Azure Storage backend
- Learn about state locking and collaboration benefits
- Define variables with types, descriptions, and validation
- Create and use reusable Terraform modules
- Apply lifecycle rules and best practices
- Deploy a real application to Azure App Service

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              Azure Subscription                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                    Resource Group: rg-tftraining-{env}               │    │
│  │                                                                      │    │
│  │   ┌────────────────────────┐    ┌────────────────────────────────┐  │    │
│  │   │   App Service Plan     │    │       Linux Web App            │  │    │
│  │   │   asp-tftraining-...   │───▶│   tftraining-webapp-{env}      │  │    │
│  │   │   (Linux, SKU: F1/B1)  │    │   - Node.js 18 LTS             │  │    │
│  │   └────────────────────────┘    │   - Managed Identity           │  │    │
│  │                                  │   - HTTPS Only                 │  │    │
│  │                                  └────────────────────────────────┘  │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                Resource Group: rg-tfstate-{env} (Separate)           │    │
│  │                                                                      │    │
│  │   ┌────────────────────────────────────────────────────────────┐    │    │
│  │   │              Storage Account: sttfstate{unique}             │    │    │
│  │   │                                                             │    │    │
│  │   │   ┌─────────────────────────────────────────────────┐      │    │    │
│  │   │   │         Container: tfstate                       │      │    │    │
│  │   │   │                                                  │      │    │    │
│  │   │   │   📄 dev/appservice.tfstate                      │      │    │    │
│  │   │   │   📄 test/appservice.tfstate                     │      │    │    │
│  │   │   │   📄 prod/appservice.tfstate                     │      │    │    │
│  │   │   │                                                  │      │    │    │
│  │   │   │   Features:                                      │      │    │    │
│  │   │   │   ✓ Soft Delete (7 days)                         │      │    │    │
│  │   │   │   ✓ Blob Versioning                              │      │    │    │
│  │   │   │   ✓ State Locking                                │      │    │    │
│  │   │   └─────────────────────────────────────────────────┘      │    │    │
│  │   └────────────────────────────────────────────────────────────┘    │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────────┘

           │
           │  Terraform
           │  Operations
           ▼
    ┌─────────────────┐
    │   Developer     │
    │   Workstation   │
    │                 │
    │  terraform init │
    │  terraform plan │
    │  terraform apply│
    └─────────────────┘
```

---

## File Structure

```
module-02/
├── main.tf                 # Main configuration with backend and resources
├── variables.tf            # Input variable definitions with validation
├── outputs.tf              # Output values
├── versions.tf             # Terraform and provider version constraints
├── terraform.tfvars.example # Example variables file
├── dev.tfvars              # Development environment variables
├── test.tfvars             # Test environment variables
├── .gitignore              # Git ignore patterns
├── README.md               # This file
│
├── scripts/
│   └── bootstrap-remote-state.sh  # Bootstrap script for state storage
│
├── modules/
│   └── appservice/
│       ├── main.tf         # App Service Plan + Linux Web App
│       ├── variables.tf    # Module input variables
│       └── outputs.tf      # Module outputs
│
└── app/
    ├── package.json        # Node.js dependencies
    ├── server.js           # Express.js application
    └── README.md           # App documentation
```

---

## Prerequisites

Before starting this module, ensure you have:

1. ✅ Completed Module 00 (Prerequisites) and Module 01 (Basics)
2. ✅ Terraform installed (v1.0+)
3. ✅ Azure CLI installed and authenticated (`az login`)
4. ✅ Azure subscription with permissions to create resources
5. ✅ PowerShell (Windows) or Bash (Linux/Mac)

Set your Azure subscription:

```powershell
$env:ARM_SUBSCRIPTION_ID = "<your-subscription-id>"
$env:ARM_TENANT_ID = "<your-tenant-id>"
```

---

## Why Remote State?

### Local State Problems

In Module 01, Terraform stored state in a local file (`terraform.tfstate`). This works for learning but has problems:

| Problem              | Impact                                   |
| -------------------- | ---------------------------------------- |
| **No Collaboration** | Team members can't share state           |
| **No Locking**       | Concurrent runs can corrupt state        |
| **No Backup**        | State loss = lost infrastructure mapping |
| **Secrets Exposure** | State contains sensitive data on disk    |

### Remote State Benefits

| Benefit                | Description                                 |
| ---------------------- | ------------------------------------------- |
| **Team Collaboration** | Shared state accessible to all team members |
| **State Locking**      | Prevents concurrent modifications           |
| **Versioning**         | Azure Storage blob versioning for history   |
| **Soft Delete**        | Recover accidentally deleted state          |
| **Security**           | State encrypted at rest, access controlled  |

---

## Hands-On Actions

### Step 1: Understand Local State First (5 minutes)

Before migrating to remote state, let's observe local state behavior.

Navigate to module-02:

```powershell
cd "c:\Users\$env:USERNAME\Desktop\TerraformPresentationCXP\TerraformTraining\module-02"
```

Initialize with local backend (temporary):

```powershell
# Comment out the backend block in main.tf first, then:
terraform init
```

Run a plan and notice the local state file:

```powershell
terraform plan -var-file="dev.tfvars"
```

**Observation:** Terraform creates `terraform.tfstate` locally. This is what we'll migrate.

---

### Step 2: Bootstrap Remote State Storage (10 minutes)

Create the Azure Storage account for remote state:

**Option A: Using the Bootstrap Script (Recommended)**

```powershell
# Set environment variables
$env:RG = "rg-tfstate-dev"
$env:SA = "sttfstatedev$(Get-Random -Maximum 99999)"  # Must be globally unique
$env:CONTAINER = "tfstate"
$env:LOCATION = "centralus"

# Run the bootstrap script (Git Bash or WSL)
bash ./scripts/bootstrap-remote-state.sh

# Or using PowerShell equivalent commands:
az group create --name $env:RG --location $env:LOCATION

az storage account create `
  --name $env:SA `
  --resource-group $env:RG `
  --location $env:LOCATION `
  --sku Standard_LRS `
  --kind StorageV2 `
  --https-only true `
  --min-tls-version TLS1_2 `
  --allow-blob-public-access false

az storage account blob-service-properties update `
  --account-name $env:SA `
  --resource-group $env:RG `
  --enable-delete-retention true `
  --delete-retention-days 7 `
  --enable-versioning true

$key = az storage account keys list --account-name $env:SA --resource-group $env:RG --query '[0].value' -o tsv

az storage container create `
  --name $env:CONTAINER `
  --account-name $env:SA `
  --account-key $key
```

**Save the output values!** You'll need them for `terraform init`.

---

### Step 3: Initialize with Remote Backend (10 minutes)

Ensure the backend block in `main.tf` is uncommented, then initialize:

```powershell
terraform init `
  -backend-config="resource_group_name=$env:RG" `
  -backend-config="storage_account_name=$env:SA" `
  -backend-config="container_name=$env:CONTAINER" `
  -backend-config="key=dev/appservice.tfstate"
```

**Expected Output:**

```
Initializing the backend...

Successfully configured the backend "azurerm"! Terraform will automatically
use this backend unless the backend configuration changes.
```

**If migrating from local state**, Terraform will ask:

```
Do you want to copy existing state to the new backend?
  Enter "yes" to copy and "no" to start with an empty state.
```

Type `yes` to migrate existing state.

---

### Step 4: Explore Variables and Validation (10 minutes)

Open `variables.tf` and review the variable definitions:

```hcl
variable "appservice_plan_sku" {
  description = "SKU for the App Service Plan"
  type        = string
  default     = "F1"

  validation {
    condition     = contains(["F1", "B1", "B2", "S1", "S2"], var.appservice_plan_sku)
    error_message = "SKU must be one of: F1, B1, B2, S1, S2."
  }
}
```

**Test Validation:**

```powershell
# This should fail validation
terraform plan -var="appservice_plan_sku=INVALID" -var-file="dev.tfvars"
```

**Expected Error:**

```
Error: Invalid value for variable

  on variables.tf line X:
  X: variable "appservice_plan_sku" {

SKU must be one of: F1, B1, B2, S1, S2.
```

---

### Step 5: Predict → Plan → Apply (15 minutes)

**Predict:** Before running plan, write down what you expect Terraform to create:

1. Resource Group: `rg-tftraining-dev`
2. App Service Plan: `asp-tftraining-webapp-dev`
3. Linux Web App: `tftraining-webapp-dev`

**Plan:**

```powershell
terraform plan -var-file="dev.tfvars"
```

Review the plan output. Does it match your predictions?

**Apply:**

```powershell
terraform apply -var-file="dev.tfvars"
```

Type `yes` when prompted.

**Verify the deployment:**

```powershell
# Get the output URL
terraform output app_service_url
```

Open the URL in your browser. You should see "Hi, this is your Terraform training"!

---

### Step 6: Understanding State Locking (5 minutes)

When you run `terraform apply`, Terraform acquires a lock on the state file:

1. Open a second terminal
2. Try running `terraform plan` while an apply is in progress
3. You'll see a lock message:

```
Error: Error locking state: Error acquiring the state lock
```

This prevents team members from corrupting state with concurrent operations.

**View the lock in Azure:**

```powershell
# List blobs in the container (you'll see .tfstate and potentially .tflock files)
az storage blob list `
  --account-name $env:SA `
  --container-name $env:CONTAINER `
  --output table
```

---

### Step 7: Deploy Sample Application (Optional, 10 minutes)

To deploy the sample Node.js app:

```powershell
terraform apply -var-file="dev.tfvars" -var="deploy_sample_app=true"
```

Or update `dev.tfvars`:

```hcl
deploy_sample_app = true
```

Then apply:

```powershell
terraform apply -var-file="dev.tfvars"
```

Visit the app URL to see the styled welcome page!

---

### Step 8: Switch Environments (5 minutes)

To deploy to a different environment, use a different tfvars file and state key:

**Test Environment:**

```powershell
# Re-initialize with test state key
terraform init -reconfigure `
  -backend-config="resource_group_name=$env:RG" `
  -backend-config="storage_account_name=$env:SA" `
  -backend-config="container_name=$env:CONTAINER" `
  -backend-config="key=test/appservice.tfstate"

# Plan and apply with test variables
terraform plan -var-file="test.tfvars"
terraform apply -var-file="test.tfvars"
```

**Strategy:** Each environment has its own:

- State file key: `{env}/appservice.tfstate`
- Variables file: `{env}.tfvars`
- Resources with environment suffix

---

### Step 9: Make a Change and Observe (5 minutes)

Change the App Service SKU in `dev.tfvars`:

```hcl
appservice_plan_sku = "B1"
```

**Predict:** What will happen?

Run plan:

```powershell
terraform plan -var-file="dev.tfvars"
```

You'll see the App Service Plan will be updated in-place:

```
# module.appservice.azurerm_service_plan.main will be updated in-place
~ resource "azurerm_service_plan" "main" {
    ~ sku_name            = "F1" -> "B1"
      # (other attributes unchanged)
  }
```

---

### Step 10: Clean Up (5 minutes)

Destroy the dev environment:

```powershell
terraform destroy -var-file="dev.tfvars"
```

Type `yes` when prompted.

**Optional:** Clean up the state storage (if no longer needed):

```powershell
az group delete --name $env:RG --yes --no-wait
```

---

## Key Concepts Summary

### Remote State

| Concept        | Description                                  |
| -------------- | -------------------------------------------- |
| **Backend**    | Where Terraform stores state (Azure Storage) |
| **Locking**    | Prevents concurrent modifications            |
| **Versioning** | Blob versioning for state history            |
| **Keys**       | Unique path per environment/project          |

### Variables

| Feature        | Purpose                                   |
| -------------- | ----------------------------------------- |
| **Types**      | `string`, `number`, `bool`, `list`, `map` |
| **Defaults**   | Optional values when not specified        |
| **Validation** | Ensure inputs meet requirements           |
| **Sensitive**  | Mark variables containing secrets         |

### Modules

| Concept         | Description                         |
| --------------- | ----------------------------------- |
| **Source**      | Location of module code             |
| **Inputs**      | Variables passed to module          |
| **Outputs**     | Values exposed by module            |
| **Reusability** | Same module, different environments |

---

## Lifecycle Rules

The module demonstrates `lifecycle` rules:

```hcl
lifecycle {
  prevent_destroy = true  # Prevent accidental deletion
  ignore_changes = [...]  # Ignore external changes
}
```

**Use Cases:**

- `prevent_destroy`: Protect production databases
- `ignore_changes`: Ignore tags modified outside Terraform
- `create_before_destroy`: Zero-downtime replacements

---

## App Deployment: Terraform vs CI/CD

| Approach      | Pros                                | Cons                          |
| ------------- | ----------------------------------- | ----------------------------- |
| **Terraform** | Single tool, good for demos         | Couples infra + app lifecycle |
| **CI/CD**     | Separate concerns, frequent updates | Additional tooling required   |

**Recommendation:** Use Terraform for infrastructure, CI/CD pipelines for application code.

---

## Common Commands Reference

| Command                                  | Purpose                          |
| ---------------------------------------- | -------------------------------- |
| `terraform init -backend-config=...`     | Initialize with remote backend   |
| `terraform init -migrate-state`          | Migrate state to new backend     |
| `terraform plan -var-file=dev.tfvars`    | Plan with environment variables  |
| `terraform apply -var-file=dev.tfvars`   | Apply with environment variables |
| `terraform output`                       | Show output values               |
| `terraform state list`                   | List resources in state          |
| `terraform destroy -var-file=dev.tfvars` | Destroy environment              |

---

## Troubleshooting

### Backend Initialization Errors

**Error:** `Error configuring the backend "azurerm"`

**Solution:** Verify storage account exists and credentials are correct:

```powershell
az storage account show --name $env:SA --resource-group $env:RG
```

### State Lock Errors

**Error:** `Error acquiring the state lock`

**Solution:** Wait for other operations to complete, or force-unlock (use with caution):

```powershell
terraform force-unlock LOCK_ID
```

### Module Not Found

**Error:** `Module not found`

**Solution:** Ensure the module path is correct and run `terraform init`:

```powershell
terraform init -upgrade
```

---

## Best Practices

1. ✅ **Always use remote state** for team environments
2. ✅ **Separate state per environment** using unique keys
3. ✅ **Never commit tfvars with secrets** to version control
4. ✅ **Use variable validation** to catch errors early
5. ✅ **Tag all resources** consistently
6. ✅ **Use modules** for reusable infrastructure patterns
7. ✅ **Review plans carefully** before applying

---

## If You Use GitHub Copilot

> 💡 **Think First, Prompt Second**
>
> Before asking Copilot to generate Terraform code:
>
> 1. **Understand the resource** - What Azure resource are you creating?
> 2. **Know the required arguments** - Check the provider documentation
> 3. **Consider dependencies** - What resources must exist first?
> 4. **Plan for environments** - How will this vary across dev/test/prod?
>
> **Good Prompt:** "Create a Terraform module for Azure App Service with inputs for name, SKU, and runtime stack, following the azurerm provider 4.x syntax"
>
> **Bad Prompt:** "Make me an app service"
>
> Always **validate generated code** against the [Terraform Azure Provider docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs).

---

## Next Steps

After completing this module, you're ready for:

- **Module 03:** Data sources and dependencies
- **Module 04:** Workspaces and environment management
- **Module 05:** CI/CD integration with GitHub Actions

---

**Version:** 1.0  
**Last Updated:** January 2026
