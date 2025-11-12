# Lab 4: Lambda Layers for Code Reuse

## Overview
This lab demonstrates Lambda Layers for sharing common code and dependencies across multiple Lambda functions. This approach reduces deployment package sizes, improves code reusability, and simplifies maintenance.

## Architecture
![Architecture Diagram](screenshots/architecture.png)

## What We're Building
- **Lambda Layer**: Common utilities and dependencies
- **Instance Manager Function**: EC2 operations using shared layer
- **Resource Reporter Function**: AWS resource reporting using shared layer
- **Shared Dependencies**: boto3, requests, and custom utilities
- **Code Reuse**: Common CloudOps utilities across functions

## Key Features
✅ **Code Reuse**: Shared utilities across multiple functions  
✅ **Smaller Packages**: Functions without bundled dependencies  
✅ **Version Management**: Independent layer versioning  
✅ **Faster Deployments**: Cached layers reduce upload time  
✅ **Cost Optimization**: Reduced storage and transfer costs  

## Lambda Layer Structure
```
layer/
└── python/
    └── lib/
        └── python3.9/
            └── site-packages/
                ├── boto3/
                ├── requests/
                └── layer_utils.py
```

## Terraform Resources

### 1. Lambda Layer
- **Name**: `cloudops-common-layer`
- **Runtime**: Python 3.9
- **Contents**: boto3, requests, custom utilities

### 2. Lambda Functions
- **Instance Manager**: EC2 operations with layer utilities
- **Resource Reporter**: AWS resource analysis with layer utilities

### 3. Shared Utilities
- **CloudOpsUtils**: Common EC2 operations class
- **Helper Functions**: Validation and formatting utilities

## Deployment

### Step 1: Deploy Infrastructure
```bash
cd labs/lab4
terraform init
terraform plan
terraform apply
```
![Terraform Apply](screenshots/terraform-apply.png)

### Step 2: Verify Layer Creation
```bash
terraform output
```
![Terraform Output](screenshots/terraform-output.png)

## Testing

### Test 1: Instance Manager Function
```bash
# List all instances
aws lambda invoke --function-name cloudops-instance-manager --payload '{"action":"list","tag_key":"Environment","tag_value":"Dev"}' response.json

# List running instances only
aws lambda invoke --function-name cloudops-instance-manager --payload '{"action":"list_by_state","tag_key":"Environment","tag_value":"Dev","states":["running"]}' response.json

# Stop instances
aws lambda invoke --function-name cloudops-instance-manager --payload '{"action":"stop","tag_key":"Environment","tag_value":"Dev"}' response.json
```
![Instance Manager Test](screenshots/instance-manager-test.png)

### Test 2: Resource Reporter Function
```bash
# Resource summary
aws lambda invoke --function-name cloudops-resource-reporter --payload '{"report_type":"summary"}' response.json

# Detailed report
aws lambda invoke --function-name cloudops-resource-reporter --payload '{"report_type":"detailed","tag_key":"Environment","tag_value":"Dev"}' response.json

# Cost analysis
aws lambda invoke --function-name cloudops-resource-reporter --payload '{"report_type":"cost_analysis","tag_key":"Environment","tag_value":"Dev"}' response.json
```
![Resource Reporter Test](screenshots/resource-reporter-test.png)

## Layer Utilities

### CloudOpsUtils Class
```python
class CloudOpsUtils:
    def get_instances_by_tag(self, tag_key, tag_value, states=None)
    def bulk_instance_operation(self, instance_ids, operation)
    def get_resource_summary(self)
    def format_response(self, status_code, data, message=None)
```

### Helper Functions
```python
def get_tag_value(tags, key)
def validate_instance_ids(instance_ids)
```

## Function Capabilities

### Instance Manager
- **List Instances**: Filter by tags and states
- **Bulk Operations**: Start, stop, reboot multiple instances
- **Validation**: Instance ID format validation
- **Error Handling**: Comprehensive exception management

