#!/bin/bash

# Get AWS Account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "=== ECS Fargate Deployment ==="
echo "Account ID: $ACCOUNT_ID"

# Create ECS cluster
echo "Creating ECS cluster..."
aws ecs create-cluster --cluster-name my-fargate-cluster

# Create task execution role
echo "Creating task execution role..."
cat > task-execution-role.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

aws iam create-role \
  --role-name ecsTaskExecutionRole \
  --assume-role-policy-document file://task-execution-role.json

aws iam attach-role-policy \
  --role-name ecsTaskExecutionRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy

# Create CloudWatch log group
echo "Creating CloudWatch log group..."
aws logs create-log-group --log-group-name /ecs/my-ecs-app

# Update task definition with account ID
sed "s/ACCOUNT_ID/$ACCOUNT_ID/g" task-definition.json > task-definition-updated.json

# Register task definition
echo "Registering task definition..."
aws ecs register-task-definition --cli-input-json file://task-definition-updated.json

echo "ECS setup complete!"
echo "Next: Build and push Docker image to ECR, then create ECS service"