# =============================================================================
# Module 02: Terraform and Provider Version Constraints
# =============================================================================
# This file defines version constraints for Terraform and required providers.
# Keeping versions pinned ensures consistent behavior across team members
# and CI/CD pipelines.
# =============================================================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}
