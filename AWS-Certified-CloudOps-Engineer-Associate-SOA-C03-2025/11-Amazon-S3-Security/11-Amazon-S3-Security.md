# 11. Amazon S3 Security

## Lab 1: S3 Bucket Policies and ACLs

### Block Public Access
```bash
# Block all public access
aws s3api put-public-access-block \
  --bucket cloudops-secure-bucket \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

# Get public access block configuration
aws s3api get-public-access-block \
  --bucket cloudops-secure-bucket
```

### Bucket Policy Examples
```bash
# Create secure bucket policy
cat > secure-bucket-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyInsecureConnections",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::cloudops-secure-bucket",
        "arn:aws:s3:::cloudops-secure-bucket/*"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    },
    {
      "Sid": "RestrictToVPCEndpoint",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::cloudops-secure-bucket",
        "arn:aws:s3:::cloudops-secure-bucket/*"
      ],
      "Condition": {
        "StringNotEquals": {
          "aws:sourceVpce": "vpce-xxxxxxxxx"
        }
      }
    },
    {
      "Sid": "AllowSpecificIAMRole",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789012:role/CloudOpsRole"
      },
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::cloudops-secure-bucket/*"
    }
  ]
}
EOF

# Apply bucket policy
aws s3api put-bucket-policy \
  --bucket cloudops-secure-bucket \
  --policy file://secure-bucket-policy.json
```

### Object ACLs
```bash
# Set object ACL
aws s3api put-object-acl \
  --bucket cloudops-secure-bucket \
  --key sensitive-file.txt \
  --acl private

# Grant specific permissions
aws s3api put-object-acl \
  --bucket cloudops-secure-bucket \
  --key shared-file.txt \
  --grant-read emailaddress=user@example.com \
  --grant-full-control id=canonical-user-id
```

## Terraform S3 Security Configuration

```hcl
# s3-security.tf
resource "aws_s3_bucket" "secure_bucket" {
  bucket = "cloudops-secure-${random_string.suffix.result}"
}

resource "aws_s3_bucket_public_access_block" "secure_pab" {
  bucket = aws_s3_bucket.secure_bucket.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "secure_policy" {
  bucket = aws_s3_bucket.secure_bucket.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureConnections"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.secure_bucket.arn,
          "${aws_s3_bucket.secure_bucket.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
      {
        Sid       = "AllowCloudOpsRole"
        Effect    = "Allow"
        Principal = {
          AWS = aws_iam_role.cloudops_role.arn
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.secure_bucket.arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket_notification" "security_notifications" {
  bucket = aws_s3_bucket.secure_bucket.id
  
  topic {
    topic_arn = aws_sns_topic.security_alerts.arn
    events    = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
  }
}
```

## Lab 2: S3 Encryption

### Server-Side Encryption
```bash
# Enable default encryption with S3-managed keys
aws s3api put-bucket-encryption \
  --bucket cloudops-secure-bucket \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      },
      "BucketKeyEnabled": true
    }]
  }'

# Enable encryption with KMS
aws s3api put-bucket-encryption \
  --bucket cloudops-secure-bucket \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "aws:kms",
        "KMSMasterKeyID": "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
      },
      "BucketKeyEnabled": true
    }]
  }'

# Upload encrypted object
aws s3 cp file.txt s3://cloudops-secure-bucket/ \
  --sse AES256

# Upload with KMS encryption
aws s3 cp file.txt s3://cloudops-secure-bucket/ \
  --sse aws:kms \
  --sse-kms-key-id arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012
```

### Client-Side Encryption
```python
# client-side-encryption.py
import boto3
from botocore.client import Config

# Create KMS client
kms = boto3.client('kms')

# Create data key
response = kms.generate_data_key(
    KeyId='arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012',
    KeySpec='AES_256'
)

plaintext_key = response['Plaintext']
encrypted_key = response['CiphertextBlob']

# Encrypt data client-side before upload
from cryptography.fernet import Fernet
import base64

# Use the plaintext key for encryption
key = base64.urlsafe_b64encode(plaintext_key[:32])
cipher = Fernet(key)

# Encrypt file content
with open('sensitive-file.txt', 'rb') as f:
    plaintext = f.read()

encrypted_data = cipher.encrypt(plaintext)

# Upload encrypted data
s3 = boto3.client('s3')
s3.put_object(
    Bucket='cloudops-secure-bucket',
    Key='encrypted-file.txt',
    Body=encrypted_data,
    Metadata={
        'encrypted-key': base64.b64encode(encrypted_key).decode('utf-8')
    }
)
```

### Terraform Encryption Configuration
```hcl
# encryption.tf
resource "aws_kms_key" "s3_key" {
  description = "KMS key for S3 encryption"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow S3 Service"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_kms_alias" "s3_key_alias" {
  name          = "alias/s3-encryption-key"
  target_key_id = aws_kms_key.s3_key.key_id
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.secure_bucket.id
  
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_key.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}
```

## Lab 3: Access Logging and Monitoring

