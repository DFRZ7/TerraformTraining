# Terraform Training — Foundations and Intermediate

This repository contains the Terraform for Azure training program.  
It includes:

- **Module 00 – Prerequisites**
- **Module 01 – Terraform Basics**
- **Module 02 – Intermediate (Remote State, Variables, Modules)**

These modules are designed for Azure engineers who are new to Terraform or solidifying their Infrastructure‑as‑Code (IaC) fundamentals.

## Learning Objectives

After completing Modules 00–02, learners will be able to:

- Install and verify Terraform and Azure CLI
- Authenticate to Azure using Azure CLI
- Create and run a basic Terraform configuration
- Understand the core Terraform workflow:  
  `init → fmt → validate → plan → apply → destroy`
- Understand the purpose of the Terraform state file
- Deploy and destroy their first Azure resource
- Configure remote state with Azure Storage backend
- Define variables with types, validation, and defaults
- Create and use reusable Terraform modules
- Deploy Azure App Service with Linux runtime

## Prerequisites

- Active Azure subscription with sufficient permissions
- Basic understanding of Azure resources
- Familiarity with command-line interfaces
- Text editor or IDE (VS Code recommended)

## Training Structure

### Module 00: Prerequisites (10 minutes)

**Location:** `00-prerequisites/`

Learn how to install Terraform, configure Azure CLI, and authenticate to Azure.

**Actions:**

- Install Terraform
- Install Azure CLI
- Authenticate with `az login`
- Verify installations

---

### Module 01: Basics (15 minutes)

**Location:** `01-basics/`

Create your first Terraform configuration to deploy an Azure Resource Group.

**Actions:**

- Write your first `main.tf`
- Run `terraform init`
- Run `terraform fmt` and `terraform validate`
- Run `terraform plan`
- Run `terraform apply`
- Understand state files
- Run `terraform destroy`

---

### Module 02: Intermediate (45-60 minutes)

**Location:** `02-intermediate/`

Learn remote state management, variables with validation, and reusable modules by deploying an Azure App Service.

**Actions:**

- Bootstrap Azure Storage for remote state
- Configure backend with state locking
- Define variables with types and validation
- Create and use a reusable App Service module
- Deploy a Linux Web App with Node.js runtime
- Switch between environments (dev/test)

## Clean Up

To avoid Azure charges, remember to destroy all resources after completing the training:

```bash
terraform destroy
```

## Additional Resources

- [Terraform Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Terraform AzAPI Provider Documentation](https://registry.terraform.io/providers/azure/azapi/latest/docs)
- [Azure AI Foundry Documentation](https://learn.microsoft.com/azure/ai-studio/)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)

---

**Version:** 1.1  
**Last Updated:** January 2026
