# 09. Amazon S3 Introduction

## Lab 1: Basic S3 Operations

### Create and Manage Buckets
```bash
# Create S3 bucket
aws s3 mb s3://cloudops-bucket-$(date +%s)

# List buckets
aws s3 ls

# Upload file
aws s3 cp file.txt s3://cloudops-bucket-123456789/

# Download file
aws s3 cp s3://cloudops-bucket-123456789/file.txt ./downloaded-file.txt

# Sync directory
aws s3 sync ./local-folder s3://cloudops-bucket-123456789/folder/

# Delete object
aws s3 rm s3://cloudops-bucket-123456789/file.txt

# Delete bucket
aws s3 rb s3://cloudops-bucket-123456789 --force
```

### S3 API Operations
```bash
# Create bucket with specific region
aws s3api create-bucket \
  --bucket cloudops-api-bucket-$(date +%s) \
  --region us-west-2 \
  --create-bucket-configuration LocationConstraint=us-west-2

# Put object with metadata
aws s3api put-object \
  --bucket cloudops-api-bucket-123456789 \
  --key documents/report.pdf \
  --body report.pdf \
  --metadata author=cloudops,department=engineering

# Get object metadata
aws s3api head-object \
  --bucket cloudops-api-bucket-123456789 \
  --key documents/report.pdf

# List objects with details
aws s3api list-objects-v2 \
  --bucket cloudops-api-bucket-123456789 \
  --prefix documents/
```

## Terraform S3 Configuration

```hcl
# s3.tf
resource "aws_s3_bucket" "cloudops_bucket" {
  bucket = "cloudops-bucket-${random_string.bucket_suffix.result}"
  
  tags = {
    Name        = "CloudOps Bucket"
    Environment = "Lab"
  }
}

resource "aws_s3_bucket_versioning" "cloudops_versioning" {
  bucket = aws_s3_bucket.cloudops_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudops_encryption" {
  bucket = aws_s3_bucket.cloudops_bucket.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cloudops_pab" {
  bucket = aws_s3_bucket.cloudops_bucket.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}
```

## Lab 2: S3 Storage Classes

### Configure Storage Classes
```bash
# Upload with specific storage class
aws s3 cp file.txt s3://cloudops-bucket-123456789/ \
  --storage-class STANDARD_IA

# Copy object to different storage class
aws s3 cp s3://cloudops-bucket-123456789/file.txt s3://cloudops-bucket-123456789/file-glacier.txt \
  --storage-class GLACIER

# Restore Glacier object
aws s3api restore-object \
  --bucket cloudops-bucket-123456789 \
  --key file-glacier.txt \
  --restore-request Days=7,GlacierJobParameters='{Tier=Standard}'
```

### Terraform Storage Classes
```hcl
# storage-classes.tf
resource "aws_s3_object" "standard_object" {
  bucket       = aws_s3_bucket.cloudops_bucket.id
  key          = "documents/standard-file.txt"
  source       = "local-file.txt"
  storage_class = "STANDARD"
  
  tags = {
    StorageClass = "Standard"
  }
}

resource "aws_s3_object" "ia_object" {
  bucket       = aws_s3_bucket.cloudops_bucket.id
  key          = "documents/ia-file.txt"
  source       = "local-file.txt"
  storage_class = "STANDARD_IA"
  
  tags = {
    StorageClass = "Standard-IA"
  }
}
```

## Lab 3: S3 Lifecycle Management

### Create Lifecycle Policy
```bash
# Create lifecycle configuration
cat > lifecycle.json << EOF
{
  "Rules": [
    {
      "ID": "TransitionRule",
      "Status": "Enabled",
      "Filter": {
        "Prefix": "documents/"
      },
      "Transitions": [
        {
          "Days": 30,
          "StorageClass": "STANDARD_IA"
        },
        {
          "Days": 90,
          "StorageClass": "GLACIER"
        },
        {
          "Days": 365,
          "StorageClass": "DEEP_ARCHIVE"
        }
      ],
      "Expiration": {
        "Days": 2555
      }
    },
    {
      "ID": "DeleteIncompleteMultipartUploads",
      "Status": "Enabled",
      "Filter": {},
      "AbortIncompleteMultipartUpload": {
        "DaysAfterInitiation": 7
      }
    }
  ]
}
EOF

# Apply lifecycle configuration
aws s3api put-bucket-lifecycle-configuration \
  --bucket cloudops-bucket-123456789 \
  --lifecycle-configuration file://lifecycle.json

# Get lifecycle configuration
aws s3api get-bucket-lifecycle-configuration \
  --bucket cloudops-bucket-123456789
```

