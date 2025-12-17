# Module 01: Terraform Basics

## Overview

This module introduces you to the fundamental Terraform workflow by deploying a simple Azure Resource Group.

**Duration:** 15 minutes

**Learning Objectives:**

- Understand Terraform configuration files
- Learn the Terraform workflow: init, fmt, validate, plan, apply, destroy
- Understand Terraform state

---

## File Structure

```
01-basics/
├── .gitignore          # Files to exclude from version control
├── main.tf             # Main Terraform configuration
└── README.md           # This file
```

---

## Understanding main.tf

Open `main.tf` and review the configuration:

### Terraform Block

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
  required_version = ">= 1.0"
}
```

This block:

- Declares required providers (azurerm for Azure)
- Specifies provider version constraints
- Sets minimum Terraform version

### Provider Block

```hcl
provider "azurerm" {
  features {}
}
```

This configures the Azure Resource Manager provider. The `features {}` block is required but can be empty for basic usage.

### Resource Block

```hcl
resource "azurerm_resource_group" "main" {
  name     = "rg-terraform-basics"
  location = "Central US"

  tags = {
    Environment = "Training"
    Module      = "01-basics"
    ManagedBy   = "Terraform"
  }
}
```

This creates an Azure Resource Group with:

- Resource type: `azurerm_resource_group`
- Local name: `main` (used to reference this resource)
- Azure name: `rg-terraform-basics`
- Location: `Central US`
- Tags for organization

---

## Hands-On Actions

### Action 1: Initialize Terraform

Navigate to this directory:

```powershell
cd "C:\Users\$env:USERNAME\Desktop\Terraform-Training-Workspace"
```

Initialize Terraform (downloads provider plugins):

```powershell
terraform init
```

**Expected Output:**

```
Initializing the backend...
Initializing provider plugins...
- Finding hashicorp/azurerm versions matching "~> 4.0"...
- Installing hashicorp/azurerm v4.x.x... (signed by HashiCorp)
Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

**What happened:**

- Created `.terraform/` directory (contains downloaded provider plugins and modules)
- Downloaded azurerm provider plugin
- Created `.terraform.lock.hcl` lock file (records exact provider versions for consistency)

**Understanding the files:**

- **`.terraform/` directory:** Contains the actual provider binaries and cached modules. Should be added to `.gitignore` as it can be regenerated with `terraform init`.
- **`.terraform.lock.hcl` file:** Records the exact provider versions and checksums selected during init. This ensures all team members use the same provider versions. Should be committed to version control.

---

### Action 2: Validate Configuration

Check if your configuration is syntactically valid:

```powershell
terraform validate
```

**Expected Output:**

```
Success! The configuration is valid.
```

---

### Action 3: Set Azure Subscription and Tenant

Configure your Azure subscription and tenant for Terraform authentication:

```powershell
$env:ARM_SUBSCRIPTION_ID = "<sub-id>"
$env:ARM_TENANT_ID = "<tenant-id>"  # Optional but helpful with multi-tenant scenarios
```

**Note:** Replace `<sub-id>` and `<tenant-id>` with your actual Azure subscription ID and tenant ID.

To find your subscription ID:

```powershell
az account show --query id --output tsv
```

To find your tenant ID:

```powershell
az account show --query tenantId --output tsv
```

---

### Action 4: Plan the Changes

Preview what Terraform will do:

```powershell
terraform plan
```

**Expected Output:**

Terraform plan shows what will be **created**, **changed**, or **destroyed**:

```
Terraform will perform the following actions:

  # azurerm_resource_group.main will be created
  + resource "azurerm_resource_group" "main" {
      + id       = (known after apply)
      + location = "centralus"
      + name     = "rg-terraform-basics"
      + tags     = {
          + "Environment" = "Training"
          + "ManagedBy"   = "Terraform"
          + "Module"      = "01-basics"
        }
    }

Plan: 1 to add, 0 to change, 0 to destroy.
```

> **Note:** You didn't use the -out option to save this plan, so Terraform can't guarantee to take exactly these actions if you run "terraform apply" now.

This note reminds you that the plan is not saved. We'll cover using the `-out` option in later modules.

**Key Points:**

- `+` means resource will be created
- `~` means resource will be modified in-place
- `-/+` means resource will be destroyed and recreated
- `-` means resource will be destroyed
- `(known after apply)` means the value is determined during creation
- No actual changes are made during plan—it's a preview only

---

### Action 5: Apply the Configuration

Create the resources:

