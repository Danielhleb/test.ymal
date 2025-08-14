# ALM Environment ARM Templates Backup

This repository contains GitHub Actions workflows for automatically backing up Azure ARM templates from multiple ALM (Application Lifecycle Management) environments.

## Overview

The backup system supports four environments:
- **ALM-TEST** - Test environment
- **ALM-DEV** - Development environment  
- **ALM-PREPROD** - Pre-production environment
- **ALM-PROD** - Production environment

## Workflow Files

### 1. Sequential Workflow (`alm-arm-templates-backup.yml`)
- **Purpose**: Processes environments sequentially (one after another)
- **Execution Time**: Longer due to sequential processing
- **Use Case**: When you need careful control over execution order
- **Resource Usage**: Lower concurrent resource usage

### 2. Matrix Workflow (`alm-arm-templates-backup-matrix.yml`)
- **Purpose**: Processes all environments in parallel using matrix strategy
- **Execution Time**: Faster due to parallel processing
- **Use Case**: Recommended for faster backups
- **Resource Usage**: Higher concurrent resource usage

## Features

### 🚀 **Core Functionality**
- **Multi-Environment Support**: Backs up all four ALM environments
- **ARM Template Export**: Exports ARM templates from each resource group
- **Fallback Mechanisms**: Uses alternative export methods if primary fails
- **Git Integration**: Automatically commits and pushes backup files
- **Artifact Management**: Stores backups as workflow artifacts

### 🛡️ **Error Handling**
- **Graceful Failures**: Continues processing other environments if one fails
- **JSON Validation**: Validates exported ARM template JSON structure
- **Comprehensive Logging**: Detailed logging with timestamps
- **Error Recovery**: Alternative export methods for failed resource groups

### 📁 **File Organization**
```
Repository Root/
├── ALM-TEST/
│   └── [ResourceGroupName]/
│       └── [ResourceGroupName]_[timestamp].json
├── ALM-DEV/
│   └── [ResourceGroupName]/
│       └── [ResourceGroupName]_[timestamp].json
├── ALM-PREPROD/
│   └── [ResourceGroupName]/
│       └── [ResourceGroupName]_[timestamp].json
└── ALM-PROD/
    └── [ResourceGroupName]/
        └── [ResourceGroupName]_[timestamp].json
```

## Required Secrets

Configure the following GitHub secrets in your repository:

### Test Environment
- `AZURE_CLIENT_ID_SECRETS_APPREG_ALMCICD_TEST_USGOVVA_01_CLIENT_ID`
- `AZURE_CLIENT_SECRET_SECRETS_APPREG_ALMCICD_TEST_USGOVVA_01_CLIENT_SECRET`
- `AZURE_SUBSCRIPTION_ID_SECRETS_TEST_SUBCRIPTION_ID`

### Development Environment
- `AZURE_CLIENT_ID_SECRETS_APPREG_ALMCICD_DEV_USGOVVA_01_CLIENT_ID`
- `AZURE_CLIENT_SECRET_SECRETS_APPREG_ALMCICD_DEV_USGOVVA_01_CLIENT_SECRET`
- `AZURE_SUBSCRIPTION_ID_SECRETS_DEV_SUBCRIPTION_ID`

### Pre-Production Environment
- `AZURE_CLIENT_ID_SECRETS_APPREG_ALMCICD_PRE_USGOVVA_01_CLIENT_ID`
- `AZURE_CLIENT_SECRET_SECRETS_APPREG_ALMCICD_PRE_USGOVVA_01_CLIENT_SECRET`
- `AZURE_SUBSCRIPTION_ID_SECRETS_PRE_SUBCRIPTION_ID`

### Production Environment
- `AZURE_CLIENT_ID_SECRETS_APPREG_ALMCICD_PRD_USGOVVA_01_CLIENT_ID`
- `AZURE_CLIENT_SECRET_SECRETS_APPREG_ALMCICD_PRD_USGOVVA_01_CLIENT_SECRET`
- `AZURE_SUBSCRIPTION_ID_SECRETS_PRD_SUBCRIPTION_ID`

### Common
- `AZURE_TENANT_ID_SECRETS_TENANT_ID`

## Trigger Events

The workflows are triggered by:
- **Push** to `master` branch
- **Pull Request** to `master` branch
- **Manual trigger** via `workflow_dispatch`

## Scripts

### `backup-arm-templates.sh`
A reusable shell script that:
- Takes environment name and subscription ID as parameters
- Authenticates with Azure
- Exports ARM templates from all resource groups
- Validates JSON output
- Provides comprehensive logging

**Usage:**
```bash
./backup-arm-templates.sh "ALM-TEST" "subscription-id-here"
```

## Backup Process

1. **Authentication**: Login to Azure using service principal credentials
2. **Subscription Setup**: Set Azure context to target subscription
3. **Resource Group Discovery**: List all resource groups in subscription
4. **ARM Template Export**: 
   - Primary method: `az group export`
   - Fallback method: `az deployment group list`
5. **Validation**: Validate exported JSON files
6. **Artifact Upload**: Upload backup files as workflow artifacts
7. **Git Commit**: Commit all backups to repository

## Monitoring and Troubleshooting

### Logs
- Each step provides detailed logging with timestamps
- JSON validation results are logged
- File sizes and counts are reported

### Common Issues

#### Missing Credentials
```
❌ Error: Missing Azure credentials for [Environment] environment
```
**Solution**: Verify all required secrets are configured in GitHub repository settings

#### Subscription Access
```
❌ Error: Failed to set Azure subscription context
```
**Solution**: Verify service principal has access to target subscription

#### Export Failures
```
⚠ Primary export method failed for resource group: [ResourceGroupName]
```
**Solution**: Check resource group permissions and deployment history

### Verification

Check the workflow run logs to verify:
- ✅ All environments processed successfully
- ✅ ARM templates exported for each resource group
- ✅ JSON validation passed
- ✅ Files committed to repository

## File Retention

- **Workflow Artifacts**: 7 days (configurable)
- **Git Repository**: Permanent (managed by repository retention policies)

## Security Considerations

- Uses Azure Government cloud (`AzureUSGovernment`)
- Service principal authentication with minimal required permissions
- Secrets stored in GitHub encrypted secrets
- No sensitive data exposed in logs

## Customization

### Adding New Environments
1. Add new environment variables to workflow
2. Add new secrets to repository
3. Update matrix configuration (for matrix workflow)
4. Add new job (for sequential workflow)

### Modifying Backup Schedule
Update the `on` triggers in the workflow files:
```yaml
on:
  schedule:
    - cron: '0 2 * * 0'  # Weekly on Sunday at 2 AM UTC
  workflow_dispatch:
```

### Changing File Retention
Modify `retention-days` in artifact upload steps:
```yaml
- name: Upload Artifacts
  uses: actions/upload-artifact@v4
  with:
    retention-days: 30  # Keep for 30 days
```

## Performance Comparison

| Workflow Type | Execution Time | Resource Usage | Failure Impact |
|---------------|----------------|----------------|----------------|
| Sequential    | ~20-30 minutes | Low            | Stops remaining environments |
| Matrix        | ~8-12 minutes  | High           | Continues other environments |

## Best Practices

1. **Use Matrix Workflow** for regular backups (faster execution)
2. **Monitor Logs** regularly for export failures
3. **Verify Backups** by checking committed files
4. **Update Credentials** before expiration
5. **Test Workflows** in development environment first

## Support

For issues or questions:
1. Check workflow run logs for detailed error messages
2. Verify Azure credentials and permissions
3. Check Azure service health status
4. Review repository security settings