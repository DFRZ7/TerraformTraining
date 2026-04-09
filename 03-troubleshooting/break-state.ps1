# break-state.ps1 - Simulate manual changes outside Terraform
# Run this AFTER terraform apply to introduce state drift.

Write-Host ""
Write-Host "Simulating manual Azure changes (state drift)..." -ForegroundColor Yellow
Write-Host ""

# 1. Delete the NSG outside Terraform (creates orphaned state entry)
Write-Host "1. Deleting NSG nsg-lab03 outside Terraform..." -ForegroundColor Cyan
az network nsg delete --name nsg-lab03 --resource-group rg-lab03-state-test 2>$null
Write-Host "   NSG deleted from Azure (but still in Terraform state!)" -ForegroundColor Green

# 2. Add tags to VNet outside Terraform (creates attribute drift)
Write-Host "2. Adding tags to VNet outside Terraform..." -ForegroundColor Cyan
az network vnet update --name vnet-lab03 --resource-group rg-lab03-state-test --tags env=production team=platform manual=true --output none 2>$null
Write-Host "   VNet tags modified (Terraform does not know!)" -ForegroundColor Green

Write-Host ""
Write-Host "State drift introduced! Now run:" -ForegroundColor Red
Write-Host "   terraform plan" -ForegroundColor White
Write-Host "   terraform destroy" -ForegroundColor White
Write-Host ""
