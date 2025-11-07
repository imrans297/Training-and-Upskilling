#!/bin/bash

# Get AWS Account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "=== Lambda Function Deployment ==="
echo "Account ID: $ACCOUNT_ID"

# Create deployment package
echo "Creating Lambda deployment package..."
zip lambda-function.zip lambda_function.py

# Create IAM role for Lambda
echo "Creating Lambda execution role..."
cat > lambda-role.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

aws iam create-role \
  --role-name lambda-execution-role \
  --assume-role-policy-document file://lambda-role.json

aws iam attach-role-policy \
  --role-name lambda-execution-role \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

# Wait for role to be available
sleep 10

# Create Lambda function
echo "Creating Lambda function..."
aws lambda create-function \
  --function-name multi-trigger-lambda \
  --runtime python3.9 \
  --role arn:aws:iam::$ACCOUNT_ID:role/lambda-execution-role \
  --handler lambda_function.lambda_handler \
  --zip-file fileb://lambda-function.zip

echo "Lambda function created successfully!"
echo "Function ARN: arn:aws:lambda:us-east-1:$ACCOUNT_ID:function:multi-trigger-lambda"