### Resource Reporter
- **Summary Report**: Region-wide resource overview
- **Detailed Report**: Enhanced instance information
- **Cost Analysis**: Hourly and monthly cost estimates
- **Grouping**: By state, type, and tags

## Benefits of Lambda Layers

### 1. Code Reuse
![Code Reuse](screenshots/code-reuse.png)

### 2. Smaller Deployment Packages
- **Without Layer**: 50MB+ per function
- **With Layer**: 5MB per function + 45MB layer (shared)

### 3. Faster Deployments
- **Layer Caching**: AWS caches layers separately
- **Incremental Updates**: Only function code changes

### 4. Version Management
```bash
# Layer versions
aws lambda list-layer-versions --layer-name cloudops-common-layer

# Function using specific layer version
aws lambda get-function --function-name cloudops-instance-manager
```

## Monitoring

### Layer Usage
![Layer Usage](screenshots/layer-usage.png)

### Function Performance
![Function Performance](screenshots/function-performance.png)

### Cost Comparison
![Cost Comparison](screenshots/cost-comparison.png)

## Advanced Features

### Layer Versioning
```hcl
resource "aws_lambda_layer_version" "cloudops_layer_v2" {
  filename   = "cloudops-layer-v2.zip"
  layer_name = "cloudops-common-layer"
  
  compatible_runtimes = ["python3.9", "python3.10"]
}
```

### Cross-Account Sharing
```hcl
resource "aws_lambda_layer_version_permission" "layer_permission" {
  layer_name     = aws_lambda_layer_version.cloudops_layer.layer_name
  version_number = aws_lambda_layer_version.cloudops_layer.version
  principal      = "123456789012"
  action         = "lambda:GetLayerVersion"
}
```

### Multiple Runtime Support
```hcl
compatible_runtimes = ["python3.8", "python3.9", "python3.10"]
```

## Best Practices

### Layer Design
✅ **Single Responsibility**: One purpose per layer  
✅ **Size Limits**: Keep layers under 50MB unzipped  
✅ **Version Control**: Tag layer versions appropriately  
✅ **Documentation**: Document layer contents and usage  

### Function Design
✅ **Import Optimization**: Import only needed modules  
✅ **Error Handling**: Handle layer import failures  
✅ **Testing**: Test with and without layers  
✅ **Dependencies**: Minimize external dependencies  

## Troubleshooting

### Common Issues
1. **Import Errors**: Check layer path structure
2. **Version Conflicts**: Verify compatible runtimes
3. **Size Limits**: Layer too large for deployment

### Debug Commands
```bash
# Check layer contents
aws lambda get-layer-version --layer-name cloudops-common-layer --version-number 1

# List function layers
aws lambda get-function-configuration --function-name cloudops-instance-manager

# Test layer import
python3 -c "from layer_utils import CloudOpsUtils; print('Layer imported successfully')"
```

## Cost Analysis

### Without Layers (2 functions)
- **Function 1**: 50MB deployment package
- **Function 2**: 50MB deployment package
- **Total Storage**: 100MB
- **Monthly Cost**: ~$0.50

### With Layers (2 functions + 1 layer)
- **Function 1**: 5MB deployment package
- **Function 2**: 5MB deployment package
- **Layer**: 45MB (shared)
- **Total Storage**: 55MB
- **Monthly Cost**: ~$0.28 (44% savings)

## Security Considerations
✅ **Layer Permissions**: Control access to layers  
✅ **Code Scanning**: Scan layer contents for vulnerabilities  
✅ **Version Management**: Use specific layer versions in production  
✅ **Access Logging**: Monitor layer usage and access  

## Next Steps
- **Lab 5**: Error Handling and Monitoring
- **Advanced**: Multi-region layer deployment
- **Integration**: CI/CD pipeline for layer updates

## Cleanup
```bash
terraform destroy
```
![Terraform Destroy](screenshots/terraform-destroy.png)