### Terraform Lifecycle Configuration
```hcl
# lifecycle.tf
resource "aws_s3_bucket_lifecycle_configuration" "cloudops_lifecycle" {
  bucket = aws_s3_bucket.cloudops_bucket.id
  
  rule {
    id     = "transition_rule"
    status = "Enabled"
    
    filter {
      prefix = "documents/"
    }
    
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    
    transition {
      days          = 90
      storage_class = "GLACIER"
    }
    
    transition {
      days          = 365
      storage_class = "DEEP_ARCHIVE"
    }
    
    expiration {
      days = 2555
    }
  }
  
  rule {
    id     = "delete_incomplete_multipart"
    status = "Enabled"
    
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}
```

## Lab 4: S3 Versioning

### Enable and Manage Versioning
```bash
# Enable versioning
aws s3api put-bucket-versioning \
  --bucket cloudops-bucket-123456789 \
  --versioning-configuration Status=Enabled

# Upload multiple versions
echo "Version 1" > test-file.txt
aws s3 cp test-file.txt s3://cloudops-bucket-123456789/

echo "Version 2" > test-file.txt
aws s3 cp test-file.txt s3://cloudops-bucket-123456789/

# List object versions
aws s3api list-object-versions \
  --bucket cloudops-bucket-123456789 \
  --prefix test-file.txt

# Get specific version
aws s3api get-object \
  --bucket cloudops-bucket-123456789 \
  --key test-file.txt \
  --version-id version-id-here \
  downloaded-version.txt

# Delete specific version
aws s3api delete-object \
  --bucket cloudops-bucket-123456789 \
  --key test-file.txt \
  --version-id version-id-here
```

### Terraform Versioning with MFA Delete
```hcl
# versioning.tf
resource "aws_s3_bucket_versioning" "cloudops_versioning" {
  bucket = aws_s3_bucket.cloudops_bucket.id
  
  versioning_configuration {
    status     = "Enabled"
    mfa_delete = "Disabled"  # Requires root user to enable
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "version_cleanup" {
  bucket = aws_s3_bucket.cloudops_bucket.id
  
  rule {
    id     = "cleanup_old_versions"
    status = "Enabled"
    
    noncurrent_version_expiration {
      noncurrent_days = 90
    }
    
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }
  }
}
```

## Lab 5: S3 Event Notifications

### Configure Event Notifications
```bash
# Create SNS topic
aws sns create-topic --name s3-notifications

# Create notification configuration
cat > notification.json << EOF
{
  "TopicConfigurations": [
    {
      "Id": "ObjectCreatedEvents",
      "TopicArn": "arn:aws:sns:us-east-1:123456789012:s3-notifications",
      "Events": ["s3:ObjectCreated:*"],
      "Filter": {
        "Key": {
          "FilterRules": [
            {
              "Name": "prefix",
              "Value": "uploads/"
            },
            {
              "Name": "suffix",
              "Value": ".jpg"
            }
          ]
        }
      }
    }
  ]
}
EOF

# Apply notification configuration
aws s3api put-bucket-notification-configuration \
  --bucket cloudops-bucket-123456789 \
  --notification-configuration file://notification.json
```

### Terraform Event Notifications
```hcl
# s3-events.tf
resource "aws_sns_topic" "s3_notifications" {
  name = "s3-notifications"
}

resource "aws_sns_topic_policy" "s3_notifications_policy" {
  arn = aws_sns_topic.s3_notifications.arn
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.s3_notifications.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_notification" "cloudops_notification" {
  bucket = aws_s3_bucket.cloudops_bucket.id
  
  topic {
    topic_arn = aws_sns_topic.s3_notifications.arn
    events    = ["s3:ObjectCreated:*"]
    
    filter_prefix = "uploads/"
    filter_suffix = ".jpg"
  }
  
  depends_on = [aws_sns_topic_policy.s3_notifications_policy]
}

data "aws_caller_identity" "current" {}
```

