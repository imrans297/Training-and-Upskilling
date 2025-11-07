#!/bin/bash

echo "=== Creating ECS Service ==="

# Get default VPC and subnets
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=is-default,Values=true" --query 'Vpcs[0].VpcId' --output text)
echo "Using VPC: $VPC_ID"

# Create security group for ECS tasks
SG_ID=$(aws ec2 create-security-group \
  --group-name ecs-fargate-sg \
  --description "Security group for ECS Fargate tasks" \
  --vpc-id $VPC_ID \
  --query 'GroupId' --output text 2>/dev/null || \
  aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=ecs-fargate-sg" \
  --query 'SecurityGroups[0].GroupId' --output text)

echo "Security Group: $SG_ID"

# Allow inbound traffic on port 5000
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 5000 \
  --cidr 0.0.0.0/0 2>/dev/null || echo "Port 5000 already allowed"

# Get subnet IDs
SUBNET_IDS=$(aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'Subnets[0:2].SubnetId' \
  --output text | tr '\t' ',')

echo "Subnets: $SUBNET_IDS"

# Create ECS service
echo "Creating ECS service..."
aws ecs create-service \
  --cluster my-fargate-cluster \
  --service-name my-ecs-service \
  --task-definition my-ecs-app:1 \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_IDS],securityGroups=[$SG_ID],assignPublicIp=ENABLED}"

echo "ECS service created! Waiting for tasks to start..."
sleep 30

# Check service status
aws ecs describe-services \
  --cluster my-fargate-cluster \
  --services my-ecs-service \
  --query 'services[0].[serviceName,status,runningCount,desiredCount]' \
  --output table