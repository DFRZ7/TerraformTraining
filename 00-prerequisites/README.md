# Module 00: Prerequisites and Installation

## Overview

This module covers the installation and configuration of required tools for Terraform development with Azure.

**Duration:** 15-20 minutes

## Prerequisites

**PowerShell Required:** All commands in this training will be executed using PowerShell **running as Administrator**. Ensure you have PowerShell 5.1 or later installed on your Windows system.

**How to run PowerShell as Administrator:**

1. Press the Windows key
2. Type "PowerShell"
3. Right-click on "Windows PowerShell"
4. Select "Run as administrator"

You can verify your PowerShell version by running:

```powershell
$PSVersionTable.PSVersion
```

> **Troubleshooting Tip:** If a command is not working as expected, close the terminal, open a new PowerShell window as Administrator, and try the command again.

## Required Tools

### 1. Terraform

**Windows Installation (Manual):**

1. Download Terraform for Windows **AMD64** from the official HashiCorp site:
   https://developer.hashicorp.com/terraform/install#windows

   - Select the **AMD64** version for 64-bit Windows systems

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
Terraform v1.14.x
```

---

### 2. Azure CLI

**Windows Installation:**

Download and install the **Azure CLI MSI installer (64-bit)** from the official Microsoft documentation:
https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-windows?view=azure-cli-latest&pivots=msi

- Select the **64-bit MSI** option for your Windows system
- Run the installer and follow the prompts

**Verify Installation:**

```powershell
az --version
```

Expected output:

```
azure-cli                         2.81.x
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
