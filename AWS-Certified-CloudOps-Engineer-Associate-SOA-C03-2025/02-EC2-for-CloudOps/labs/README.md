# EC2 for CloudOps - Lab Environment

## Overview
This lab environment provides hands-on experience with EC2 instance management, monitoring, and CloudOps best practices.

## Architecture
- VPC with public subnet
- EC2 instance with CloudWatch monitoring
- Security group with HTTP/HTTPS/SSH access
- IAM role with CloudWatch and SSM permissions
- EBS volumes for storage management

## Prerequisites
1. AWS CLI configured
2. Terraform installed
3. Existing key pair "dmoUser1Key" in AWS

## Setup Instructions

### 1. Verify Key Pair
```bash
# Verify the key pair exists in AWS
aws ec2 describe-key-pairs --key-names dmoUser1Key

# Verify local key file
ls -la /home/einfochips/backup/Keys/dmoUser1Key
```

### 2. Deploy Infrastructure
```bash
terraform init
terraform plan
terraform apply
```

### 3. Connect to Instance
```bash
# Use the SSH command from terraform output
terraform output ssh_command

# Or manually
ssh -i /home/einfochips/backup/Keys/dmoUser1Key ec2-user@<PUBLIC_IP>
```

## Lab Exercises

### Exercise 1: Instance Management
```bash
# View instance details
aws ec2 describe-instances --instance-ids $(terraform output -raw instance_id)

# Stop instance
aws ec2 stop-instances --instance-ids $(terraform output -raw instance_id)

# Start instance
aws ec2 start-instances --instance-ids $(terraform output -raw instance_id)
```

### Exercise 2: Monitoring
```bash
# View CloudWatch metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=$(terraform output -raw instance_id) \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average
```

### Exercise 3: Storage Management
```bash
# List EBS volumes
aws ec2 describe-volumes --filters "Name=attachment.instance-id,Values=$(terraform output -raw instance_id)"

# Create snapshot
aws ec2 create-snapshot \
  --volume-id <VOLUME_ID> \
  --description "EC2 Lab Snapshot"
```

### Exercise 4: Instance Metadata
```bash
# From within the instance
curl http://169.254.169.254/latest/meta-data/instance-id
curl http://169.254.169.254/latest/meta-data/public-ipv4
curl http://169.254.169.254/latest/user-data
```

## Web Server Access
Access the web server at: `http://<PUBLIC_IP>`

## Cleanup
```bash
terraform destroy
```

## Troubleshooting

### Common Issues
1. **SSH Connection Refused**: Check security group rules
2. **Instance Not Starting**: Check CloudWatch logs
3. **Web Server Not Accessible**: Verify httpd service status

### Useful Commands
```bash
# Check instance status
aws ec2 describe-instance-status --instance-ids $(terraform output -raw instance_id)

# Get console output
aws ec2 get-console-output --instance-id $(terraform output -raw instance_id)

# View system logs via SSM
aws ssm start-session --target $(terraform output -raw instance_id)
```