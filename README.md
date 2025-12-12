# Terraform Training: Deploy Azure AI Foundry Multi-Agent Solution

## Overview

This training provides a hands-on introduction to Terraform for Azure engineers. You will learn how to install, configure, and use Terraform to deploy infrastructure on Azure, culminating in the deployment of an Azure AI Foundry project that runs a multi-agent AI solution.

**Duration:** 90-120 minutes

**Target Audience:** Azure engineers new to Terraform or looking to solidify their Infrastructure as Code (IaC) practices.

## Learning Objectives

By the end of this training, you will be able to:

- Install and configure Terraform for Azure
- Write Terraform configurations using HCL (HashiCorp Configuration Language)
- Use variables, outputs, and modules effectively
- Manage Terraform state with remote backends
- Deploy Azure resources using both azurerm and azapi providers
- Debug and troubleshoot Terraform deployments
- Query existing Azure resources using data sources
- Deploy a complete Azure AI Foundry solution with GPT-4o model
- Run a Python-based multi-agent application on deployed infrastructure

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

### Module 02: Variables and State (20 minutes)

**Location:** `02-variables-and-state/`

Learn about variables, remote state management, and debugging.

**Actions:**

- Define variables in `variables.tf`
- Create `terraform.tfvars`
- Configure Azure Storage backend for remote state
- Enable debug logging with TF_LOG
- Handle sensitive variables
- Apply configuration with remote state

---

### Module 03: Data Sources (10 minutes)

**Location:** `03-data-sources/`

Query existing Azure resources and use them in your configurations.

**Actions:**

- Use data sources to query existing resources
- Reference data source outputs
- Understand the difference between resources and data sources

---

### Module 04: AI Foundry Hub (20 minutes)

**Location:** `04-ai-foundry-hub/`

Deploy Azure AI Foundry hub with required dependencies.

**Actions:**

- Configure azurerm and azapi providers
- Deploy Storage Account
- Deploy Key Vault
- Deploy Application Insights
- Deploy AI Foundry Hub
- Review outputs

---

### Module 05: Modules (20 minutes)

**Location:** `05-modules/`

Refactor your code into reusable modules.

**Actions:**

- Create module structure
- Define module inputs and outputs
- Call modules from root configuration
- Understand module best practices

---

### Module 06: Complete Solution (20 minutes)

**Location:** `06-complete-solution/`

Deploy the full AI Foundry project with model deployment and lifecycle management.

**Actions:**

- Deploy complete infrastructure
- Create AI Foundry project
- Deploy GPT-4o model
- Use lifecycle rules
- Configure outputs for Python app
- Test the deployment

---

### Module 07: Operations (10 minutes)

**Location:** `07-operations/`

Learn operational best practices for Terraform.

**Topics:**

- Debugging with TF_LOG levels
- Importing existing resources
- Using workspaces for environments
- Common troubleshooting scenarios

---

## Python Application

After completing the infrastructure deployment, you will run a multi-agent Python application that performs ticket triage using Azure AI Foundry Agent Service.

**Application Repository:** https://github.com/MicrosoftLearning/mslearn-ai-agents

The application uses three specialized agents:

- **Priority Agent:** Assesses ticket urgency
- **Team Agent:** Assigns tickets to appropriate teams
- **Effort Agent:** Estimates work required

A triage agent coordinates these agents to process support tickets.

## Getting Started

1. Start with `00-prerequisites/installation-guide.md`
2. Progress through each module in order
3. Complete the actions listed in each module's README
4. Deploy the full solution in Module 06
5. Run the Python application using your deployed infrastructure

## Clean Up

To avoid Azure charges, remember to destroy all resources after completing the training:

```bash
cd 06-complete-solution
terraform destroy
```

## Additional Resources

- [Terraform Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Terraform AzAPI Provider Documentation](https://registry.terraform.io/providers/azure/azapi/latest/docs)
- [Azure AI Foundry Documentation](https://learn.microsoft.com/azure/ai-studio/)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)

## Support

For issues or questions during the training, refer to:

- Module-specific README files
- `07-operations/troubleshooting.md`
- Azure AI Foundry portal logs

---

**Version:** 1.0  
**Last Updated:** October 2025
