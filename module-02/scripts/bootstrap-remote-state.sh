#!/bin/sh
# =============================================================================
# Bootstrap Script: Azure Storage Backend for Terraform Remote State
# =============================================================================
# This script creates the Azure resources needed for Terraform remote state:
#   - Resource Group
#   - Storage Account (with soft delete and versioning)
#   - Blob Container
#
# The script is idempotent - running it multiple times is safe.
#
# Prerequisites:
#   - Azure CLI installed and authenticated (az login)
#   - Appropriate permissions to create resources
#
# Usage:
#   export RG="rg-tfstate-dev"
#   export SA="sttfstatedev12345"
#   export CONTAINER="tfstate"
#   export LOCATION="centralus"
#   ./bootstrap-remote-state.sh
#
# Or inline:
#   RG=rg-tfstate-dev SA=sttfstatedev12345 CONTAINER=tfstate LOCATION=centralus ./bootstrap-remote-state.sh
# =============================================================================

set -e  # Exit on error

# -----------------------------------------------------------------------------
# Configuration from Environment Variables
# -----------------------------------------------------------------------------

# Check required environment variables
if [ -z "$RG" ]; then
    echo "ERROR: RG environment variable is required (Resource Group name)"
    echo "Example: export RG='rg-tfstate-dev'"
    exit 1
fi

if [ -z "$SA" ]; then
    echo "ERROR: SA environment variable is required (Storage Account name)"
    echo "Example: export SA='sttfstatedev12345'"
    echo "Note: Storage account names must be 3-24 lowercase letters/numbers, globally unique"
    exit 1
fi

if [ -z "$CONTAINER" ]; then
    echo "ERROR: CONTAINER environment variable is required (Blob Container name)"
    echo "Example: export CONTAINER='tfstate'"
    exit 1
fi

if [ -z "$LOCATION" ]; then
    echo "ERROR: LOCATION environment variable is required (Azure region)"
    echo "Example: export LOCATION='centralus'"
    exit 1
fi

# Validate storage account name (3-24 lowercase letters and numbers)
if ! echo "$SA" | grep -qE '^[a-z0-9]{3,24}$'; then
    echo "ERROR: Storage account name must be 3-24 lowercase letters and numbers only"
    echo "Got: $SA"
    exit 1
fi

echo "============================================================================="
echo "Terraform Remote State Bootstrap"
echo "============================================================================="
echo "Resource Group:    $RG"
echo "Storage Account:   $SA"
echo "Container:         $CONTAINER"
echo "Location:          $LOCATION"
echo "============================================================================="
echo ""

# -----------------------------------------------------------------------------
# Verify Azure CLI Authentication
# -----------------------------------------------------------------------------

echo "[1/5] Verifying Azure CLI authentication..."
if ! az account show > /dev/null 2>&1; then
    echo "ERROR: Not logged in to Azure CLI. Please run 'az login' first."
    exit 1
fi

SUBSCRIPTION=$(az account show --query name -o tsv)
echo "       Using subscription: $SUBSCRIPTION"
echo ""

# -----------------------------------------------------------------------------
# Create Resource Group
# -----------------------------------------------------------------------------

echo "[2/5] Creating/verifying resource group '$RG'..."
if az group show --name "$RG" > /dev/null 2>&1; then
    echo "       Resource group already exists."
else
    az group create \
        --name "$RG" \
        --location "$LOCATION" \
        --tags Purpose=TerraformState ManagedBy=BootstrapScript \
        --output none
    echo "       Resource group created."
fi
echo ""

# -----------------------------------------------------------------------------
# Create Storage Account
# -----------------------------------------------------------------------------

echo "[3/5] Creating/verifying storage account '$SA'..."
if az storage account show --name "$SA" --resource-group "$RG" > /dev/null 2>&1; then
    echo "       Storage account already exists."
else
    az storage account create \
        --name "$SA" \
        --resource-group "$RG" \
        --location "$LOCATION" \
        --sku Standard_LRS \
        --kind StorageV2 \
        --https-only true \
        --min-tls-version TLS1_2 \
        --allow-blob-public-access false \
        --tags Purpose=TerraformState ManagedBy=BootstrapScript \
        --output none
    echo "       Storage account created."
fi
echo ""

# -----------------------------------------------------------------------------
# Enable Soft Delete and Versioning
# -----------------------------------------------------------------------------

echo "[4/5] Enabling blob soft delete and versioning..."

# Enable blob soft delete (7 days retention)
az storage account blob-service-properties update \
    --account-name "$SA" \
    --resource-group "$RG" \
    --enable-delete-retention true \
    --delete-retention-days 7 \
    --enable-versioning true \
    --output none

echo "       Soft delete enabled (7 day retention)"
echo "       Versioning enabled"
echo ""

# -----------------------------------------------------------------------------
# Create Blob Container
# -----------------------------------------------------------------------------

echo "[5/5] Creating/verifying blob container '$CONTAINER'..."

# Get storage account key for container creation
ACCOUNT_KEY=$(az storage account keys list \
    --account-name "$SA" \
    --resource-group "$RG" \
    --query '[0].value' \
    --output tsv)

if az storage container show \
    --name "$CONTAINER" \
    --account-name "$SA" \
    --account-key "$ACCOUNT_KEY" > /dev/null 2>&1; then
    echo "       Container already exists."
else
    az storage container create \
        --name "$CONTAINER" \
        --account-name "$SA" \
        --account-key "$ACCOUNT_KEY" \
        --output none
    echo "       Container created."
fi
echo ""

# -----------------------------------------------------------------------------
# Output Backend Configuration
# -----------------------------------------------------------------------------

echo "============================================================================="
echo "SUCCESS! Remote state backend is ready."
echo "============================================================================="
echo ""
echo "Use these values for terraform init:"
echo ""
echo "  terraform init \\"
echo "    -backend-config=\"resource_group_name=$RG\" \\"
echo "    -backend-config=\"storage_account_name=$SA\" \\"
echo "    -backend-config=\"container_name=$CONTAINER\" \\"
echo "    -backend-config=\"key=dev/appservice.tfstate\""
echo ""
echo "Or for PowerShell:"
echo ""
echo "  terraform init \`"
echo "    -backend-config=\"resource_group_name=$RG\" \`"
echo "    -backend-config=\"storage_account_name=$SA\" \`"
echo "    -backend-config=\"container_name=$CONTAINER\" \`"
echo "    -backend-config=\"key=dev/appservice.tfstate\""
echo ""
echo "Environment-specific state keys:"
echo "  - dev:     key=dev/appservice.tfstate"
echo "  - test:    key=test/appservice.tfstate"
echo "  - staging: key=staging/appservice.tfstate"
echo "  - prod:    key=prod/appservice.tfstate"
echo ""
echo "============================================================================="
