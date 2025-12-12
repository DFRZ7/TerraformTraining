# Module 00: Prerequisites and Installation

## Overview

This module covers the installation and configuration of required tools for Terraform development with Azure.

**Duration:** 10 minutes

## Prerequisites

**PowerShell Required:** All commands in this training will be executed using PowerShell. Ensure you have PowerShell 5.1 or later installed on your Windows system. You can verify your PowerShell version by running:

```powershell
$PSVersionTable.PSVersion
```

## Required Tools

### 1. Terraform

**Windows Installation:**

Option A: Using Chocolatey (recommended)

```powershell
# Run PowerShell as Administrator
choco install terraform
```

**Note:** Chocolatey commands must be run in an elevated PowerShell session (Run as Administrator).

Option B: Manual Installation

1. Download Terraform for Windows from the official HashiCorp site:
   https://developer.hashicorp.com/terraform/install#windows

2. Extract the zip file to a directory (e.g., `C:\terraform`)

   - Right-click the downloaded zip file
   - Select "Extract All..."
   - Choose or create the destination folder (e.g., `C:\terraform`)

3. Add the directory to your PATH environment variable:

   - Open System Properties (Windows Key + Pause/Break or search "Environment Variables")
   - Click "Environment Variables" button
   - Under "System variables", find and select "Path"
   - Click "Edit"
   - Click "New"
   - Add the full path to your Terraform directory (e.g., `C:\terraform`)
   - Click "OK" on all dialogs

4. Restart your terminal to apply PATH changes

**Verify Installation:**

```powershell
terraform version
```

Expected output:

```
Terraform v1.13.x
```

---

### 2. Azure CLI

**Windows Installation:**

Follow the official Microsoft documentation for the latest installation methods:
https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-windows?view=azure-cli-latest&pivots=winget

**Verify Installation:**

```powershell
az --version
```

Expected output:

```
azure-cli                         2.x.x
```

---

### 3. Text Editor

**Recommended:** Visual Studio Code with Terraform extension

**Install VS Code:**
Download from https://code.visualstudio.com/

**Install Terraform Extensions:**

1. Open VS Code
2. Go to Extensions (Ctrl+Shift+X)
3. Install the following verified extensions:
   - **HashiCorp Terraform** - Syntax highlighting and autocompletion for Terraform
   - **Microsoft Terraform (Preview)** - VS Code extension for developing with Terraform on Azure

**Note:** Keep these extensions updated regularly to ensure compatibility with the latest Terraform features and Azure resources.

---

## Azure Authentication

### Step 1: Sign in to Azure

```powershell
az login --tenant <tenant-id>
```

This will open your default browser for authentication. Sign in with your Azure credentials and select the subscription you want to work with.

### Step 2: Verify Your Subscription

```powershell
az account show
```

Expected output includes:

```json
{
  "environmentName": "AzureCloud",
  "homeTenantId": "248157a9-03g9--------------",
  "id": "2134abca-d19c--------------",
  "isDefault": true,
  "managedByTenants": [],
  "name": "TEST-PROD",
  "state": "Enabled",
  "tenantId": "248157a9-03g9--------------",
  "user": {
    "name": "user@test.com",
    "type": "user"
  }
}
```

### Step 3: Set Default Subscription (if needed)

You can also run this command if you want to work with another subscription:

```powershell
az account set --subscription "<subscription ID or name>"
```

---

## Create Working Directory

Create a directory for this training:

```powershell
cd C:\Users\$env:USERNAME\Desktop
mkdir "Terraform-Training-Workspace"
cd Terraform-Training-Workspace
```

---

## Verify Everything Works

Run the following commands to ensure everything is set up correctly:

```powershell
# Check Terraform
terraform version

# Check Azure CLI
az --version

# Check Azure authentication
az account show

# Check you can query Azure resources
az group list --output table
```
