#!/bin/bash

# Deploy AMI Update Lambda Function

FUNCTION_NAME="gdp-web-ami-update"
ROLE_NAME="gdp-web-ami-update-role"

echo "=== Creating IAM Role for Lambda ==="
cat > trust-policy.json << 'EOF'
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
    --role-name $ROLE_NAME \
    --assume-role-policy-document file://trust-policy.json

echo "=== Creating IAM Policy ==="
cat > lambda-policy.json << 'EOF'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:*:*:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeImages",
                "ec2:DescribeLaunchTemplateVersions",
                "ec2:CreateLaunchTemplateVersion",
                "ec2:ModifyLaunchTemplate"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "autoscaling:UpdateAutoScalingGroup",
                "autoscaling:StartInstanceRefresh",
                "autoscaling:DescribeAutoScalingGroups"
            ],
            "Resource": "*"
        }
    ]
}
EOF

aws iam put-role-policy \
    --role-name $ROLE_NAME \
    --policy-name "AMIUpdatePolicy" \
    --policy-document file://lambda-policy.json

echo "=== Waiting for role propagation ==="
sleep 10

echo "=== Creating Lambda deployment package ==="
zip lambda-function.zip task2-ami-update-lambda.py

echo "=== Creating Lambda function ==="
ROLE_ARN=$(aws iam get-role --role-name $ROLE_NAME --query 'Role.Arn' --output text)

aws lambda create-function \
    --function-name $FUNCTION_NAME \
    --runtime python3.9 \
    --role $ROLE_ARN \
    --handler task2-ami-update-lambda.lambda_handler \
    --zip-file fileb://lambda-function.zip \
    --timeout 300 \
    --description "Updates ASG Launch Template with latest GDP-Web AMI"

echo "=== Creating EventBridge Rule ==="
aws events put-rule \
    --name "gdp-web-ami-created" \
    --event-pattern '{
        "source": ["aws.ec2"],
        "detail-type": ["AWS API Call via CloudTrail"],
        "detail": {
            "eventSource": ["ec2.amazonaws.com"],
            "eventName": ["CreateImage"],
            "requestParameters": {
                "name": [{"prefix": "gdp-web-"}]
            }
        }
    }' \
    --description "Trigger when GDP-Web AMI is created"

echo "=== Adding Lambda permission for EventBridge ==="
aws lambda add-permission \
    --function-name $FUNCTION_NAME \
    --statement-id "allow-eventbridge" \
    --action "lambda:InvokeFunction" \
    --principal events.amazonaws.com \
    --source-arn "arn:aws:events:$(aws configure get region):$(aws sts get-caller-identity --query Account --output text):rule/gdp-web-ami-created"

echo "=== Adding EventBridge target ==="
LAMBDA_ARN=$(aws lambda get-function --function-name $FUNCTION_NAME --query 'Configuration.FunctionArn' --output text)

aws events put-targets \
    --rule "gdp-web-ami-created" \
    --targets "Id"="1","Arn"="$LAMBDA_ARN"

echo "=== Cleanup temporary files ==="
rm -f trust-policy.json lambda-policy.json lambda-function.zip

echo "=== Setup Complete ==="
echo "Lambda Function: $FUNCTION_NAME"
echo "EventBridge Rule: gdp-web-ami-created"
echo "The Lambda will automatically update ASG launch template when new GDP-Web AMIs are created"