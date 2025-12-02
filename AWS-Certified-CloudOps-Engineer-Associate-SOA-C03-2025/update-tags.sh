#!/bin/bash

# Script to update standard tags across all sections
echo "🏷️  Updating standard tags across all CloudOps sections..."

# Define the standard tags template
TAGS_TEMPLATE='# Standard Tags
locals {
  common_tags = {
    Owner       = "Imran Shaikh"
    Project     = "Internal POC"
    DM          = "Kalpesh Kumal"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}'

# List of all sections
SECTIONS=(
    "01-Introduction-Requirements"
    "02-EC2-for-CloudOps"
    "03-AMI-Amazon-Machine-Image"
    "04-Managing-EC2-at-Scale-SSM"
    "05-EC2-High-Availability-Scalability"
    "06-CloudFormation-for-CloudOps"
    "07-Lambda-for-CloudOps"
    "08-EC2-Storage-Data-Management-EBS-EFS"
    "09-Amazon-S3-Introduction"
    "10-Advanced-Amazon-S3-Athena"
    "11-Amazon-S3-Security"
    "12-Advanced-Storage-Section"
    "13-CloudFront"
    "14-Databases-for-CloudOps"
    "15-Monitoring-Auditing-Performance"
    "16-AWS-Account-Management"
    "17-Disaster-Recovery"
    "18-Security-and-Compliance"
    "19-Identity"
    "20-Networking-Route53"
    "21-Networking-VPC"
)

# Update each section
for section in "${SECTIONS[@]}"; do
    echo "📁 Processing section: $section"
    
    # Create labs directory if it doesn't exist
    mkdir -p "$section/labs"
    
    # Create or update variables.tf with standard tags
    SECTION_TAGS=$(echo "$TAGS_TEMPLATE" | sed "s/SECTION_NAME/$section/g")
    
    if [ -f "$section/labs/variables.tf" ]; then
        # Check if tags already exist
        if ! grep -q "common_tags" "$section/labs/variables.tf"; then
            echo "" >> "$section/labs/variables.tf"
            echo "$SECTION_TAGS" >> "$section/labs/variables.tf"
            echo "  ✅ Added standard tags to $section/labs/variables.tf"
        else
            echo "  ℹ️  Tags already exist in $section/labs/variables.tf"
        fi
    else
        # Create basic variables.tf with standard structure
        cat > "$section/labs/variables.tf" << EOF
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "cloudops"
}

$SECTION_TAGS
EOF
        echo "  ✅ Created $section/labs/variables.tf with standard tags"
    fi
done

echo ""
echo "🎯 Standard tags update completed!"
echo ""
echo "📋 Standard Tags Applied:"
echo "   Owner: Imran Shaikh"
echo "   Project: Internal POC"
echo "   DM: Kalpesh Kumal"
echo "   Environment: \${var.environment}"
echo "   ManagedBy: Terraform"
echo ""
echo "💡 Usage in Terraform resources:"
echo "   tags = merge(local.common_tags, {"
echo "     Name = \"Resource-Name\""
echo "   })"