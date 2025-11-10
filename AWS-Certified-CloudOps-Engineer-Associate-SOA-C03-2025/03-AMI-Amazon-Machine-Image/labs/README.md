# AMI (Amazon Machine Image) - Lab Environment

## Overview
This lab provides hands-on experience with AMI creation, management, encryption, and lifecycle operations.

## Architecture
- VPC with public subnet
- Golden AMI builder instance
- Custom AMI creation from builder
- Instance launched from custom AMI
- KMS encryption for AMIs

## Lab Exercises

### Exercise 1: Deploy Infrastructure
```bash
terraform init
terraform plan
terraform apply
```

### Exercise 2: Access Golden AMI Builder
```bash
# SSH to builder instance
terraform output ssh_command_builder

# Access web interface
terraform output web_url_builder
```

### Exercise 3: Manual AMI Creation
```bash
# Connect to builder instance
ssh -i /home/einfochips/backup/Keys/dmoUser1Key.pem ec2-user@<BUILDER_IP>

# Prepare instance for AMI creation
sudo /opt/prepare-for-ami.sh

# Exit and create AMI manually
aws ec2 create-image \
  --instance-id $(terraform output -raw golden_ami_builder_id) \
  --name "manual-golden-ami-$(date +%Y%m%d)" \
  --description "Manually created Golden AMI" \
  --no-reboot
```

### Exercise 4: AMI Operations
```bash
# List your AMIs
aws ec2 describe-images --owners self --query 'Images[*].[ImageId,Name,State]' --output table

# Copy AMI to another region
aws ec2 copy-image \
  --source-region us-east-1 \
  --source-image-id $(terraform output -raw golden_ami_id) \
  --name "copied-golden-ami" \
  --region us-west-2

# Create encrypted AMI copy
aws ec2 copy-image \
  --source-region us-east-1 \
  --source-image-id $(terraform output -raw golden_ami_id) \
  --name "encrypted-golden-ami" \
  --encrypted \
  --kms-key-id $(terraform output -raw kms_key_id)
```

### Exercise 5: AMI Sharing
```bash
# Share AMI with another account (replace with actual account ID)
aws ec2 modify-image-attribute \
  --image-id $(terraform output -raw golden_ami_id) \
  --launch-permission "Add=[{UserId=123456789012}]"

# Remove sharing permissions
aws ec2 modify-image-attribute \
  --image-id $(terraform output -raw golden_ami_id) \
  --launch-permission "Remove=[{UserId=123456789012}]"
```

### Exercise 6: Launch Instance from AMI
```bash
# Launch instance using AWS CLI
aws ec2 run-instances \
  --image-id $(terraform output -raw golden_ami_id) \
  --instance-type t3.micro \
  --key-name dmoUser1Key \
  --security-group-ids $(aws ec2 describe-security-groups --filters "Name=group-name,Values=ami-lab-sg*" --query 'SecurityGroups[0].GroupId' --output text) \
  --subnet-id $(aws ec2 describe-subnets --filters "Name=tag:Name,Values=AMI-Lab-Public-Subnet" --query 'Subnets[0].SubnetId' --output text) \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=CLI-Launched-Instance}]'
```

### Exercise 7: AMI Lifecycle Management
```bash
# Create AMI backup script
cat > ami-backup.sh << 'EOF'
#!/bin/bash
INSTANCE_ID="$(terraform output -raw golden_ami_builder_id)"
AMI_NAME="backup-$(date +%Y%m%d-%H%M%S)"

echo "Creating backup AMI: $AMI_NAME"
AMI_ID=$(aws ec2 create-image \
  --instance-id $INSTANCE_ID \
  --name $AMI_NAME \
  --no-reboot \
  --query 'ImageId' \
  --output text)

echo "Created AMI: $AMI_ID"

# Tag the AMI
aws ec2 create-tags \
  --resources $AMI_ID \
  --tags Key=Type,Value=Backup Key=CreatedDate,Value=$(date +%Y-%m-%d)

echo "AMI backup completed: $AMI_ID"
EOF

chmod +x ami-backup.sh
./ami-backup.sh
```

### Exercise 8: AMI Cleanup
```bash
# List old AMIs (older than 30 days)
aws ec2 describe-images \
  --owners self \
  --query 'Images[?CreationDate<=`2024-01-01`].[ImageId,Name,CreationDate]' \
  --output table

# Deregister AMI (replace with actual AMI ID)
aws ec2 deregister-image --image-id ami-xxxxxxxxx

# Delete associated snapshots
aws ec2 describe-images \
  --image-ids ami-xxxxxxxxx \
  --query 'Images[*].BlockDeviceMappings[*].Ebs.SnapshotId' \
  --output text | xargs -I {} aws ec2 delete-snapshot --snapshot-id {}
```

## Monitoring and Troubleshooting

### Check AMI Status
```bash
# Check AMI creation status
aws ec2 describe-images \
  --image-ids $(terraform output -raw golden_ami_id) \
  --query 'Images[*].[ImageId,State,StateReason]'

# Find instances using specific AMI
aws ec2 describe-instances \
  --filters "Name=image-id,Values=$(terraform output -raw golden_ami_id)" \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress]'
```

### AMI Best Practices
1. **Use no-reboot option** for production instances
2. **Tag AMIs** with creation date and purpose
3. **Test AMIs** before production deployment
4. **Implement lifecycle management** for old AMIs
5. **Encrypt sensitive AMIs**
6. **Document AMI contents** and configurations

## Cleanup
```bash
# Destroy all resources
terraform destroy

# Manual cleanup if needed
aws ec2 deregister-image --image-id <AMI_ID>
aws ec2 delete-snapshot --snapshot-id <SNAPSHOT_ID>
```

## Troubleshooting

### Common Issues
1. **AMI creation fails**: Check instance state and permissions
2. **Instance won't boot from AMI**: Verify AMI preparation steps
3. **Encryption issues**: Check KMS key permissions

### Useful Commands
```bash
# Check AMI creation progress
aws ec2 describe-images --image-ids <AMI_ID> --query 'Images[0].State'

# View AMI block device mappings
aws ec2 describe-images --image-ids <AMI_ID> --query 'Images[0].BlockDeviceMappings'

# Check instance system log
aws ec2 get-console-output --instance-id <INSTANCE_ID>
```