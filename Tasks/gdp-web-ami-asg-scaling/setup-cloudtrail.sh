#!/bin/bash

# Setup CloudTrail for EventBridge Auto-Triggering

echo "=== Setting up CloudTrail for Auto-Triggering ==="

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=$(aws configure get region)
BUCKET_NAME="gdp-web-cloudtrail-${ACCOUNT_ID}-${REGION}"
TRAIL_NAME="gdp-web-trail"

echo "Account: $ACCOUNT_ID"
echo "Region: $REGION"
echo "Bucket: $BUCKET_NAME"

# Create S3 bucket for CloudTrail
echo "1. Creating S3 bucket for CloudTrail..."
aws s3 mb s3://$BUCKET_NAME 2>/dev/null || echo "Bucket already exists"

# Create bucket policy for CloudTrail
echo "2. Setting bucket policy..."
cat > bucket-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws:s3:::$BUCKET_NAME"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::$BUCKET_NAME/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        }
    ]
}
EOF

aws s3api put-bucket-policy --bucket $BUCKET_NAME --policy file://bucket-policy.json

# Create CloudTrail
echo "3. Creating CloudTrail..."
aws cloudtrail create-trail \
    --name $TRAIL_NAME \
    --s3-bucket-name $BUCKET_NAME \
    --include-global-service-events \
    --is-multi-region-trail 2>/dev/null || echo "Trail already exists"

# Start logging
echo "4. Starting CloudTrail logging..."
aws cloudtrail start-logging --name $TRAIL_NAME

# Verify trail status
echo "5. Verifying CloudTrail status..."
aws cloudtrail get-trail-status --name $TRAIL_NAME --query '[IsLogging,LatestDeliveryTime]' --output table

echo ""
echo "✅ CloudTrail Setup Complete!"
echo "Trail Name: $TRAIL_NAME"
echo "S3 Bucket: $BUCKET_NAME"
echo ""
echo "Now EventBridge will automatically trigger Lambda when you create AMI backups!"

# Cleanup
rm -f bucket-policy.json