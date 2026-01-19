# =============================================================================
# App Service Module: Main Configuration
# =============================================================================
# This module creates an Azure App Service Plan (Linux) and Linux Web App.
# It encapsulates the resources for reusability across environments.
# =============================================================================

# -----------------------------------------------------------------------------
# App Service Plan (Linux)
# -----------------------------------------------------------------------------
# The App Service Plan defines the compute resources for the web app.
# Linux plans use a different SKU naming than Windows.

resource "azurerm_service_plan" "main" {
  name                = "asp-${var.app_name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = var.appservice_plan_sku

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Linux Web App
# -----------------------------------------------------------------------------
# The Linux Web App runs your application code on the App Service Plan.

resource "azurerm_linux_web_app" "main" {
  name                = var.app_name
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.main.id

  # Enable HTTPS only for security
  https_only = true

  # Site configuration
  site_config {
    # Configure the runtime stack
    application_stack {
      # Parse runtime stack (e.g., "NODE|18-lts" -> node_version = "18-lts")
      node_version   = local.is_node ? local.runtime_version : null
      python_version = local.is_python ? local.runtime_version : null
      dotnet_version = local.is_dotnet ? local.runtime_version : null
      java_version   = local.is_java ? local.runtime_version : null
    }

    # Always on keeps the app warm (not available on Free tier)
    always_on = var.appservice_plan_sku != "F1"

    # Enable HTTP/2 for better performance
    http2_enabled = true
  }

  # Application settings (environment variables)
  app_settings = var.app_settings

  # Managed Identity configuration
  dynamic "identity" {
    for_each = var.enable_managed_identity ? [1] : []
    content {
      type = "SystemAssigned"
    }
  }

  tags = var.tags

  # Lifecycle configuration
  # Ignore changes to app_settings that might be modified outside Terraform
  # (e.g., by deployment slots or Azure DevOps)
  lifecycle {
    ignore_changes = [
      # Uncomment if using deployment slots or external config management
      # app_settings["WEBSITE_RUN_FROM_PACKAGE"],
    ]
  }
}

# -----------------------------------------------------------------------------
# Local Values for Runtime Stack Parsing
# -----------------------------------------------------------------------------
# Parse the runtime_stack variable (e.g., "NODE|18-lts") into components.

locals {
  runtime_parts   = split("|", var.runtime_stack)
  runtime_name    = upper(local.runtime_parts[0])
  runtime_version = local.runtime_parts[1]

  # Determine which runtime to configure
  is_node   = local.runtime_name == "NODE"
  is_python = local.runtime_name == "PYTHON"
  is_dotnet = local.runtime_name == "DOTNETCORE"
  is_java   = local.runtime_name == "JAVA"
}
