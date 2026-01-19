# =============================================================================
# Module 02: Variables
# =============================================================================
# This file defines all input variables for the configuration.
# Variables allow customization without modifying the core configuration.
# =============================================================================

# -----------------------------------------------------------------------------
# General Settings
# -----------------------------------------------------------------------------

variable "environment" {
  description = "Environment name (e.g., dev, test, prod). Used for naming and tagging resources."
  type        = string

  validation {
    condition     = contains(["dev", "test", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, test, staging, prod."
  }
}

variable "location" {
  description = "Azure region where resources will be deployed."
  type        = string
  default     = "Central US"
}

variable "project_name" {
  description = "Name of the project. Used as a prefix for resource names."
  type        = string
  default     = "tftraining"

  validation {
    condition     = can(regex("^[a-z0-9]{3,15}$", var.project_name))
    error_message = "Project name must be 3-15 lowercase alphanumeric characters."
  }
}

# -----------------------------------------------------------------------------
# App Service Configuration
# -----------------------------------------------------------------------------

variable "app_name" {
  description = "Name of the web application. Will be combined with environment for the full name."
  type        = string
  default     = "webapp"

  validation {
    condition     = can(regex("^[a-z0-9-]{2,20}$", var.app_name))
    error_message = "App name must be 2-20 lowercase alphanumeric characters or hyphens."
  }
}

variable "appservice_plan_sku" {
  description = "SKU for the App Service Plan. F1=Free, B1/B2=Basic, S1/S2=Standard."
  type        = string
  default     = "F1"

  validation {
    condition     = contains(["F1", "B1", "B2", "B3", "S1", "S2", "S3", "P1v2", "P2v2", "P3v2"], var.appservice_plan_sku)
    error_message = "SKU must be one of: F1, B1, B2, B3, S1, S2, S3, P1v2, P2v2, P3v2."
  }
}

variable "runtime_stack" {
  description = "Runtime stack for the web app (e.g., NODE|18-lts, PYTHON|3.11, DOTNETCORE|8.0)."
  type        = string
  default     = "NODE|18-lts"

  validation {
    condition     = can(regex("^[A-Z]+\\|[a-z0-9.-]+$", var.runtime_stack))
    error_message = "Runtime stack must be in format RUNTIME|VERSION (e.g., NODE|18-lts)."
  }
}

variable "enable_managed_identity" {
  description = "Enable System Assigned Managed Identity for the web app."
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# App Settings (Environment Variables)
# -----------------------------------------------------------------------------

variable "app_settings" {
  description = "Map of application settings (environment variables) for the web app."
  type        = map(string)
  default = {
    "WEBSITE_NODE_DEFAULT_VERSION" = "~18"
  }
}

# -----------------------------------------------------------------------------
# Sample App Deployment
# -----------------------------------------------------------------------------

variable "deploy_sample_app" {
  description = "Whether to deploy the sample Node.js application after infrastructure creation."
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------

variable "owner" {
  description = "Owner of the resources (email or team name)."
  type        = string
  default     = "terraform-training"
}

variable "cost_center" {
  description = "Cost center for billing purposes."
  type        = string
  default     = "training"
}

variable "additional_tags" {
  description = "Additional tags to apply to all resources."
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Local Values
# -----------------------------------------------------------------------------
# These are computed values based on inputs, used throughout the configuration.
# -----------------------------------------------------------------------------
