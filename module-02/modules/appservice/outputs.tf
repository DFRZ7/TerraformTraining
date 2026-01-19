# =============================================================================
# App Service Module: Outputs
# =============================================================================
# Outputs expose useful information about the created resources.
# =============================================================================

output "default_hostname" {
  description = "Default hostname of the web app (e.g., myapp.azurewebsites.net)."
  value       = azurerm_linux_web_app.main.default_hostname
}

output "webapp_id" {
  description = "Resource ID of the Linux Web App."
  value       = azurerm_linux_web_app.main.id
}

output "webapp_name" {
  description = "Name of the Linux Web App."
  value       = azurerm_linux_web_app.main.name
}

output "principal_id" {
  description = "Principal ID of the System Assigned Managed Identity (if enabled)."
  value       = var.enable_managed_identity ? azurerm_linux_web_app.main.identity[0].principal_id : null
}

output "service_plan_id" {
  description = "Resource ID of the App Service Plan."
  value       = azurerm_service_plan.main.id
}

output "service_plan_name" {
  description = "Name of the App Service Plan."
  value       = azurerm_service_plan.main.name
}

output "outbound_ip_addresses" {
  description = "Comma-separated list of outbound IP addresses used by the web app."
  value       = azurerm_linux_web_app.main.outbound_ip_addresses
}