```powershell
terraform apply
```

You will be prompted to confirm:

```
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value:
```

Type `yes` and press Enter.

**Expected Output:**

```
azurerm_resource_group.main: Creating...
azurerm_resource_group.main: Creation complete after 2s [id=/subscriptions/...]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

---

### Action 6: Verify in Azure Portal

Open the Azure Portal and verify:

1. Navigate to Resource Groups
2. Find `rg-terraform-basics`
3. Check the tags

Or use Azure CLI:

```powershell
az group show --name rg-terraform-basics --output table
```

**Expected Output:**

```
Location    Name
----------  -------------------
centralus   rg-terraform-basics
```

---

### Action 7: Examine Terraform State

Terraform tracks your infrastructure in a state file:

```powershell
terraform show
```

This displays the current state of your infrastructure.

**Expected Output:**

```hcl
# azurerm_resource_group.main:
resource "azurerm_resource_group" "main" {
    id         = "/subscriptions/********-****-****-****-************/resourceGroups/rg-terraform-basics"
    location   = "centralus"
    managed_by = null
    name       = "rg-terraform-basics"
    tags       = {
        "Environment" = "Training"
        "ManagedBy"   = "Terraform"
        "Module"      = "01-basics"
    }
}
```

**View state file directly (not recommended for editing):**

```powershell
Get-Content terraform.tfstate
```

**Key Points:**

- State file is JSON format
- Contains sensitive information
- Should not be manually edited
- Must be secured and backed up

---

### Action 8: Make a Change

Edit `main.tf` and add a new tag:

```hcl
tags = {
  Environment = "Training"
  Module      = "01-basics"
  ManagedBy   = "Terraform"
  Updated     = "Yes"  # Add this new tag
}
```

Run plan again:

```powershell
terraform plan
```

Notice Terraform detects the change:

```
# azurerm_resource_group.main will be updated in-place
  ~ resource "azurerm_resource_group" "main" {
      ~ tags     = {
          + "Updated"     = "Yes"
            # (3 unchanged elements hidden)
        }
    }

Plan: 0 to add, 1 to change, 0 to destroy.
```

Apply the change:

```powershell
terraform apply
```

**Verify the tag update:**

Check in the Azure Portal that the new `Updated` tag appears, or use Azure CLI:

```powershell
az group show --name rg-terraform-basics --query tags --output json
```

**Expected Output:**

```json
{
  "Environment": "Training",
  "ManagedBy": "Terraform",
  "Module": "01-basics",
  "Updated": "Yes"
}
```

---

### Action 9: Clean Up Resources

Destroy the infrastructure:

```powershell
terraform destroy
```

Confirm with `yes` when prompted.

**Expected Output:**

```
azurerm_resource_group.main: Destroying... [id=/subscriptions/...]
azurerm_resource_group.main: Destruction complete after 45s

Destroy complete! Resources: 1 destroyed.
```

**Verify the resource is deleted:**

Check in the Azure Portal that `rg-terraform-basics` no longer exists, or use Azure CLI:

```powershell
az group show --name rg-terraform-basics
```

**Expected Output:**

```
ResourceGroupNotFound: Resource group 'rg-terraform-basics' could not be found.
```

---

## Key Concepts Learned

### Terraform Workflow

1. **Write:** Create `.tf` configuration files
2. **Initialize:** `terraform init` downloads providers
3. **Validate:** `terraform validate` checks syntax
4. **Plan:** `terraform plan` previews changes
5. **Apply:** `terraform apply` creates/updates resources
6. **Destroy:** `terraform destroy` removes resources

### State Management

- Terraform stores infrastructure state in `terraform.tfstate`
- State maps configuration to real resources
- State contains sensitive data
- Never manually edit state files
- Always back up state files

### Idempotency

- Running `terraform apply` multiple times with the same configuration produces the same result
- Terraform only makes changes when configuration differs from state

---

## Common Commands Reference

| Command              | Purpose                        |
| -------------------- | ------------------------------ |
| `terraform init`     | Initialize working directory   |
| `terraform validate` | Validate configuration syntax  |
| `terraform plan`     | Preview changes                |
| `terraform apply`    | Apply changes                  |
| `terraform destroy`  | Destroy managed infrastructure |
| `terraform show`     | Show current state             |

---

## Best Practices

1. Always run `terraform plan` before `terraform apply`
2. Review plans carefully before applying
3. Use version control for `.tf` files
4. Never commit `.tfstate` files to version control
5. Use meaningful resource names and tags
