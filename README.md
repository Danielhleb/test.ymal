# ALM Environment ARM Templates Backup

This repository contains a GitHub Actions workflow for backing up ARM templates from multiple Azure environments in the ALM (Application Lifecycle Management) pipeline.

## Overview

The workflow automatically exports ARM templates from all resource groups in four Azure environments:
- **TEST** - Test environment
- **DEV** - Development environment  
- **PREPROD** - Pre-production environment
- **PROD** - Production environment

## Features

### ✨ Key Improvements Over Original

1. **Eliminated Code Duplication** - Uses reusable composite actions
2. **Enhanced Error Handling** - Better validation and fallback mechanisms
3. **Improved Security** - Updated to latest action versions and better practices
4. **Flexible Execution** - Can run for specific environments or all at once
5. **Better Logging** - Comprehensive logging with success/error counts
6. **Summary Reports** - Generates detailed backup summaries
7. **Conditional Execution** - Jobs can run independently based on needs

### 🔧 Technical Features

- **Reusable Actions**: Centralized backup logic in `.github/actions/backup-arm-templates`
- **Input Validation**: Comprehensive validation of all inputs
- **JSON Validation**: Verifies exported templates are valid JSON
- **Fallback Methods**: Alternative export methods when primary fails
- **Detailed Logging**: Step-by-step progress with success/error indicators
- **Artifact Management**: Proper artifact upload/download with retention policies
- **Git Integration**: Automatic commits with detailed commit messages

## Workflow Structure

```
.github/
├── workflows/
│   └── alm-arm-backup.yml          # Main workflow file
└── actions/
    └── backup-arm-templates/
        └── action.yml              # Reusable backup action
```

## Triggers

The workflow can be triggered by:

1. **Push to main/master branch** - Automatic backup of all environments
2. **Pull Request to main/master** - Backup for validation
3. **Manual dispatch** - Choose specific environment(s) to backup

### Manual Dispatch Options

When manually triggering the workflow, you can select:
- `all` - Backup all environments (default)
- `test` - Backup only TEST environment
- `dev` - Backup only DEV environment  
- `pre` - Backup only PREPROD environment
- `prod` - Backup only PROD environment

## Environment Variables

The workflow uses the following Azure service principal credentials:

| Environment | Client ID Secret | Client Secret Secret | Subscription ID Secret |
|-------------|------------------|---------------------|------------------------|
| TEST | `AZURE_CLIENT_ID_SECRETS_APPREG_ALMCICD_TEST_USGOVVA_01_CLIENT_ID` | `AZURE_CLIENT_SECRET_SECRETS_APPREG_ALMCICD_TEST_USGOVVA_01_CLIENT_SECRET` | `AZURE_SUBSCRIPTION_ID_SECRETS_TEST_SUBCRIPTION_ID` |
| DEV | `AZURE_CLIENT_ID_SECRETS_APPREG_ALMCICD_DEV_USGOVVA_01_CLIENT_ID` | `AZURE_CLIENT_SECRET_SECRETS_APPREG_ALMCICD_DEV_USGOVVA_01_CLIENT_SECRET` | `AZURE_SUBSCRIPTION_ID_SECRETS_DEV_SUBCRIPTION_ID` |
| PREPROD | `AZURE_CLIENT_ID_SECRETS_APPREG_ALMCICD_PRE_USGOVVA_01_CLIENT_ID` | `AZURE_CLIENT_SECRET_SECRETS_APPREG_ALMCICD_PRE_USGOVVA_01_CLIENT_SECRET` | `AZURE_SUBSCRIPTION_ID_SECRETS_PRE_SUBCRIPTION_ID` |
| PROD | `AZURE_CLIENT_ID_SECRETS_APPREG_ALMCICD_PRD_USGOVVA_01_CLIENT_ID` | `AZURE_CLIENT_SECRET_SECRETS_APPREG_ALMCICD_PRD_USGOVVA_01_CLIENT_SECRET` | `AZURE_SUBSCRIPTION_ID_SECRETS_PRD_SUBCRIPTION_ID` |

**Common Secret**: `AZURE_TENANT_ID_SECRETS_TENANT_ID`

## Output Structure

Backups are organized as follows:

```
ALM-{ENVIRONMENT}/
├── {ResourceGroup1}/
│   ├── {ResourceGroup1}_{timestamp}.json
│   └── ...
├── {ResourceGroup2}/
│   ├── {ResourceGroup2}_{timestamp}.json
│   └── ...
└── backup_summary_{timestamp}.json
```

### Summary Report Format

Each environment generates a summary report with:

```json
{
  "environment": "TEST",
  "subscription_id": "subscription-id",
  "backup_timestamp": "20241201-143022",
  "backup_date": "2024-12-01 14:30:22 UTC",
  "summary": {
    "successful_exports": 5,
    "failed_exports": 1,
    "total_resource_groups": 6
  },
  "triggered_by": "push",
  "commit_sha": "abc123..."
}
```

## Jobs and Dependencies

The workflow runs jobs sequentially to ensure proper resource management:

1. **backup-alm-test** - Backs up TEST environment
2. **backup-alm-dev** - Backs up DEV environment (depends on test)
3. **backup-alm-pre** - Backs up PREPROD environment (depends on dev)
4. **backup-alm-prod** - Backs up PROD environment (depends on pre)
5. **push-all-backups** - Commits all backups to repository (depends on all)

## Error Handling

### Export Failures

When ARM template export fails, the workflow:

1. **Primary Method**: Uses `az group export` with parameters
2. **Fallback Method**: Tries `az deployment group list` to get template
3. **Error File**: Creates error JSON if both methods fail

### Validation

- **Input Validation**: All required parameters are validated
- **Azure Context**: Verifies subscription context is set correctly
- **JSON Validation**: Validates exported templates are valid JSON
- **File Size**: Reports file sizes for monitoring

## Security Considerations

- Uses latest GitHub Actions versions
- Implements proper secret management
- Uses service principal authentication
- Follows least privilege principle
- Validates all inputs and outputs

## Monitoring and Logging

### Log Levels

- **✓ Success**: Successful operations
- **⚠ Warning**: Non-critical issues
- **✗ Error**: Failed operations

### Metrics Tracked

- Number of successful exports
- Number of failed exports
- Total resource groups processed
- File sizes and validation results
- Execution time and timestamps

## Troubleshooting

### Common Issues

1. **Authentication Failures**
   - Verify service principal credentials
   - Check subscription access permissions
   - Ensure tenant ID is correct

2. **Export Failures**
   - Resource groups may not have exportable resources
   - Check Azure CLI version compatibility
   - Verify resource group permissions

3. **JSON Validation Errors**
   - Exported templates may be malformed
   - Check Azure resource state
   - Review export parameters

### Debug Steps

1. Check workflow logs for detailed error messages
2. Verify all secrets are properly configured
3. Test Azure CLI commands manually
4. Review summary reports for specific failures

## Contributing

When contributing to this workflow:

1. Test changes in a development environment
2. Update documentation for any new features
3. Follow the existing code structure
4. Add appropriate error handling
5. Update version numbers for actions

## License

This project is licensed under the MIT License - see the LICENSE file for details.