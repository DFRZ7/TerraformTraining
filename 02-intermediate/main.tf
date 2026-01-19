# =============================================================================
# Module 02: Remote State, Variables, and Modules
# =============================================================================
# This module demonstrates:
#   - Remote state storage with Azure Storage backend
#   - Input variables with validation
#   - Reusable Terraform modules
#   - Deploying Azure App Service (Linux)
# =============================================================================

# -----------------------------------------------------------------------------
# Backend Configuration - Azure Storage
# -----------------------------------------------------------------------------
# The backend block cannot use variables directly. Use -backend-config flags
# during terraform init to provide environment-specific values.
#
# IMPORTANT: Run the bootstrap script first to create the storage account:
#   ./scripts/bootstrap-remote-state.sh
#
# Initialize with backend configuration:
#   terraform init \
#     -backend-config="resource_group_name=rg-tfstate-dev" \
#     -backend-config="storage_account_name=sttfstatedev12345" \
#     -backend-config="container_name=tfstate" \
#     -backend-config="key=dev/appservice.tfstate"
#
# For different environments, change the key:
#   - dev:  key=dev/appservice.tfstate
#   - test: key=test/appservice.tfstate
#   - prod: key=prod/appservice.tfstate
# -----------------------------------------------------------------------------

terraform {
  backend "azurerm" {
    # Values provided via -backend-config during init
    # resource_group_name  = "rg-tfstate"
    # storage_account_name = "sttfstate"
    # container_name       = "tfstate"
    # key                  = "env/appservice.tfstate"
  }
}

# -----------------------------------------------------------------------------
# Provider Configuration
# -----------------------------------------------------------------------------

provider "azurerm" {
  features {
    # Recommended: Prevent accidental deletion of resource groups with resources
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# -----------------------------------------------------------------------------
# Local Values
# -----------------------------------------------------------------------------
# Computed values used throughout the configuration

locals {
  # Resource naming convention: {project}-{resource}-{environment}
  resource_prefix = "${var.project_name}-${var.environment}"

  # Full web app name (must be globally unique)
  webapp_name = "${var.project_name}-${var.app_name}-${var.environment}"

  # Common tags applied to all resources
  common_tags = merge(
    {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
      Module      = "02-remote-state"
      Owner       = var.owner
      CostCenter  = var.cost_center
    },
    var.additional_tags
  )
}

# -----------------------------------------------------------------------------
# Resource Group
# -----------------------------------------------------------------------------
# All resources for this deployment are contained in a single resource group.
# This follows the principle of grouping resources by lifecycle.

resource "azurerm_resource_group" "main" {
  name     = "rg-${local.resource_prefix}"
  location = var.location

  tags = local.common_tags

  # Lifecycle example: Prevent accidental deletion
  # Uncomment the following block to protect the resource group from deletion.
  # This is useful for production environments where data loss is critical.
  # 
  # lifecycle {
  #   prevent_destroy = true
  # }
}

# -----------------------------------------------------------------------------
# App Service Module
# -----------------------------------------------------------------------------
# Using a reusable module for the App Service deployment.
# Modules encapsulate resources and can be shared across configurations.

module "appservice" {
  source = "./modules/appservice"

  app_name                = local.webapp_name
  resource_group_name     = azurerm_resource_group.main.name
  location                = azurerm_resource_group.main.location
  appservice_plan_sku     = var.appservice_plan_sku
  runtime_stack           = var.runtime_stack
  app_settings            = var.app_settings
  enable_managed_identity = var.enable_managed_identity
  tags                    = local.common_tags
}

# -----------------------------------------------------------------------------
# Sample App Deployment (Optional)
# -----------------------------------------------------------------------------
# This null_resource deploys the sample Node.js application to the web app.
# It is conditional on the deploy_sample_app variable.
#
# PROS of deploying via Terraform:
#   - Single command for infrastructure + app
#   - Good for demos and training
#   - Ensures app is deployed with infra
#
# CONS of deploying via Terraform:
#   - Couples infrastructure and application lifecycles
#   - Not suitable for frequent app updates
#   - Better handled by CI/CD pipelines (GitHub Actions, Azure DevOps)
#
# RECOMMENDATION: Use Terraform for infrastructure, CI/CD for application code.

resource "null_resource" "deploy_sample_app" {
  count = var.deploy_sample_app ? 1 : 0

  # Re-deploy when the web app ID changes (e.g., after recreation)
  triggers = {
    webapp_id = module.appservice.webapp_id
  }

  # Wait for the web app to be fully provisioned
  depends_on = [module.appservice]

  provisioner "local-exec" {
    # PowerShell command for Windows; adjust path for cross-platform
    command = <<-EOT
      Write-Host "Deploying sample app to ${module.appservice.default_hostname}..."
      
      # Navigate to app directory and create zip
      $appPath = "${path.module}/app"
      $zipPath = "${path.module}/app.zip"
      
      if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
      
      Compress-Archive -Path "$appPath/*" -DestinationPath $zipPath -Force
      
      # Deploy using Azure CLI
      az webapp deploy `
        --resource-group "${azurerm_resource_group.main.name}" `
        --name "${local.webapp_name}" `
        --src-path $zipPath `
        --type zip `
        --async true
      
      Write-Host "Deployment initiated. Visit: https://${module.appservice.default_hostname}"
    EOT

    interpreter = ["pwsh", "-Command"]
  }
}
