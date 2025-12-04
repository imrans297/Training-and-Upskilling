#!/bin/bash

# Deploy Event-Driven Lambda for Dynamic AMI Triggering

echo "=== Deploying Event-Driven Lambda Setup ==="

FUNCTION_NAME="gdp-web-event-driven-ami"
ROLE_NAME="gdp-web-event-lambda-role"

# Create IAM role
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
    --policy-name EC2ImageAccess \
    --policy-document '{
        "Version": "2012-10-17",
        "Statement": [{
            "Effect": "Allow",
            "Action": ["ec2:DescribeImages"],
            "Resource": "*"
        }]
    }'

sleep 10

# Package function
zip -q function.zip event-driven-lambda.py

# Get role ARN
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"

# Deploy function
echo "Deploying Lambda function..."
aws lambda create-function \
    --function-name $FUNCTION_NAME \
    --runtime python3.11 \
    --role $ROLE_ARN \
    --handler event-driven-lambda.lambda_handler \
    --zip-file fileb://function.zip \
    --timeout 30 \
    --description "Event-driven Lambda for specific AMI backup triggering" 2>/dev/null || {
    
    echo "Function exists, updating..."
    aws lambda update-function-code \
        --function-name $FUNCTION_NAME \
        --zip-file fileb://function.zip
}

# Create EventBridge Rule
echo "Creating EventBridge Rule..."
aws events put-rule \
    --name gdp-web-ami-creation-rule \
    --description "Trigger Lambda when GDP-Web AMI is created" \
    --event-pattern '{
        "source": ["aws.ec2"],
        "detail-type": ["AWS API Call via CloudTrail"],
        "detail": {
            "eventSource": ["ec2.amazonaws.com"],
            "eventName": ["CreateImage"],
            "responseElements": {
                "imageId": [{"exists": true}]
            }
        }
    }' \
    --state ENABLED 2>/dev/null || echo "Rule exists"

# Add Lambda target to EventBridge rule
echo "Adding Lambda target to EventBridge rule..."
LAMBDA_ARN="arn:aws:lambda:$(aws configure get region):${ACCOUNT_ID}:function:${FUNCTION_NAME}"

aws events put-targets \
    --rule gdp-web-ami-creation-rule \
    --targets "Id"="1","Arn"="$LAMBDA_ARN" 2>/dev/null || echo "Target exists"

# Add permission for EventBridge to invoke Lambda
echo "Adding EventBridge permission to Lambda..."
aws lambda add-permission \
    --function-name $FUNCTION_NAME \
    --statement-id allow-eventbridge \
    --action lambda:InvokeFunction \
    --principal events.amazonaws.com \
    --source-arn "arn:aws:events:$(aws configure get region):${ACCOUNT_ID}:rule/gdp-web-ami-creation-rule" 2>/dev/null || echo "Permission exists"

echo ""
echo "✅ Event-Driven Lambda Setup Complete!"
echo "Function: $FUNCTION_NAME"
echo "EventBridge Rule: gdp-web-ami-creation-rule"
echo ""
echo "Test manually with AMI ID:"
echo "aws lambda invoke --function-name $FUNCTION_NAME --payload '{\"detail\":{\"responseElements\":{\"imageId\":\"ami-035acc1319ac2b971\"}}}' result.json"

# Cleanup
rm -f function.zip