#!/bin/bash

# AMI CloudOps Lab Setup Script
echo "Setting up AMI CloudOps Lab Environment..."

# Check prerequisites
check_prerequisites() {
    echo "Checking prerequisites..."
    
    if ! command -v aws &> /dev/null; then
        echo "AWS CLI not found. Please install AWS CLI."
        exit 1
    fi
    
    if ! command -v terraform &> /dev/null; then
        echo "Terraform not found. Please install Terraform."
        exit 1
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        echo "AWS credentials not configured. Please run 'aws configure'."
        exit 1
    fi
    
    echo "Prerequisites check passed!"
}

# Verify key pair exists
verify_key_pair() {
    echo "Verifying key pair..."
    
    if ! aws ec2 describe-key-pairs --key-names dmoUser1Key &> /dev/null; then
        echo "Key pair 'dmoUser1Key' not found in AWS."
        exit 1
    fi
    
    if [ ! -f "/home/einfochips/backup/Keys/dmoUser1Key.pem" ]; then
        echo "Local key file not found at /home/einfochips/backup/Keys/dmoUser1Key.pem"
        exit 1
    fi
    
    echo "Key pair verification passed!"
}

# Deploy infrastructure
deploy_infrastructure() {
    echo "Deploying AMI lab infrastructure..."
    
    terraform init
    if [ $? -ne 0 ]; then
        echo "Terraform init failed!"
        exit 1
    fi
    
    terraform plan
    if [ $? -ne 0 ]; then
        echo "Terraform plan failed!"
        exit 1
    fi
    
    echo "Do you want to apply the Terraform configuration? (y/n)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        terraform apply -auto-approve
        if [ $? -eq 0 ]; then
            echo "Infrastructure deployed successfully!"
            echo ""
            echo "AMI Lab Environment Details:"
            echo "============================"
            terraform output
            echo ""
            echo "Next Steps:"
            echo "1. Wait 5-10 minutes for instances to fully initialize"
            echo "2. Access Golden AMI builder: $(terraform output -raw web_url_builder)"
            echo "3. SSH to builder: $(terraform output -raw ssh_command_builder)"
            echo "4. Follow the lab exercises in README.md"
        else
            echo "Terraform apply failed!"
            exit 1
        fi
    else
        echo "Deployment cancelled."
    fi
}

# Create helper scripts
create_helper_scripts() {
    echo "Creating helper scripts..."
    
    # AMI backup script
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
    
    # AMI cleanup script
    cat > ami-cleanup.sh << 'EOF'
#!/bin/bash
echo "Listing your AMIs..."
aws ec2 describe-images --owners self --query 'Images[*].[ImageId,Name,CreationDate]' --output table

echo ""
echo "To deregister an AMI, use:"
echo "aws ec2 deregister-image --image-id <AMI_ID>"
echo ""
echo "To delete associated snapshots:"
echo "aws ec2 describe-images --image-ids <AMI_ID> --query 'Images[*].BlockDeviceMappings[*].Ebs.SnapshotId' --output text | xargs -I {} aws ec2 delete-snapshot --snapshot-id {}"
EOF
    
    chmod +x ami-cleanup.sh
    
    echo "Helper scripts created: ami-backup.sh, ami-cleanup.sh"
}

# Main execution
main() {
    check_prerequisites
    verify_key_pair
    deploy_infrastructure
    create_helper_scripts
    
    echo ""
    echo "AMI CloudOps Lab setup completed!"
    echo ""
    echo "Available helper scripts:"
    echo "- ./ami-backup.sh    : Create backup AMI"
    echo "- ./ami-cleanup.sh   : List and cleanup AMIs"
    echo ""
    echo "For detailed exercises, see README.md"
}

# Run main function
main