## Lab 6: S3 Transfer Acceleration

### Enable Transfer Acceleration
```bash
# Enable transfer acceleration
aws s3api put-bucket-accelerate-configuration \
  --bucket cloudops-bucket-123456789 \
  --accelerate-configuration Status=Enabled

# Get acceleration status
aws s3api get-bucket-accelerate-configuration \
  --bucket cloudops-bucket-123456789

# Upload using acceleration endpoint
aws s3 cp large-file.zip s3://cloudops-bucket-123456789/ \
  --endpoint-url https://s3-accelerate.amazonaws.com
```

### Terraform Transfer Acceleration
```hcl
# transfer-acceleration.tf
resource "aws_s3_bucket_accelerate_configuration" "cloudops_acceleration" {
  bucket = aws_s3_bucket.cloudops_bucket.id
  status = "Enabled"
}

resource "aws_s3_bucket_request_payment_configuration" "cloudops_requester_pays" {
  bucket = aws_s3_bucket.cloudops_bucket.id
  payer  = "Requester"
}
```

## Lab 7: S3 Multipart Upload

### Multipart Upload Script
```bash
#!/bin/bash
# multipart-upload.sh

BUCKET="cloudops-bucket-123456789"
KEY="large-files/big-file.zip"
FILE="big-file.zip"

# Initiate multipart upload
UPLOAD_ID=$(aws s3api create-multipart-upload \
  --bucket $BUCKET \
  --key $KEY \
  --query 'UploadId' \
  --output text)

echo "Upload ID: $UPLOAD_ID"

# Split file into parts (100MB each)
split -b 100M $FILE part_

# Upload parts
PARTS=""
PART_NUM=1

for part in part_*; do
  echo "Uploading part $PART_NUM..."
  
  ETAG=$(aws s3api upload-part \
    --bucket $BUCKET \
    --key $KEY \
    --part-number $PART_NUM \
    --upload-id $UPLOAD_ID \
    --body $part \
    --query 'ETag' \
    --output text)
  
  PARTS="$PARTS{\"ETag\":$ETAG,\"PartNumber\":$PART_NUM},"
  PART_NUM=$((PART_NUM + 1))
done

# Remove trailing comma
PARTS=${PARTS%,}

# Complete multipart upload
cat > parts.json << EOF
{
  "Parts": [$PARTS]
}
EOF

aws s3api complete-multipart-upload \
  --bucket $BUCKET \
  --key $KEY \
  --upload-id $UPLOAD_ID \
  --multipart-upload file://parts.json

echo "Multipart upload completed"
```

## Best Practices

1. **Use appropriate storage classes** for cost optimization
2. **Enable versioning** for important data
3. **Implement lifecycle policies** for automated management
4. **Use multipart upload** for large files
5. **Enable transfer acceleration** for global uploads
6. **Set up proper monitoring** and notifications
7. **Implement security best practices**

## Monitoring S3

```bash
# Get bucket size
aws cloudwatch get-metric-statistics \
  --namespace AWS/S3 \
  --metric-name BucketSizeBytes \
  --dimensions Name=BucketName,Value=cloudops-bucket-123456789 Name=StorageType,Value=StandardStorage \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z \
  --period 86400 \
  --statistics Average

# Get number of objects
aws cloudwatch get-metric-statistics \
  --namespace AWS/S3 \
  --metric-name NumberOfObjects \
  --dimensions Name=BucketName,Value=cloudops-bucket-123456789 Name=StorageType,Value=AllStorageTypes \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z \
  --period 86400 \
  --statistics Average
```

## Cleanup

```bash
# Delete all objects and versions
aws s3api delete-objects \
  --bucket cloudops-bucket-123456789 \
  --delete "$(aws s3api list-object-versions \
    --bucket cloudops-bucket-123456789 \
    --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}')"

# Delete bucket
aws s3api delete-bucket \
  --bucket cloudops-bucket-123456789
```