### Enable Access Logging
```bash
# Create logging bucket
aws s3 mb s3://cloudops-access-logs-bucket

# Enable access logging
aws s3api put-bucket-logging \
  --bucket cloudops-secure-bucket \
  --bucket-logging-status '{
    "LoggingEnabled": {
      "TargetBucket": "cloudops-access-logs-bucket",
      "TargetPrefix": "access-logs/"
    }
  }'

# Enable CloudTrail for S3 API calls
aws s3api put-bucket-notification-configuration \
  --bucket cloudops-secure-bucket \
  --notification-configuration '{
    "CloudWatchConfigurations": [{
      "Id": "S3AccessNotification",
      "CloudWatchConfiguration": {
        "LogGroupName": "/aws/s3/access-logs"
      },
      "Events": ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
    }]
  }'
```

### CloudWatch Metrics and Alarms
```bash
# Create alarm for unusual access patterns
aws cloudwatch put-metric-alarm \
  --alarm-name "S3-Unusual-Access" \
  --alarm-description "Unusual S3 access pattern detected" \
  --metric-name NumberOfObjects \
  --namespace AWS/S3 \
  --statistic Sum \
  --period 300 \
  --threshold 100 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=BucketName,Value=cloudops-secure-bucket Name=StorageType,Value=AllStorageTypes \
  --evaluation-periods 2

# Create alarm for failed requests
aws cloudwatch put-metric-alarm \
  --alarm-name "S3-High-4xx-Errors" \
  --alarm-description "High number of 4xx errors" \
  --metric-name 4xxErrors \
  --namespace AWS/S3 \
  --statistic Sum \
  --period 300 \
  --threshold 10 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=BucketName,Value=cloudops-secure-bucket \
  --evaluation-periods 2
```

### Terraform Logging Configuration
```hcl
# logging.tf
resource "aws_s3_bucket" "access_logs" {
  bucket = "cloudops-access-logs-${random_string.suffix.result}"
}

resource "aws_s3_bucket_logging" "access_logging" {
  bucket = aws_s3_bucket.secure_bucket.id
  
  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "access-logs/"
}

resource "aws_cloudwatch_log_group" "s3_access_logs" {
  name              = "/aws/s3/access-logs"
  retention_in_days = 30
}

resource "aws_cloudwatch_metric_alarm" "unusual_access" {
  alarm_name          = "S3-Unusual-Access"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "NumberOfObjects"
  namespace           = "AWS/S3"
  period              = "300"
  statistic           = "Sum"
  threshold           = "100"
  alarm_description   = "Unusual S3 access pattern detected"
  
  dimensions = {
    BucketName  = aws_s3_bucket.secure_bucket.id
    StorageType = "AllStorageTypes"
  }
  
  alarm_actions = [aws_sns_topic.security_alerts.arn]
}
```

## Lab 4: S3 Object Lock and Legal Hold

### Configure Object Lock
```bash
# Create bucket with Object Lock
aws s3api create-bucket \
  --bucket cloudops-compliance-bucket \
  --object-lock-enabled-for-bucket

# Set default retention
aws s3api put-object-lock-configuration \
  --bucket cloudops-compliance-bucket \
  --object-lock-configuration '{
    "ObjectLockEnabled": "Enabled",
    "Rule": {
      "DefaultRetention": {
        "Mode": "COMPLIANCE",
        "Years": 7
      }
    }
  }'

# Upload object with retention
aws s3api put-object \
  --bucket cloudops-compliance-bucket \
  --key compliance-document.pdf \
  --body compliance-document.pdf \
  --object-lock-mode COMPLIANCE \
  --object-lock-retain-until-date 2031-01-01T00:00:00Z

# Apply legal hold
aws s3api put-object-legal-hold \
  --bucket cloudops-compliance-bucket \
  --key compliance-document.pdf \
  --legal-hold Status=ON
```

### Terraform Object Lock Configuration
```hcl
# object-lock.tf
resource "aws_s3_bucket" "compliance_bucket" {
  bucket              = "cloudops-compliance-${random_string.suffix.result}"
  object_lock_enabled = true
}

resource "aws_s3_bucket_object_lock_configuration" "compliance_lock" {
  bucket = aws_s3_bucket.compliance_bucket.id
  
  rule {
    default_retention {
      mode = "COMPLIANCE"
      years = 7
    }
  }
}

resource "aws_s3_object" "compliance_document" {
  bucket = aws_s3_bucket.compliance_bucket.id
  key    = "compliance-document.pdf"
  source = "compliance-document.pdf"
  
  object_lock_mode                = "COMPLIANCE"
  object_lock_retain_until_date   = "2031-01-01T00:00:00Z"
  object_lock_legal_hold_status   = "ON"
}
```

## Lab 5: S3 Access Points

### Create Access Points
```bash
# Create access point
aws s3control create-access-point \
  --account-id 123456789012 \
  --name finance-access-point \
  --bucket cloudops-secure-bucket \
  --vpc-configuration VpcId=vpc-xxxxxxxxx \
  --policy '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789012:role/FinanceRole"
      },
      "Action": ["s3:GetObject", "s3:PutObject"],
      "Resource": "arn:aws:s3:us-east-1:123456789012:accesspoint/finance-access-point/object/finance/*"
    }]
  }'

# Use access point
aws s3 cp file.txt s3://arn:aws:s3:us-east-1:123456789012:accesspoint/finance-access-point/finance/file.txt
```

