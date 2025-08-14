#!/bin/bash

# ALM ARM Backup Workflow Validation Script
# This script validates the workflow configuration and dependencies

set -e

echo "🔍 ALM ARM Backup Workflow Validation"
echo "====================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    case $status in
        "OK")
            echo -e "${GREEN}✓${NC} $message"
            ;;
        "WARN")
            echo -e "${YELLOW}⚠${NC} $message"
            ;;
        "ERROR")
            echo -e "${RED}✗${NC} $message"
            ;;
    esac
}

# Check if we're in the right directory
if [ ! -f ".github/workflows/alm-arm-backup.yml" ]; then
    print_status "ERROR" "Workflow file not found. Run this script from the repository root."
    exit 1
fi

print_status "OK" "Found workflow file"

# Validate workflow YAML syntax
echo ""
echo "📋 Validating workflow YAML syntax..."
if command -v yamllint &> /dev/null; then
    if yamllint .github/workflows/alm-arm-backup.yml; then
        print_status "OK" "Workflow YAML syntax is valid"
    else
        print_status "ERROR" "Workflow YAML syntax has issues"
        exit 1
    fi
else
    print_status "WARN" "yamllint not found, skipping YAML validation"
fi

# Check action file
echo ""
echo "🔧 Validating reusable action..."
if [ -f ".github/actions/backup-arm-templates/action.yml" ]; then
    print_status "OK" "Reusable action file found"
    
    if command -v yamllint &> /dev/null; then
        if yamllint .github/actions/backup-arm-templates/action.yml; then
            print_status "OK" "Action YAML syntax is valid"
        else
            print_status "ERROR" "Action YAML syntax has issues"
            exit 1
        fi
    fi
else
    print_status "ERROR" "Reusable action file not found"
    exit 1
fi

# Check required secrets (just check if they're referenced)
echo ""
echo "🔐 Checking required secrets..."
required_secrets=(
    "AZURE_CLIENT_ID_SECRETS_APPREG_ALMCICD_TEST_USGOVVA_01_CLIENT_ID"
    "AZURE_CLIENT_SECRET_SECRETS_APPREG_ALMCICD_TEST_USGOVVA_01_CLIENT_SECRET"
    "AZURE_SUBSCRIPTION_ID_SECRETS_TEST_SUBCRIPTION_ID"
    "AZURE_CLIENT_ID_SECRETS_APPREG_ALMCICD_DEV_USGOVVA_01_CLIENT_ID"
    "AZURE_CLIENT_SECRET_SECRETS_APPREG_ALMCICD_DEV_USGOVVA_01_CLIENT_SECRET"
    "AZURE_SUBSCRIPTION_ID_SECRETS_DEV_SUBCRIPTION_ID"
    "AZURE_CLIENT_ID_SECRETS_APPREG_ALMCICD_PRE_USGOVVA_01_CLIENT_ID"
    "AZURE_CLIENT_SECRET_SECRETS_APPREG_ALMCICD_PRE_USGOVVA_01_CLIENT_SECRET"
    "AZURE_SUBSCRIPTION_ID_SECRETS_PRE_SUBCRIPTION_ID"
    "AZURE_CLIENT_ID_SECRETS_APPREG_ALMCICD_PRD_USGOVVA_01_CLIENT_ID"
    "AZURE_CLIENT_SECRET_SECRETS_APPREG_ALMCICD_PRD_USGOVVA_01_CLIENT_SECRET"
    "AZURE_SUBSCRIPTION_ID_SECRETS_PRD_SUBCRIPTION_ID"
    "AZURE_TENANT_ID_SECRETS_TENANT_ID"
)

for secret in "${required_secrets[@]}"; do
    if grep -q "$secret" .github/workflows/alm-arm-backup.yml; then
        print_status "OK" "Secret '$secret' is referenced in workflow"
    else
        print_status "ERROR" "Secret '$secret' is not referenced in workflow"
    fi
done

# Check for deprecated actions
echo ""
echo "⚠️  Checking for deprecated actions..."
if grep -q "actions/checkout@v2" .github/workflows/alm-arm-backup.yml; then
    print_status "WARN" "Using deprecated checkout@v2, consider upgrading to v4"
else
    print_status "OK" "Using current checkout action version"
fi

if grep -q "actions/upload-artifact@v2" .github/workflows/alm-arm-backup.yml; then
    print_status "WARN" "Using deprecated upload-artifact@v2, consider upgrading to v4"
else
    print_status "OK" "Using current upload-artifact action version"
fi

# Check workflow structure
echo ""
echo "📁 Checking workflow structure..."
if [ -d ".github/workflows" ]; then
    print_status "OK" "Workflows directory exists"
else
    print_status "ERROR" "Workflows directory missing"
fi

if [ -d ".github/actions" ]; then
    print_status "OK" "Actions directory exists"
else
    print_status "ERROR" "Actions directory missing"
fi

# Check for common issues
echo ""
echo "🔍 Checking for common issues..."

# Check for hardcoded secrets
if grep -q "clientSecret.*[a-zA-Z0-9]" .github/workflows/alm-arm-backup.yml; then
    print_status "ERROR" "Found potential hardcoded secrets in workflow"
else
    print_status "OK" "No hardcoded secrets found"
fi

# Check for proper permissions
if grep -q "permissions:" .github/workflows/alm-arm-backup.yml; then
    print_status "OK" "Workflow has explicit permissions defined"
else
    print_status "WARN" "Workflow doesn't have explicit permissions"
fi

# Check for proper error handling
if grep -q "if: always()" .github/workflows/alm-arm-backup.yml; then
    print_status "OK" "Workflow has proper error handling with 'if: always()'"
else
    print_status "WARN" "Workflow may not handle job failures properly"
fi

echo ""
echo "✅ Validation complete!"
echo ""
echo "📝 Next steps:"
echo "1. Ensure all required secrets are configured in your repository"
echo "2. Test the workflow with a manual dispatch"
echo "3. Monitor the first run for any issues"
echo "4. Review the generated backup files and summary reports"