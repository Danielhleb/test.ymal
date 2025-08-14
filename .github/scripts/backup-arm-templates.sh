#!/bin/bash

# ARM Template Backup Script for Azure ALM Environments
# Usage: ./backup-arm-templates.sh <ENVIRONMENT_NAME> <SUBSCRIPTION_ID>
# Example: ./backup-arm-templates.sh "ALM-TEST" "12345678-1234-1234-1234-123456789012"

set -e  # Exit on any error

# Function to display usage
usage() {
    echo "Usage: $0 <ENVIRONMENT_NAME> <SUBSCRIPTION_ID>"
    echo "  ENVIRONMENT_NAME: Name of the environment (e.g., ALM-TEST, ALM-DEV, ALM-PREPROD, ALM-PROD)"
    echo "  SUBSCRIPTION_ID: Azure subscription ID"
    echo ""
    echo "Example: $0 ALM-TEST 12345678-1234-1234-1234-123456789012"
    exit 1
}

# Function to log messages with timestamp
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Function to validate JSON
validate_json() {
    local file_path="$1"
    if jq empty "$file_path" 2>/dev/null; then
        log "✓ Verified valid JSON content in: $file_path"
        return 0
    else
        log "⚠ Warning: Invalid JSON content in: $file_path"
        log "First 100 characters of file content:"
        head -c 100 "$file_path"
        return 1
    fi
}

# Function to export ARM template for a resource group
export_arm_template() {
    local resource_group_name="$1"
    local file_path="$2"
    
    log "Attempting to export ARM template for resource group: $resource_group_name"
    
    # Primary export method
    if az group export --name "$resource_group_name" --include-parameter-default-value --skip-resource-name-params > "$file_path" 2>/dev/null; then
        local filesize=$(du -h "$file_path" | cut -f1)
        log "✓ Exported ARM template saved to: $file_path (Size: $filesize)"
        validate_json "$file_path"
        return 0
    else
        log "⚠ Primary export method failed for resource group: $resource_group_name"
        log "Trying alternative export method..."
        
        # Alternative export method - get from deployment history
        if az deployment group list --resource-group "$resource_group_name" --query "[0].properties.template" -o json > "$file_path" 2>/dev/null && [ -s "$file_path" ]; then
            log "✓ Alternative export method succeeded"
            validate_json "$file_path"
            return 0
        else
            log "⚠ Alternative export also failed. Resource group may not have deployments to export."
            echo '{"error": "No deployments found to export", "resourceGroup": "'$resource_group_name'", "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}' > "$file_path"
            return 1
        fi
    fi
}

# Main script execution starts here
main() {
    # Check if correct number of arguments provided
    if [ $# -ne 2 ]; then
        log "❌ Error: Incorrect number of arguments"
        usage
    fi

    local environment_name="$1"
    local subscription_id="$2"

    log "===========================================" 
    log "Starting ARM Template Backup Process"
    log "Environment: $environment_name"
    log "Subscription ID: $subscription_id"
    log "==========================================="

    # Validate subscription ID is set
    if [ -z "$subscription_id" ]; then
        log "❌ Error: SUBSCRIPTION_ID is not set or empty!"
        exit 1
    fi

    # Set Azure context
    log "Setting Azure context for subscription: $subscription_id"
    if ! az account set --subscription "$subscription_id"; then
        log "❌ Error: Failed to set Azure subscription context"
        exit 1
    fi

    # Verify we're in the correct subscription
    current_subscription=$(az account show --query "id" -o tsv)
    if [ "$current_subscription" != "$subscription_id" ]; then
        log "❌ Error: Current subscription ($current_subscription) does not match expected ($subscription_id)"
        exit 1
    fi

    log "✓ Successfully set Azure context for subscription: $subscription_id"

    # Create directory structure
    local timestamp=$(date +"%Y%m%d-%H%M%S")
    local base_folder="."
    local subscription_folder="$base_folder/$environment_name"
    
    log "Creating directory: $subscription_folder"
    mkdir -p "$subscription_folder"

    # Get list of resource groups
    log "Retrieving resource groups from subscription..."
    local resource_groups_json=$(az group list --query "[].name" -o json)
    
    if [ "$(echo "$resource_groups_json" | jq '. | length')" -eq 0 ]; then
        log "⚠ No resource groups found in subscription: $subscription_id"
        exit 0
    fi

    local resource_group_count=$(echo "$resource_groups_json" | jq '. | length')
    log "✓ Found $resource_group_count resource group(s) in subscription: $subscription_id"

    # Initialize counters
    local success_count=0
    local error_count=0

    # Process each resource group
    echo "$resource_groups_json" | jq -r '.[]' | while read -r resource_group_name; do
        log "===========================================" 
        log "Processing resource group: $resource_group_name"
        
        local resource_group_folder="$subscription_folder/$resource_group_name"
        mkdir -p "$resource_group_folder"
        
        local file_name="${resource_group_name}_${timestamp}.json"
        local file_path="$resource_group_folder/$file_name"
        
        if export_arm_template "$resource_group_name" "$file_path"; then
            ((success_count++))
            log "✓ Successfully processed resource group: $resource_group_name"
        else
            ((error_count++))
            log "❌ Failed to process resource group: $resource_group_name"
        fi
        
        log "==========================================="
    done

    # Final summary
    log "===========================================" 
    log "ARM Template Backup Process Completed"
    log "Environment: $environment_name"
    log "Total Resource Groups: $resource_group_count"
    log "Successfully Exported: $success_count"
    log "Errors Encountered: $error_count"
    log "==========================================="

    # List created files
    log "Generated backup files:"
    find "$subscription_folder" -name "*.json" -type f | while read -r file; do
        local size=$(du -h "$file" | cut -f1)
        log "  - $file ($size)"
    done

    log "Script execution completed successfully!"
}

# Run main function with all arguments
main "$@"