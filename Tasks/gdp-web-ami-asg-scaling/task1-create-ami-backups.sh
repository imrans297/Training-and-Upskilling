#!/bin/bash

# Task 1: Create AMI backups for GDP-Web instances

echo "=== Task 1: Creating AMI Backups ==="

# Get running instances
INSTANCES=$(aws ec2 describe-instances \
    --filters "Name=tag:Application,Values=gdp-web-1,gdp-web-2,gdp-web-3" "Name=instance-state-name,Values=running" \
    --query 'Reservations[].Instances[].[Tags[?Key==`Application`].Value|[0],InstanceId]' \
    --output text)

echo "Found instances:"
echo "$INSTANCES"

# Create AMI backups
while read -r app_name instance_id; do
    if [ -n "$app_name" ] && [ -n "$instance_id" ]; then
        timestamp=$(date -u +%Y-%m-%d-%H-%M)
        ami_name="${app_name}-${timestamp}"
        
        echo "Creating AMI backup: $ami_name for $instance_id"
        
        ami_id=$(aws ec2 create-image \
            --instance-id $instance_id \
            --name "$ami_name" \
            --description "AMI backup for $app_name" \
            --no-reboot \
            --query 'ImageId' \
            --output text)
        
        echo "✓ Created AMI: $ami_id ($ami_name)"
        
        # Tag the AMI
        aws ec2 create-tags \
            --resources $ami_id \
            --tags Key=Name,Value="$ami_name" Key=Application,Value="$app_name" Key=BackupDate,Value="$timestamp"
    fi
done <<< "$INSTANCES"

echo ""
echo "=== AMI Backups Created ==="
aws ec2 describe-images \
    --owners self \
    --filters "Name=name,Values=gdp-web-*" \
    --query 'Images[].[Name,ImageId,CreationDate,State]' \
    --output table

echo ""
echo "✅ Task 1 Complete: AMI backups created with naming convention gdp-web-X-YYYY-MM-DD-HH-MM"