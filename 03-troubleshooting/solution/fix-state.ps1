# ============================================================
# fix-state.ps1 — Fix the state drift from break-state.ps1
# ============================================================
# Run these steps to reconcile Terraform state with reality.
# ============================================================

Write-Host "`nFixing Terraform state drift..." -ForegroundColor Cyan
Write-Host ""

# Step 1: See what Terraform thinks exists
Write-Host "Step 1: Current Terraform state:" -ForegroundColor Yellow
terraform state list
Write-Host ""

# Step 2: Remove the deleted NSG from state (it no longer exists in Azure)
Write-Host "Step 2: Removing orphaned NSG from state..." -ForegroundColor Yellow
terraform state rm azurerm_network_security_group.lab03
Write-Host ""

# Step 3: Refresh state to pick up manual tag changes on VNet
Write-Host "Step 3: Refreshing state to reconcile drift..." -ForegroundColor Yellow
terraform plan -refresh-only
Write-Host ""

# Step 4: Apply the refresh
Write-Host "Step 4: Apply refresh to update state file..." -ForegroundColor Yellow
terraform apply -refresh-only -auto-approve
Write-Host ""

# Step 5: Now replace the broken main.tf with the solution (remove prevent_destroy)
Write-Host "Step 5: Copy solution/main.tf over main.tf to remove prevent_destroy" -ForegroundColor Yellow
Write-Host "   Copy-Item solution\main.tf main.tf -Force" -ForegroundColor White
Write-Host ""

# Step 6: Now plan and apply should work cleanly
Write-Host "Step 6: Now you can run:" -ForegroundColor Green
Write-Host "   terraform plan" -ForegroundColor White
Write-Host "   terraform apply -auto-approve   # Re-creates NSG, fixes tags" -ForegroundColor White
Write-Host "   terraform destroy -auto-approve  # Clean up everything" -ForegroundColor White
Write-Host ""
