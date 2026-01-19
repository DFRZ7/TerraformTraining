# =============================================================================
# App Service Module: Variables
# =============================================================================
# Input variables for the App Service module.
# =============================================================================

variable "app_name" {
  description = "Name of the web application. Must be globally unique."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{2,60}$", var.app_name))
    error_message = "App name must be 2-60 lowercase alphanumeric characters or hyphens."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group where resources will be created."
  type        = string
}

variable "location" {
  description = "Azure region for the resources."
  type        = string
}

variable "appservice_plan_sku" {
  description = "SKU for the App Service Plan."
  type        = string
  default     = "F1"

  validation {
    condition     = contains(["F1", "B1", "B2", "B3", "S1", "S2", "S3", "P1v2", "P2v2", "P3v2", "P1v3", "P2v3", "P3v3"], var.appservice_plan_sku)
    error_message = "SKU must be one of: F1, B1, B2, B3, S1, S2, S3, P1v2, P2v2, P3v2, P1v3, P2v3, P3v3."
  }
}

variable "runtime_stack" {
  description = "Runtime stack in format RUNTIME|VERSION (e.g., NODE|18-lts, PYTHON|3.11)."
  type        = string
  default     = "NODE|18-lts"

  validation {
    condition     = can(regex("^(NODE|PYTHON|DOTNETCORE|JAVA)\\|[a-z0-9.-]+$", upper(var.runtime_stack)))
    error_message = "Runtime stack must be in format RUNTIME|VERSION. Supported runtimes: NODE, PYTHON, DOTNETCORE, JAVA."
  }
}

variable "app_settings" {
  description = "Map of application settings (environment variables)."
  type        = map(string)
  default     = {}
}

variable "enable_managed_identity" {
  description = "Enable System Assigned Managed Identity for the web app."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
