# =============================================================================
# Module 02: Outputs
# =============================================================================
# Outputs expose information about the deployed resources.
# These can be used by other configurations, scripts, or for reference.
# =============================================================================

# -----------------------------------------------------------------------------
# Resource Group Outputs
# -----------------------------------------------------------------------------

output "resource_group_name" {
  description = "Name of the created resource group."
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "ID of the created resource group."
  value       = azurerm_resource_group.main.id
}

output "resource_group_location" {
  description = "Location of the created resource group."
  value       = azurerm_resource_group.main.location
}

# -----------------------------------------------------------------------------
# App Service Outputs
# -----------------------------------------------------------------------------

output "app_service_url" {
  description = "URL to access the deployed web application."
  value       = "https://${module.appservice.default_hostname}"
}

output "app_service_hostname" {
  description = "Default hostname of the web app (without https://)."
  value       = module.appservice.default_hostname
}

output "app_service_id" {
  description = "Resource ID of the web app."
  value       = module.appservice.webapp_id
}

output "app_service_name" {
  description = "Name of the deployed web app."
  value       = local.webapp_name
}

# -----------------------------------------------------------------------------
# Managed Identity Outputs (Conditional)
# -----------------------------------------------------------------------------

output "app_service_principal_id" {
  description = "Principal ID of the web app's managed identity (if enabled)."
  value       = module.appservice.principal_id
}

# -----------------------------------------------------------------------------
# Environment Information
# -----------------------------------------------------------------------------

output "environment" {
  description = "The environment this deployment belongs to."
  value       = var.environment
}

output "deployment_summary" {
  description = "Summary of the deployment for quick reference."
  value       = <<-EOT
    
    ╔══════════════════════════════════════════════════════════════════╗
    ║                    Deployment Summary                            ║
    ╠══════════════════════════════════════════════════════════════════╣
    ║  Environment:     ${var.environment}
    ║  Resource Group:  ${azurerm_resource_group.main.name}
    ║  Location:        ${azurerm_resource_group.main.location}
    ║  Web App URL:     https://${module.appservice.default_hostname}
    ║  Managed Identity: ${var.enable_managed_identity ? "Enabled" : "Disabled"}
    ╚══════════════════════════════════════════════════════════════════╝
    
  EOT
}
