# Managing EC2 at Scale - Systems Manager (SSM) Lab

## Overview
This lab provides hands-on experience with AWS Systems Manager (SSM) for managing EC2 instances at scale, including Session Manager, Run Command, Parameter Store, Patch Manager, and Maintenance Windows.

## Architecture
- VPC with public and private subnets
- Public instance (accessible via SSH and web)
- Private instance (accessible only via SSM Session Manager)
- NAT Gateway for private subnet internet access
- SSM-enabled instances with proper IAM roles
- Parameter Store for configuration management
- Maintenance Windows for automated patching

## Lab Exercises

### Exercise 1: Deploy Infrastructure
```bash
terraform init
terraform plan
terraform apply
```

### Exercise 2: Session Manager Access
```bash
# Connect to public instance via Session Manager
aws ssm start-session --target $(terraform output -raw public_instance_id)

# Connect to private instance via Session Manager (no SSH needed!)
aws ssm start-session --target $(terraform output -raw private_instance_id)

# Port forwarding example
aws ssm start-session \
  --target $(terraform output -raw public_instance_id) \
  --document-name AWS-StartPortForwardingSession \
  --parameters '{"portNumber":["80"],"localPortNumber":["8080"]}'
```

### Exercise 3: Run Command Operations
```bash
# Run command on all Production instances
aws ssm send-command \
  --document-name "AWS-RunShellScript" \
  --targets "Key=tag:Environment,Values=Production" \
  --parameters 'commands=["uptime","df -h","free -m"]'

# Run custom maintenance document
aws ssm send-command \
  --document-name "CloudOps-Maintenance" \
  --targets "Key=tag:Environment,Values=Production" \
  --parameters 'action=status'

# Check command execution status
COMMAND_ID=$(aws ssm send-command \
  --document-name "AWS-RunShellScript" \
  --targets "Key=instanceids,Values=$(terraform output -raw public_instance_id)" \
  --parameters 'commands=["echo Hello from SSM"]' \
  --query 'Command.CommandId' --output text)

aws ssm list-command-invocations --command-id $COMMAND_ID --details
```

### Exercise 4: Parameter Store Management
```bash
# Retrieve parameters
aws ssm get-parameter --name "/cloudops/database/host"
aws ssm get-parameter --name "/cloudops/database/password" --with-decryption

# Get all parameters by path
aws ssm get-parameters-by-path --path "/cloudops" --recursive

# Create new parameters
aws ssm put-parameter \
  --name "/cloudops/app/version" \
  --value "1.2.3" \
  --type "String" \
  --description "Application version"

aws ssm put-parameter \
  --name "/cloudops/app/api-key" \
  --value "secret-api-key-123" \
  --type "SecureString" \
  --description "API key for external service"

# Use parameters in commands
aws ssm send-command \
  --document-name "AWS-RunShellScript" \
  --targets "Key=instanceids,Values=$(terraform output -raw public_instance_id)" \
  --parameters 'commands=["echo Database host: $(aws ssm get-parameter --name /cloudops/database/host --query Parameter.Value --output text)"]'
```

### Exercise 5: Patch Management
```bash
# Scan for available patches
aws ssm send-command \
  --document-name "AWS-RunPatchBaseline" \
  --targets "Key=tag:Environment,Values=Production" \
  --parameters 'Operation=Scan'

# Install patches
aws ssm send-command \
  --document-name "AWS-RunPatchBaseline" \
  --targets "Key=tag:Environment,Values=Production" \
  --parameters 'Operation=Install'

# Check patch compliance
aws ssm describe-instance-patch-states \
  --instance-ids $(terraform output -raw public_instance_id)
```

### Exercise 6: Maintenance Windows
```bash
# List maintenance windows
aws ssm describe-maintenance-windows

# Get maintenance window details
aws ssm describe-maintenance-window-targets \
  --window-id $(terraform output -raw maintenance_window_id)

# Execute maintenance window manually (for testing)
aws ssm send-command \
  --document-name "AWS-RunPatchBaseline" \
  --targets "Key=tag:Environment,Values=Production" \
  --parameters 'Operation=Scan'
```

### Exercise 7: Inventory and Compliance
```bash
# Get instance inventory
aws ssm get-inventory \
  --filters "Key=AWS:InstanceInformation.InstanceId,Values=$(terraform output -raw public_instance_id)"

# List compliance items
aws ssm list-compliance-items \
  --resource-ids $(terraform output -raw public_instance_id) \
  --resource-types "ManagedInstance"

# Get compliance summary
aws ssm list-compliance-summaries \
  --filters "Key=ComplianceType,Values=Patch"
```

### Exercise 8: Automation Documents
```bash
# List available documents
aws ssm list-documents --filters "Key=DocumentType,Values=Command"

# Describe custom document
aws ssm describe-document --name "CloudOps-Maintenance"

# Execute custom maintenance actions
aws ssm send-command \
  --document-name "CloudOps-Maintenance" \
  --targets "Key=instanceids,Values=$(terraform output -raw public_instance_id)" \
  --parameters 'action=update'

aws ssm send-command \
  --document-name "CloudOps-Maintenance" \
  --targets "Key=instanceids,Values=$(terraform output -raw public_instance_id)" \
  --parameters 'action=install'
```

## Monitoring and Troubleshooting

### Check SSM Agent Status
```bash
# Via Session Manager
aws ssm start-session --target $(terraform output -raw public_instance_id)
# Then run: sudo systemctl status amazon-ssm-agent

# Via Run Command
aws ssm send-command \
  --document-name "AWS-RunShellScript" \
  --targets "Key=instanceids,Values=$(terraform output -raw public_instance_id)" \
  --parameters 'commands=["systemctl status amazon-ssm-agent"]'
```

### View CloudWatch Logs
```bash
# List log groups
aws logs describe-log-groups --log-group-name-prefix "/aws/ssm"

# View setup logs
aws logs get-log-events \
  --log-group-name "/aws/ssm/cloudops/setup" \
  --log-stream-name "$(terraform output -raw public_instance_id)"
```

### Instance Registration
```bash
# Check if instances are registered with SSM
aws ssm describe-instance-information

# Get specific instance info
aws ssm describe-instance-information \
  --filters "Key=InstanceIds,Values=$(terraform output -raw public_instance_id)"
```

## Best Practices Demonstrated

1. **IAM Roles**: Proper IAM roles with minimal required permissions
2. **Network Security**: Private instances accessible only via SSM
3. **Parameter Store**: Secure storage of configuration and secrets
4. **Automation**: Custom documents for standardized operations
5. **Maintenance Windows**: Scheduled patching and maintenance
6. **Monitoring**: CloudWatch integration for logging and metrics
7. **Compliance**: Patch management and compliance tracking

## Web Interface Access
- **Public Instance**: http://$(terraform output -raw public_instance_ip)
- Shows instance information and SSM capabilities

## Cleanup
```bash
terraform destroy
```

## Troubleshooting

### Common Issues
1. **Instance not showing in SSM**: Check IAM role and internet connectivity
2. **Session Manager not working**: Verify SSM agent is running
3. **Run Command fails**: Check instance status and permissions

### Useful Commands
```bash
# Check SSM agent logs
sudo tail -f /var/log/amazon/ssm/amazon-ssm-agent.log

# Restart SSM agent
sudo systemctl restart amazon-ssm-agent

# Check instance registration
aws ssm describe-instance-information --query 'InstanceInformationList[*].[InstanceId,PingStatus,LastPingDateTime]' --output table
```