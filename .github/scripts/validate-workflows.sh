#!/bin/bash

# Workflow Validation Script
# Validates GitHub Actions workflow files for common issues

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_status $BLUE "🔍 Validating GitHub Actions workflows..."
echo

# Check if workflow files exist
WORKFLOW_DIR=".github/workflows"
SEQUENTIAL_WORKFLOW="$WORKFLOW_DIR/alm-arm-templates-backup.yml"
MATRIX_WORKFLOW="$WORKFLOW_DIR/alm-arm-templates-backup-matrix.yml"

if [ ! -d "$WORKFLOW_DIR" ]; then
    print_status $RED "❌ Workflows directory not found: $WORKFLOW_DIR"
    exit 1
fi

# Function to validate YAML syntax
validate_yaml() {
    local file=$1
    local filename=$(basename "$file")
    
    print_status $BLUE "📝 Validating $filename..."
    
    if [ ! -f "$file" ]; then
        print_status $RED "❌ File not found: $file"
        return 1
    fi
    
    # Check if python with yaml is available
    if command -v python3 &> /dev/null; then
        if python3 -c "import yaml" 2>/dev/null; then
            if python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
                print_status $GREEN "✅ YAML syntax is valid"
            else
                print_status $RED "❌ Invalid YAML syntax"
                return 1
            fi
        else
            print_status $YELLOW "⚠️  Python yaml module not available, skipping syntax check"
        fi
    else
        print_status $YELLOW "⚠️  Python3 not available, skipping syntax check"
    fi
    
    # Check for common GitHub Actions patterns
    if grep -q "uses: actions/checkout@v" "$file"; then
        print_status $GREEN "✅ Uses checkout action"
    else
        print_status $YELLOW "⚠️  No checkout action found"
    fi
    
    if grep -q "uses: azure/login@v" "$file"; then
        print_status $GREEN "✅ Uses Azure login action"
    else
        print_status $RED "❌ No Azure login action found"
    fi
    
    if grep -q "uses: actions/upload-artifact@v" "$file"; then
        print_status $GREEN "✅ Uses artifact upload"
    else
        print_status $YELLOW "⚠️  No artifact upload found"
    fi
    
    # Check for required environment variables
    local required_vars=(
        "AZURE_TEST_CLIENT_ID"
        "AZURE_DEV_CLIENT_ID" 
        "AZURE_PRE_CLIENT_ID"
        "AZURE_PROD_CLIENT_ID"
        "AZURE_TENANT_ID"
    )
    
    for var in "${required_vars[@]}"; do
        if grep -q "$var" "$file"; then
            print_status $GREEN "✅ Contains $var"
        else
            print_status $RED "❌ Missing environment variable: $var"
        fi
    done
    
    echo
}

# Function to check backup script
validate_backup_script() {
    local script=".github/scripts/backup-arm-templates.sh"
    print_status $BLUE "🔧 Validating backup script..."
    
    if [ ! -f "$script" ]; then
        print_status $RED "❌ Backup script not found: $script"
        return 1
    fi
    
    if [ -x "$script" ]; then
        print_status $GREEN "✅ Script is executable"
    else
        print_status $YELLOW "⚠️  Script is not executable (may need chmod +x)"
    fi
    
    if grep -q "#!/bin/bash" "$script"; then
        print_status $GREEN "✅ Has bash shebang"
    else
        print_status $RED "❌ Missing bash shebang"
    fi
    
    if grep -q "set -e" "$script"; then
        print_status $GREEN "✅ Uses 'set -e' for error handling"
    else
        print_status $YELLOW "⚠️  Consider adding 'set -e' for error handling"
    fi
    
    # Check for required Azure CLI commands
    local required_commands=(
        "az account set"
        "az group list"
        "az group export"
    )
    
    for cmd in "${required_commands[@]}"; do
        if grep -q "$cmd" "$script"; then
            print_status $GREEN "✅ Uses '$cmd'"
        else
            print_status $RED "❌ Missing command: $cmd"
        fi
    done
    
    echo
}

# Function to check for security best practices
check_security() {
    print_status $BLUE "🔒 Checking security best practices..."
    
    # Check for hardcoded credentials (should not exist)
    local files=("$SEQUENTIAL_WORKFLOW" "$MATRIX_WORKFLOW")
    
    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            local filename=$(basename "$file")
            
            # Check for potential hardcoded secrets (exclude proper secret references)
            if grep -i "password\|secret\|key" "$file" | grep -v "secrets\." | grep -v "env\." | grep -v "client_secret" | grep -v "CLIENT_SECRET" | grep -v "steps\..*\.outputs\." >/dev/null; then
                print_status $YELLOW "⚠️  $filename: Found potential hardcoded credentials"
            else
                print_status $GREEN "✅ $filename: No hardcoded credentials found"
            fi
            
            # Check for proper secret usage
            if grep -q "secrets\." "$file"; then
                print_status $GREEN "✅ $filename: Uses GitHub secrets"
            else
                print_status $RED "❌ $filename: No GitHub secrets usage found"
            fi
        fi
    done
    
    echo
}

# Function to generate summary
generate_summary() {
    print_status $BLUE "📊 Validation Summary"
    echo "========================"
    
    local total_files=0
    local valid_files=0
    
    for file in "$SEQUENTIAL_WORKFLOW" "$MATRIX_WORKFLOW"; do
        if [ -f "$file" ]; then
            total_files=$((total_files + 1))
            print_status $GREEN "✅ $(basename "$file") exists"
            valid_files=$((valid_files + 1))
        else
            total_files=$((total_files + 1))
            print_status $RED "❌ $(basename "$file") missing"
        fi
    done
    
    if [ -f ".github/scripts/backup-arm-templates.sh" ]; then
        print_status $GREEN "✅ Backup script exists"
    else
        print_status $RED "❌ Backup script missing"
    fi
    
    if [ -f "ARM_TEMPLATES_BACKUP.md" ]; then
        print_status $GREEN "✅ Documentation exists"
    else
        print_status $YELLOW "⚠️  Documentation missing"
    fi
    
    echo
    echo "Workflow files: $valid_files/$total_files"
    
    if [ $valid_files -eq $total_files ]; then
        print_status $GREEN "🎉 All workflows are present and appear valid!"
    else
        print_status $YELLOW "⚠️  Some issues found, please review above"
    fi
}

# Main execution
main() {
    # Validate each workflow file
    if [ -f "$SEQUENTIAL_WORKFLOW" ]; then
        validate_yaml "$SEQUENTIAL_WORKFLOW"
    fi
    
    if [ -f "$MATRIX_WORKFLOW" ]; then
        validate_yaml "$MATRIX_WORKFLOW"
    fi
    
    # Validate backup script
    validate_backup_script
    
    # Check security
    check_security
    
    # Generate summary
    generate_summary
}

# Run main function
main "$@"