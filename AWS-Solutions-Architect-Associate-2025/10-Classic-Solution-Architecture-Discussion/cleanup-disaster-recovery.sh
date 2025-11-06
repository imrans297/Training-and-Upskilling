#!/bin/bash
# cleanup-disaster-recovery.sh - Complete cleanup script for disaster recovery resources

echo "🧹 Starting Disaster Recovery Cleanup..."

# ===== SECONDARY REGION (us-west-2) CLEANUP =====
echo "Cleaning up Secondary Region (us-west-2)..."

# Delete Auto Scaling Group
aws autoscaling delete-auto-scaling-group \
  --auto-scaling-group-name webapp-dr-secondary-asg \
  --force-delete \
  --region us-west-2

# Delete Load Balancer
aws elbv2 delete-load-balancer \
  --load-balancer-arn arn:aws:elasticloadbalancing:us-west-2:535537926657:loadbalancer/app/webapp-dr-secondary-alb/7068f9c88e2ca623 \
  --region us-west-2

# Delete Target Group
aws elbv2 delete-target-group \
  --target-group-arn arn:aws:elasticloadbalancing:us-west-2:535537926657:targetgroup/webapp-dr-secondary-tg/78e51cb5a065312c \
  --region us-west-2

# Delete Launch Template
aws ec2 delete-launch-template \
  --launch-template-name webapp-dr-secondary-template \
  --region us-west-2

# Delete RDS Read Replica
aws rds delete-db-instance \
  --db-instance-identifier webapp-db-replica \
  --skip-final-snapshot \
  --region us-west-2

echo "Waiting for RDS replica deletion..."
aws rds wait db-instance-deleted \
  --db-instance-identifier webapp-db-replica \
  --region us-west-2

# Delete Security Group
aws ec2 delete-security-group \
  --group-id sg-0d00542e5e2a359be \
  --region us-west-2

# Delete Subnets
aws ec2 delete-subnet --subnet-id subnet-06b3320d93ab11d7d --region us-west-2
aws ec2 delete-subnet --subnet-id subnet-0c29d9376cdb27dae --region us-west-2
aws ec2 delete-subnet --subnet-id subnet-0510662562267897f --region us-west-2
aws ec2 delete-subnet --subnet-id subnet-0ad6a74046392643d --region us-west-2

# Delete Route Table
aws ec2 delete-route-table --route-table-id rtb-0411bd3308a081c89 --region us-west-2

# Detach and Delete Internet Gateway
aws ec2 detach-internet-gateway \
  --internet-gateway-id igw-0ad43b891927fb469 \
  --vpc-id vpc-03f56af86b8d9f6c5 \
  --region us-west-2
aws ec2 delete-internet-gateway --internet-gateway-id igw-0ad43b891927fb469 --region us-west-2

# Delete VPC
aws ec2 delete-vpc --vpc-id vpc-03f56af86b8d9f6c5 --region us-west-2

# Delete KMS Key
aws kms schedule-key-deletion \
  --key-id 1fe69e14-1ef3-448e-842b-8b2a9738ace6 \
  --pending-window-in-days 7 \
  --region us-west-2

# ===== PRIMARY REGION (us-east-1) CLEANUP =====
echo "Cleaning up Primary Region (us-east-1)..."

# Delete RDS Primary Instance
aws rds delete-db-instance \
  --db-instance-identifier webapp-db-primary \
  --skip-final-snapshot \
  --region us-east-1

echo "Waiting for RDS primary deletion..."
aws rds wait db-instance-deleted \
  --db-instance-identifier webapp-db-primary \
  --region us-east-1

# Delete DB Subnet Group
aws rds delete-db-subnet-group \
  --db-subnet-group-name webapp-db-subnet-group \
  --region us-east-1

# Delete VPC (will delete associated subnets, route tables, etc.)
aws ec2 delete-vpc --vpc-id vpc-058fcde6ddde54019 --region us-east-1

# Delete S3 Buckets
TIMESTAMP=$(date +%Y%m%d)
aws s3 rm s3://webapp-dr-primary-bucket-$TIMESTAMP --recursive 2>/dev/null
aws s3 rb s3://webapp-dr-primary-bucket-$TIMESTAMP 2>/dev/null
aws s3 rm s3://webapp-dr-secondary-bucket-$TIMESTAMP --recursive --region us-west-2 2>/dev/null
aws s3 rb s3://webapp-dr-secondary-bucket-$TIMESTAMP --region us-west-2 2>/dev/null

# Delete IAM Role and Policies
aws iam detach-role-policy \
  --role-name S3ReplicationRole \
  --policy-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/S3ReplicationPolicy 2>/dev/null
aws iam delete-policy \
  --policy-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/S3ReplicationPolicy 2>/dev/null
aws iam delete-role --role-name S3ReplicationRole 2>/dev/null

# Clean up local files
rm -f replication-*.json secondary-user-data.sh promote-replica.sh deploy-secondary.sh verify-sync.sh

echo "✅ Disaster Recovery Cleanup Complete!"
echo "Note: KMS key scheduled for deletion in 7 days"