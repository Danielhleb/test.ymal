# Backup Output Example

This document shows an example of the backup output structure and content that the workflow generates.

## Directory Structure

```
ALM-TEST/
├── my-resource-group-1/
│   ├── my-resource-group-1_20241201-143022.json
│   └── my-resource-group-1_20241201-150045.json
├── my-resource-group-2/
│   ├── my-resource-group-2_20241201-143022.json
│   └── my-resource-group-2_20241201-150045.json
├── network-resources/
│   ├── network-resources_20241201-143022.json
│   └── network-resources_20241201-150045.json
└── backup_summary_20241201-143022.json
```

## ARM Template Example

**File**: `ALM-TEST/my-resource-group-1/my-resource-group-1_20241201-143022.json`

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "storageAccountName": {
      "type": "string",
      "defaultValue": "mystorageaccount123",
      "metadata": {
        "description": "Storage account name"
      }
    },
    "location": {
      "type": "string",
      "defaultValue": "East US",
      "metadata": {
        "description": "Location for all resources"
      }
    }
  },
  "variables": {
    "storageAccountType": "Standard_LRS"
  },
  "resources": [
    {
      "type": "Microsoft.Storage/storageAccounts",
      "apiVersion": "2021-09-01",
      "name": "[parameters('storageAccountName')]",
      "location": "[parameters('location')]",
      "sku": {
        "name": "[variables('storageAccountType')]"
      },
      "kind": "StorageV2",
      "properties": {
        "supportsHttpsTrafficOnly": true,
        "minimumTlsVersion": "TLS1_2"
      }
    }
  ],
  "outputs": {
    "storageAccountName": {
      "type": "string",
      "value": "[parameters('storageAccountName')]"
    }
  }
}
```

## Summary Report Example

**File**: `ALM-TEST/backup_summary_20241201-143022.json`

```json
{
  "environment": "TEST",
  "subscription_id": "12345678-1234-1234-1234-123456789012",
  "backup_timestamp": "20241201-143022",
  "backup_date": "2024-12-01 14:30:22 UTC",
  "summary": {
    "successful_exports": 3,
    "failed_exports": 0,
    "total_resource_groups": 3
  },
  "triggered_by": "workflow_dispatch",
  "commit_sha": "abc123def456789"
}
```

## Error File Example

**File**: `ALM-TEST/empty-resource-group/empty-resource-group_20241201-143022.json`

```json
{
  "error": "No deployments found to export",
  "resourceGroup": "empty-resource-group",
  "subscription": "12345678-1234-1234-1234-123456789012",
  "timestamp": "20241201-143022"
}
```

## Workflow Log Output Example

```
✓ Setting Azure context for subscription: 12345678-1234-1234-1234-123456789012
✓ Successfully set subscription context
✓ Created backup folder: ./ALM-TEST
✓ Found 3 resource group(s) in subscription: 12345678-1234-1234-1234-123456789012

Processing resource group: my-resource-group-1
✓ Attempting to export ARM template for resource group: my-resource-group-1
✓ Exported ARM template saved to: ./ALM-TEST/my-resource-group-1/my-resource-group-1_20241201-143022.json (Size: 2.1K)
✓ Verified valid JSON content
---

Processing resource group: my-resource-group-2
✓ Attempting to export ARM template for resource group: my-resource-group-2
✓ Exported ARM template saved to: ./ALM-TEST/my-resource-group-2/my-resource-group-2_20241201-143022.json (Size: 1.8K)
✓ Verified valid JSON content
---

Processing resource group: empty-resource-group
✓ Attempting to export ARM template for resource group: empty-resource-group
✗ Failed to export ARM template for resource group: empty-resource-group
Error details: No deployments found
Trying alternative export method...
✗ Alternative export also failed
✓ Created error file for empty-resource-group
---

Export Summary for TEST:
✓ Successful exports: 2
✗ Failed exports: 1
Total resource groups processed: 3
✓ Created summary report: ./ALM-TEST/backup_summary_20241201-143022.json
✓ Backup completed for TEST environment
```

## Artifact Upload Example

When the workflow uploads artifacts, you'll see:

```
✓ Uploading TEST Artifacts
✓ Uploaded 4 files to alm-test-backup artifact
  - ALM-TEST/my-resource-group-1/my-resource-group-1_20241201-143022.json (2.1 KB)
  - ALM-TEST/my-resource-group-2/my-resource-group-2_20241201-143022.json (1.8 KB)
  - ALM-TEST/empty-resource-group/empty-resource-group_20241201-143022.json (0.2 KB)
  - ALM-TEST/backup_summary_20241201-143022.json (0.5 KB)
```

## Git Commit Example

The final commit message will look like:

```
ARM Templates Backup - 2024-12-01 14:30:22 UTC

Environments backed up:
- TEST: success
- DEV: success
- PREPROD: success
- PROD: success

Triggered by: workflow_dispatch
Commit: abc123def456789
```

## Notes

1. **Timestamps**: All files include timestamps in the format `YYYYMMDD-HHMMSS`
2. **File Sizes**: The workflow reports file sizes for monitoring
3. **JSON Validation**: All exported templates are validated as proper JSON
4. **Error Handling**: Failed exports create error files with details
5. **Summary Reports**: Each environment gets a comprehensive summary
6. **Retention**: Artifacts are retained for 7 days by default