### Terraform Access Points
```hcl
# access-points.tf
resource "aws_s3_access_point" "finance_ap" {
  bucket = aws_s3_bucket.secure_bucket.id
  name   = "finance-access-point"
  
  vpc_configuration {
    vpc_id = var.vpc_id
  }
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.finance_role.arn
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "arn:aws:s3:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:accesspoint/finance-access-point/object/finance/*"
      }
    ]
  })
}

resource "aws_s3_access_point" "hr_ap" {
  bucket = aws_s3_bucket.secure_bucket.id
  name   = "hr-access-point"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.hr_role.arn
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "arn:aws:s3:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:accesspoint/hr-access-point/object/hr/*"
      }
    ]
  })
}
```

## Lab 6: S3 Security Monitoring

### Security Monitoring Script
```python
# s3-security-monitor.py
import boto3
import json
from datetime import datetime, timedelta

def check_bucket_security(bucket_name):
    s3 = boto3.client('s3')
    findings = []
    
    try:
        # Check public access block
        pab = s3.get_public_access_block(Bucket=bucket_name)
        config = pab['PublicAccessBlockConfiguration']
        
        if not all([
            config.get('BlockPublicAcls', False),
            config.get('IgnorePublicAcls', False),
            config.get('BlockPublicPolicy', False),
            config.get('RestrictPublicBuckets', False)
        ]):
            findings.append("Public access not fully blocked")
    
    except s3.exceptions.NoSuchPublicAccessBlockConfiguration:
        findings.append("No public access block configuration")
    
    # Check encryption
    try:
        encryption = s3.get_bucket_encryption(Bucket=bucket_name)
        if not encryption.get('ServerSideEncryptionConfiguration'):
            findings.append("No default encryption configured")
    except s3.exceptions.ClientError:
        findings.append("No encryption configuration")
    
    # Check logging
    try:
        logging = s3.get_bucket_logging(Bucket=bucket_name)
        if not logging.get('LoggingEnabled'):
            findings.append("Access logging not enabled")
    except s3.exceptions.ClientError:
        findings.append("No logging configuration")
    
    return findings

def lambda_handler(event, context):
    s3 = boto3.client('s3')
    sns = boto3.client('sns')
    
    # Get all buckets
    buckets = s3.list_buckets()['Buckets']
    
    security_issues = {}
    for bucket in buckets:
        bucket_name = bucket['Name']
        findings = check_bucket_security(bucket_name)
        
        if findings:
            security_issues[bucket_name] = findings
    
    # Send alert if issues found
    if security_issues:
        message = "S3 Security Issues Found:\n\n"
        for bucket, issues in security_issues.items():
            message += f"Bucket: {bucket}\n"
            for issue in issues:
                message += f"  - {issue}\n"
            message += "\n"
        
        sns.publish(
            TopicArn='arn:aws:sns:us-east-1:123456789012:s3-security-alerts',
            Message=message,
            Subject='S3 Security Alert'
        )
    
    return {
        'statusCode': 200,
        'body': json.dumps(f'Checked {len(buckets)} buckets, found issues in {len(security_issues)}')
    }
```

### Terraform Security Monitoring
```hcl
# security-monitoring.tf
resource "aws_lambda_function" "s3_security_monitor" {
  filename         = "s3-security-monitor.zip"
  function_name    = "s3-security-monitor"
  role            = aws_iam_role.lambda_role.arn
  handler         = "lambda_function.lambda_handler"
  runtime         = "python3.9"
  timeout         = 300
  
  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.security_alerts.arn
    }
  }
}

resource "aws_cloudwatch_event_rule" "daily_security_check" {
  name                = "daily-s3-security-check"
  description         = "Daily S3 security check"
  schedule_expression = "cron(0 9 * * ? *)"
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.daily_security_check.name
  target_id = "TriggerLambda"
  arn       = aws_lambda_function.s3_security_monitor.arn
}

resource "aws_sns_topic" "security_alerts" {
  name = "s3-security-alerts"
}
```

## Best Practices

1. **Block public access** by default
2. **Enable encryption** for all buckets
3. **Use least privilege** access policies
4. **Enable access logging** and monitoring
5. **Implement MFA delete** for critical buckets
6. **Use VPC endpoints** for private access
7. **Regular security audits** and compliance checks

## Security Compliance

```bash
# Check compliance status
aws s3api get-bucket-policy-status \
  --bucket cloudops-secure-bucket

# Verify encryption status
aws s3api get-bucket-encryption \
  --bucket cloudops-secure-bucket

# Check object lock status
aws s3api get-object-lock-configuration \
  --bucket cloudops-compliance-bucket
```

## Cleanup

```bash
# Remove bucket policy
aws s3api delete-bucket-policy \
  --bucket cloudops-secure-bucket

# Disable encryption
aws s3api delete-bucket-encryption \
  --bucket cloudops-secure-bucket

# Delete access points
aws s3control delete-access-point \
  --account-id 123456789012 \
  --name finance-access-point
```