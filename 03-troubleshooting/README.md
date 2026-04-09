# Lab 03 — State & Dependency Conflicts

> **Time:** 10 minutes
> **Category:** State & Dependencies
> **Phase:** Plan/Apply/Destroy

## Prerequisites

- Azure CLI installed and authenticated (`az login`)
- Terraform v1.5+ installed
- A valid Azure subscription — update the `subscription_id` in `main.tf` before starting
- PowerShell terminal (all commands in this lab use PowerShell)

## Scenario

You have a working Terraform config that deploys a VNet with subnets and an NSG.
Someone on your team made manual changes in the Azure Portal (deleted the NSG,
added tags to the VNet). Now Terraform is confused — the state doesn't match reality.

On top of that, someone added `prevent_destroy` to the resource group, so you can't
clean up easily.

## Steps to Reproduce

### Step 1: Deploy the initial (working) infrastructure

```powershell
cd labs/03-state-and-dependencies
terraform init
terraform apply -auto-approve
```

### Step 2: Simulate someone making manual changes outside Terraform

```powershell
.\break-state.ps1
```

### Step 3: See the chaos

```powershell
terraform plan      # Unexpected changes everywhere!
terraform destroy   # Blocked by prevent_destroy!
```

## Understanding the Three-Way Relationship

Terraform works by keeping three things in sync:

```
  main.tf (Config)  <---->  terraform.tfstate (State)  <---->  Azure (Reality)
```

When all three agree, `terraform plan` shows no changes — that is the healthy state.

The **state file is the ledger**. Terraform does not query Azure directly to decide
what to do. It compares your config (`main.tf`) against the state file, then compares
the state file against Azure. The moment any one of these drifts — manual portal changes,
state corruption, config edits without apply — you get cascading confusion.

This is why you should **never modify Azure resources manually** if they are managed by
Terraform. Every manual change creates a gap between Azure and state that someone has
to reconcile, and the longer it goes unnoticed, the harder it gets to untangle.

## State Management Commands Reference

| Command | Scope | Direction | What it does |
|---|---|---|---|
| `terraform apply -refresh-only` | All resources | Azure to State | Reads current Azure state and updates the state file. Changes zero resources in Azure. Purely a one-way read. |
| `terraform state rm` | One resource | Remove from State | Removes a resource from the state file. Does not delete anything in Azure. Use when a resource was deleted outside Terraform. |
| `terraform import` | One resource | Azure to State | Adds an existing Azure resource into the state file so Terraform starts tracking it. Requires two steps — see note below. |

**Important:** `terraform apply -refresh-only` only writes to the state file. The actual
Azure changes happen later when you run `terraform apply` (without `-refresh-only`), which
compares the now-updated state against your config and pushes changes to Azure to match
what `main.tf` declares.

**Note on `terraform import`:** Importing a resource into state is only half the job.
You must also write a matching `resource` block in your `.tf` config that describes
that resource. If you import without adding the config, the next `terraform plan` will
show the resource as needing to be destroyed — it exists in state but Terraform sees
no config declaring it should exist. Both steps are required: import the resource into
state, and add the corresponding IaC code to your Terraform files.

## Troubleshooting Steps

1. Run `terraform plan` — what does Terraform think needs to change?
2. Run `terraform state list` — what resources does Terraform think exist?
3. Run `terraform state show <resource_address>` to inspect a specific resource in state
4. Compare with reality:

```powershell
az resource list -g rg-lab03-state-test -o table
```

5. Understand the drift between state and actual Azure resources
6. Fix the state, then fix the config

## Resolution Steps

Once you have observed the drift in Step 3, fix it in this order:

### Fix 1: Remove the orphaned NSG from state

The NSG was deleted from Azure but Terraform still tracks it. Remove it from state:

```powershell
terraform state rm azurerm_network_security_group.lab03
```

**Note:** This step is technically redundant — the `refresh-only` in Fix 2 would also
detect that the NSG no longer exists in Azure and remove it from state automatically.
We show `state rm` here so you can see both approaches. In practice, running
`terraform apply -refresh-only` alone handles both deleted resources and attribute drift
in one pass.

### Fix 2: Reconcile VNet tag drift

The VNet tags were changed in the portal. Refresh the state so Terraform knows about
the current Azure values:

```powershell
terraform plan -refresh-only
terraform apply -refresh-only -auto-approve
```

Remember: this only updates the state file. No Azure resources are changed here.

### Fix 3: Re-apply to restore desired state

Now that the state file reflects reality, apply your config to bring Azure back
in line with what `main.tf` declares:

```powershell
terraform plan
terraform apply -auto-approve
```

### Fix 4: Deal with prevent_destroy

`prevent_destroy` blocks `terraform destroy`. There is no `-force` flag to override it.
You must remove the `lifecycle` block from the config, then destroy:

```powershell
# Copy the solution config (which has prevent_destroy removed)
Copy-Item solution\main.tf main.tf -Force

# Now destroy works
terraform destroy -auto-approve
```

## AI Copilot Prompts

**Prompt 1:**

```
My terraform plan shows unexpected changes because someone modified Azure
resources outside of Terraform. Here's the plan output. What terraform
state commands should I run to reconcile this?

<paste your terraform plan output>
```

**Prompt 2:**

```
I'm trying to terraform destroy but getting this error:
"Resource azurerm_resource_group.lab03 has lifecycle.prevent_destroy set"

How do I override this? Is there a -force flag?
```

**Prompt 3:**

```
Explain the difference between these Terraform commands and when to use each:
- terraform refresh
- terraform plan -refresh-only
- terraform state rm
- terraform import
```

## Solution

See [solution/main.tf](solution/main.tf) and [solution/fix-state.ps1](solution/fix-state.ps1)

## Key Takeaways

- **Never modify Azure resources manually** if they are managed by Terraform — every
  manual change creates drift between Azure and state that must be reconciled
- The state file is the ledger — Config, State, and Azure must stay in sync
- `terraform apply -refresh-only` syncs Azure to State (one-way read, changes nothing in Azure)
- `terraform state rm` removes a resource from state (does not delete from Azure)
- `terraform import` adds an existing Azure resource to state — but that is only half
  the job. You must also write a matching `resource` block in your `.tf` config, or
  the next plan will try to destroy it. Both the state entry and the IaC code are required.
- `prevent_destroy` is a safety net, not a lock — you can always edit the config to remove it
