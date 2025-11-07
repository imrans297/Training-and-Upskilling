#!/bin/bash

# Get AWS Account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "=== Building and Pushing Docker Image ==="
echo "Account ID: $ACCOUNT_ID"

# Navigate to app directory
cd ecs-app

# Login to ECR
echo "Logging into ECR..."
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# Build Docker image
echo "Building Docker image..."
docker build -t my-ecs-app .

# Tag image for ECR
echo "Tagging image..."
docker tag my-ecs-app:latest $ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/my-ecs-app:latest

# Push image to ECR
echo "Pushing image to ECR..."
docker push $ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/my-ecs-app:latest

echo "Image pushed successfully!"
echo "ECS tasks should now start automatically..."

# Wait and check service status
sleep 30
echo "Checking ECS service status..."
aws ecs describe-services --cluster my-fargate-cluster --services my-ecs-service --query 'services[0].[serviceName,runningCount,desiredCount]' --output table