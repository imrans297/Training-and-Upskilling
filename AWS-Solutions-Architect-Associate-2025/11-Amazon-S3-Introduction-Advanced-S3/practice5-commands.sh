#!/bin/bash

# Practice 5: S3 Event Notifications
echo "=== S3 Event Notifications Setup ==="

# Step 1: Create SNS Topic
echo "Creating SNS topic..."
aws sns create-topic --name s3-notifications

# Get your account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "Account ID: $ACCOUNT_ID"

# Step 2: Subscribe email to SNS topic
echo "Subscribing email to SNS topic..."
aws sns subscribe \
  --topic-arn arn:aws:sns:us-east-1:$ACCOUNT_ID:s3-notifications \
  --protocol email \
  --notification-endpoint imradev29@gmail.com

# Step 3: Create Lambda function (requires zip file)
echo "Creating Lambda deployment package..."
zip lambda-function.zip lambda-s3-processor.py

# Create Lambda function
echo "Creating Lambda function..."
aws lambda create-function \
  --function-name process-s3-uploads \
  --runtime python3.9 \
  --role arn:aws:iam::$ACCOUNT_ID:role/lambda-execution-role \
  --handler lambda-s3-processor.lambda_handler \
  --zip-file fileb://lambda-function.zip

# Step 4: Add S3 permission to Lambda
echo "Adding S3 permission to Lambda..."
aws lambda add-permission \
  --function-name process-s3-uploads \
  --principal s3.amazonaws.com \
  --action lambda:InvokeFunction \
  --statement-id s3-trigger \
  --source-arn arn:aws:s3:::my-unique-bucket-name-12366645

# Step 5: Configure S3 event notifications
echo "Configuring S3 event notifications..."
# Update the ARNs in the config file with actual account ID
sed "s/account-id/$ACCOUNT_ID/g" s3-event-notification-config.json > s3-event-config-updated.json

aws s3api put-bucket-notification-configuration \
  --bucket my-unique-bucket-name-12366645 \
  --notification-configuration file://s3-event-config-updated.json

# Step 6: Test event notifications
echo "Testing event notifications..."
echo "Test content for S3 event notification" > test-notification.txt
aws s3 cp test-notification.txt s3://my-unique-bucket-name-12366645/uploads/test-notification.jpg

echo "=== Setup Complete ==="
echo "Check your email for SNS notification"
echo "Check CloudWatch logs for Lambda execution"