#!/bin/bash

CLUSTER_NAME="AWS_EKS-cluster"
REGION="ap-south-1"

echo "🏷️  Verifying Tags for EKS Cluster: $CLUSTER_NAME"
echo "================================================"

# Check EC2 Instance Tags
echo -e "\n📦 EC2 Instance Tags:"
aws ec2 describe-instances \
  --region $REGION \
  --filters "Name=tag:Name,Values=${CLUSTER_NAME}-node" "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[].[InstanceId,Tags[?Key==`Name`].Value|[0],Tags[?Key==`Owner`].Value|[0],Tags[?Key==`Department`].Value|[0]]' \
  --output table

# Check ASG Tags
echo -e "\n🔄 Auto Scaling Group Tags:"
aws autoscaling describe-auto-scaling-groups \
  --region $REGION \
  --query "AutoScalingGroups[?contains(AutoScalingGroupName, '${CLUSTER_NAME}')].{Name:AutoScalingGroupName,Tags:Tags[?Key=='Owner' || Key=='Department' || Key=='ManagedBy']}" \
  --output table

# Check EBS Volume Tags
echo -e "\n💾 EBS Volume Tags:"
aws ec2 describe-volumes \
  --region $REGION \
  --filters "Name=tag:Name,Values=${CLUSTER_NAME}-node-volume" \
  --query 'Volumes[].[VolumeId,Tags[?Key==`Name`].Value|[0],Tags[?Key==`Owner`].Value|[0]]' \
  --output table

# Check VPC Tags
echo -e "\n🌐 VPC Tags:"
aws ec2 describe-vpcs \
  --region $REGION \
  --filters "Name=tag:Name,Values=${CLUSTER_NAME}-vpc" \
  --query 'Vpcs[].[VpcId,Tags[?Key==`Name`].Value|[0],Tags[?Key==`ManagedBy`].Value|[0]]' \
  --output table

# Check Security Group Tags
echo -e "\n🔒 Security Group Tags:"
aws ec2 describe-security-groups \
  --region $REGION \
  --filters "Name=tag:Name,Values=${CLUSTER_NAME}-*-sg" \
  --query 'SecurityGroups[].[GroupId,GroupName,Tags[?Key==`Owner`].Value|[0]]' \
  --output table

# Summary
echo -e "\n✅ Tag Verification Complete!"
echo "All resources should have the following tags:"
echo "  - Owner: imran.shaikh@einfochips.com"
echo "  - Department: PES-Digital"
echo "  - ManagedBy: Terraform"
echo "  - ENDDate: 30-11-2025"
