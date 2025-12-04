#!/bin/bash

# Task 1: Deploy Lambda function for latest AMI selection

echo "=== Task 1: Deploying Latest AMI Lambda Function ==="

FUNCTION_NAME="gdp-web-task1-latest-ami"
ROLE_NAME="gdp-web-task1-lambda-role"

# Create IAM role for Lambda
echo "Creating IAM role..."
aws iam create-role \
    --role-name $ROLE_NAME \
    --assume-role-policy-document '{
        "Version": "2012-10-17",
        "Statement": [{
            "Effect": "Allow",
            "Principal": {"Service": "lambda.amazonaws.com"},
            "Action": "sts:AssumeRole"
        }]
    }' 2>/dev/null || echo "Role already exists"

# Attach policies
aws iam attach-role-policy \
    --role-name $ROLE_NAME \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

aws iam put-role-policy \
    --role-name $ROLE_NAME \
    --policy-name EC2ReadOnlyAccess \
    --policy-document '{
        "Version": "2012-10-17",
        "Statement": [{
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeImages"
            ],
            "Resource": "*"
        }]
    }'

echo "Waiting for role to be available..."
sleep 10

# Package Lambda function
zip -q function.zip task1-lambda-latest-ami.py

# Get account ID and create role ARN
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"

# Deploy Lambda function
echo "Deploying Lambda function..."
aws lambda create-function \
    --function-name $FUNCTION_NAME \
    --runtime python3.11 \
    --role $ROLE_ARN \
    --handler task1-lambda-latest-ami.lambda_handler \
    --zip-file fileb://function.zip \
    --timeout 30 \
    --description "Task 1: Get latest AMI for GDP-Web applications" 2>/dev/null || {
    
    echo "Function exists, updating..."
    aws lambda update-function-code \
        --function-name $FUNCTION_NAME \
        --zip-file fileb://function.zip
}

echo "✓ Lambda function deployed: $FUNCTION_NAME"

# Test the function
echo ""
echo "=== Testing Lambda Function ==="
aws lambda invoke \
    --function-name $FUNCTION_NAME \
    --payload '{}' \
    output.json

echo "Lambda output:"
cat output.json | jq .

# Cleanup
rm -f function.zip output.json

echo ""
echo "✅ Task 1 Lambda Complete!"
echo "Function: $FUNCTION_NAME"
echo "Test: aws lambda invoke --function-name $FUNCTION_NAME --payload '{}' result.json"