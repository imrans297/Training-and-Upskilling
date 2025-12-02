# 10. Advanced Amazon S3 & Athena

## Lab 1: S3 Analytics and Intelligence

### Enable S3 Analytics
```bash
# Configure S3 analytics
aws s3api put-bucket-analytics-configuration \
  --bucket cloudops-bucket \
  --id analytics-config \
  --analytics-configuration '{
    "Id": "analytics-config",
    "StorageClassAnalysis": {
      "DataExport": {
        "OutputSchemaVersion": "V_1",
        "Destination": {
          "S3BucketDestination": {
            "Format": "CSV",
            "Bucket": "arn:aws:s3:::analytics-results-bucket",
            "Prefix": "analytics/"
          }
        }
      }
    }
  }'

# Enable S3 Inventory
aws s3api put-bucket-inventory-configuration \
  --bucket cloudops-bucket \
  --id inventory-config \
  --inventory-configuration '{
    "Id": "inventory-config",
    "IsEnabled": true,
    "Destination": {
      "S3BucketDestination": {
        "Bucket": "arn:aws:s3:::inventory-results-bucket",
        "Format": "CSV",
        "Prefix": "inventory/"
      }
    },
    "Schedule": {
      "Frequency": "Daily"
    },
    "IncludedObjectVersions": "Current"
  }'
```

### S3 Intelligent Tiering
```bash
# Configure Intelligent Tiering
aws s3api put-bucket-intelligent-tiering-configuration \
  --bucket cloudops-bucket \
  --id intelligent-tiering-config \
  --intelligent-tiering-configuration '{
    "Id": "intelligent-tiering-config",
    "Status": "Enabled",
    "Filter": {
      "Prefix": "data/"
    },
    "Tierings": [
      {
        "Days": 90,
        "AccessTier": "ARCHIVE_ACCESS"
      },
      {
        "Days": 180,
        "AccessTier": "DEEP_ARCHIVE_ACCESS"
      }
    ]
  }'
```

## Terraform S3 Advanced Configuration

```hcl
# s3-advanced.tf
resource "aws_s3_bucket" "analytics_bucket" {
  bucket = "cloudops-analytics-${random_string.suffix.result}"
}

resource "aws_s3_bucket_analytics_configuration" "analytics" {
  bucket = aws_s3_bucket.main.id
  name   = "analytics-config"
  
  storage_class_analysis {
    data_export {
      output_schema_version = "V_1"
      
      destination {
        s3_bucket_destination {
          bucket_arn = aws_s3_bucket.analytics_bucket.arn
          format     = "CSV"
          prefix     = "analytics/"
        }
      }
    }
  }
}

resource "aws_s3_bucket_inventory" "inventory" {
  bucket = aws_s3_bucket.main.id
  name   = "inventory-config"
  
  included_object_versions = "Current"
  
  schedule {
    frequency = "Daily"
  }
  
  destination {
    bucket {
      format     = "CSV"
      bucket_arn = aws_s3_bucket.analytics_bucket.arn
      prefix     = "inventory/"
    }
  }
}

resource "aws_s3_bucket_intelligent_tiering_configuration" "intelligent_tiering" {
  bucket = aws_s3_bucket.main.id
  name   = "intelligent-tiering-config"
  
  filter {
    prefix = "data/"
  }
  
  tiering {
    access_tier = "ARCHIVE_ACCESS"
    days        = 90
  }
  
  tiering {
    access_tier = "DEEP_ARCHIVE_ACCESS"
    days        = 180
  }
}
```

## Lab 2: Amazon Athena Setup

### Create Athena Database and Tables
```bash
# Create Athena database
aws athena start-query-execution \
  --query-string "CREATE DATABASE cloudops_analytics" \
  --result-configuration OutputLocation=s3://athena-results-bucket/ \
  --work-group primary

# Create table for CloudTrail logs
aws athena start-query-execution \
  --query-string "
    CREATE EXTERNAL TABLE cloudtrail_logs (
      eventversion STRING,
      useridentity STRUCT<
        type: STRING,
        principalid: STRING,
        arn: STRING,
        accountid: STRING,
        invokedby: STRING,
        accesskeyid: STRING,
        userName: STRING,
        sessioncontext: STRUCT<
          attributes: STRUCT<
            mfaauthenticated: STRING,
            creationdate: STRING>,
          sessionissuer: STRUCT<
            type: STRING,
            principalId: STRING,
            arn: STRING,
            accountId: STRING,
            userName: STRING>>>,
      eventtime STRING,
      eventsource STRING,
      eventname STRING,
      awsregion STRING,
      sourceipaddress STRING,
      useragent STRING,
      errorcode STRING,
      errormessage STRING,
      requestparameters STRING,
      responseelements STRING,
      additionaleventdata STRING,
      requestid STRING,
      eventid STRING,
      resources ARRAY<STRUCT<
        ARN: STRING,
        accountId: STRING,
        type: STRING>>,
      eventtype STRING,
      apiversion STRING,
      readonly STRING,
      recipientaccountid STRING,
      serviceeventdetails STRING,
      sharedeventid STRING,
      vpcendpointid STRING
    )
    PARTITIONED BY (
      region STRING,
      year STRING,
      month STRING,
      day STRING
    )
    STORED AS INPUTFORMAT 'com.amazon.emr.cloudtrail.CloudTrailInputFormat'
    OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
    LOCATION 's3://cloudtrail-logs-bucket/AWSLogs/123456789012/CloudTrail/'
  " \
  --result-configuration OutputLocation=s3://athena-results-bucket/
```

### Query CloudTrail Data
```sql
-- Find failed login attempts
SELECT 
  eventtime,
  sourceipaddress,
  useridentity.userName,
  errorcode,
  errormessage
FROM cloudtrail_logs
WHERE eventname = 'ConsoleLogin'
  AND errorcode IS NOT NULL
  AND year = '2024'
  AND month = '01'
ORDER BY eventtime DESC
LIMIT 100;

-- Analyze EC2 instance launches
SELECT 
  DATE(eventtime) as date,
  COUNT(*) as instance_launches,
  useridentity.userName as user
FROM cloudtrail_logs
WHERE eventname = 'RunInstances'
  AND year = '2024'
  AND month = '01'
GROUP BY DATE(eventtime), useridentity.userName
ORDER BY date DESC;
```

## Terraform Athena Configuration

```hcl
# athena.tf
resource "aws_s3_bucket" "athena_results" {
  bucket = "cloudops-athena-results-${random_string.suffix.result}"
}

resource "aws_athena_database" "cloudops_analytics" {
  name   = "cloudops_analytics"
  bucket = aws_s3_bucket.athena_results.bucket
}

resource "aws_athena_workgroup" "cloudops_workgroup" {
  name = "cloudops-workgroup"
  
  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true
    
    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_results.bucket}/results/"
      
      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }
  
  tags = {
    Name = "CloudOps Workgroup"
  }
}

resource "aws_athena_named_query" "failed_logins" {
  name      = "failed_logins"
  database  = aws_athena_database.cloudops_analytics.name
  workgroup = aws_athena_workgroup.cloudops_workgroup.name
  
  query = <<EOF
SELECT 
  eventtime,
  sourceipaddress,
  useridentity.userName,
  errorcode,
  errormessage
FROM cloudtrail_logs
WHERE eventname = 'ConsoleLogin'
  AND errorcode IS NOT NULL
  AND year = '2024'
ORDER BY eventtime DESC
LIMIT 100;
EOF
}
```

## Lab 3: S3 Select and Glacier Select

### S3 Select Queries
```bash
# Query CSV data with S3 Select
aws s3api select-object-content \
  --bucket cloudops-bucket \
  --key data/sales.csv \
  --expression "SELECT * FROM S3Object[*] WHERE _2 > 1000" \
  --expression-type SQL \
  --input-serialization '{"CSV": {"FileHeaderInfo": "USE"}, "CompressionType": "NONE"}' \
  --output-serialization '{"CSV": {}}' \
  output.csv

# Query JSON data
aws s3api select-object-content \
  --bucket cloudops-bucket \
  --key logs/application.json \
  --expression "SELECT * FROM S3Object[*].Records[*] WHERE level = 'ERROR'" \
  --expression-type SQL \
  --input-serialization '{"JSON": {"Type": "LINES"}, "CompressionType": "NONE"}' \
  --output-serialization '{"JSON": {}}' \
  error-logs.json
```

### Glacier Select
```bash
# Restore and query Glacier object
aws s3api restore-object \
  --bucket cloudops-bucket \
  --key archived-data.csv \
  --restore-request '{
    "Days": 1,
    "GlacierJobParameters": {
      "Tier": "Standard"
    },
    "SelectParameters": {
      "InputSerialization": {
        "CSV": {"FileHeaderInfo": "USE"},
        "CompressionType": "NONE"
      },
      "ExpressionType": "SQL",
      "Expression": "SELECT * FROM S3Object WHERE _3 > 500",
      "OutputSerialization": {
        "CSV": {}
      }
    }
  }'
```

## Lab 4: S3 Batch Operations

### Create Batch Job
```bash
# Create batch job manifest
cat > batch-manifest.csv << EOF
cloudops-bucket,file1.txt,1.0
cloudops-bucket,file2.txt,1.0
cloudops-bucket,file3.txt,1.0
EOF

# Upload manifest
aws s3 cp batch-manifest.csv s3://cloudops-batch-bucket/manifests/

# Create batch job to change storage class
aws s3control create-job \
  --account-id 123456789012 \
  --confirmation-required \
  --operation '{
    "S3PutObjectCopy": {
      "TargetResource": "arn:aws:s3:::cloudops-bucket",
      "StorageClass": "STANDARD_IA",
      "MetadataDirective": "COPY"
    }
  }' \
  --manifest '{
    "Spec": {
      "Format": "S3BatchOperations_CSV_20180820",
      "Fields": ["Bucket", "Key"]
    },
    "Location": {
      "ObjectArn": "arn:aws:s3:::cloudops-batch-bucket/manifests/batch-manifest.csv",
      "ETag": "example-etag"
    }
  }' \
  --priority 10 \
  --role-arn arn:aws:iam::123456789012:role/batch-operations-role
```

### Terraform Batch Operations
```hcl
# batch-operations.tf
resource "aws_s3_bucket" "batch_bucket" {
  bucket = "cloudops-batch-${random_string.suffix.result}"
}

resource "aws_iam_role" "batch_operations_role" {
  name = "S3BatchOperationsRole"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "batchoperations.s3.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "batch_operations_policy" {
  name = "S3BatchOperationsPolicy"
  role = aws_iam_role.batch_operations_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:GetBucketLocation",
          "s3:ListBucket"
        ]
        Resource = [
          "${aws_s3_bucket.main.arn}",
          "${aws_s3_bucket.main.arn}/*"
        ]
      }
    ]
  })
}
```

## Lab 5: S3 Performance Optimization

### Multipart Upload Optimization
```python
# multipart-upload.py
import boto3
from boto3.s3.transfer import TransferConfig

def optimized_upload(file_path, bucket, key):
    s3 = boto3.client('s3')
    
    # Configure multipart upload
    config = TransferConfig(
        multipart_threshold=1024 * 25,  # 25MB
        max_concurrency=10,
        multipart_chunksize=1024 * 25,
        use_threads=True
    )
    
    # Upload with optimized settings
    s3.upload_file(
        file_path, bucket, key,
        Config=config,
        ExtraArgs={
            'StorageClass': 'STANDARD_IA',
            'ServerSideEncryption': 'AES256'
        }
    )
    
    print(f"Uploaded {file_path} to s3://{bucket}/{key}")

# Usage
optimized_upload('large-file.zip', 'cloudops-bucket', 'uploads/large-file.zip')
```

### Request Rate Optimization
```bash
# Use request rate optimization prefixes
aws s3 cp file1.txt s3://cloudops-bucket/2024/01/15/12/file1.txt
aws s3 cp file2.txt s3://cloudops-bucket/2024/01/15/13/file2.txt

# Use random prefixes for high request rates
aws s3 cp file3.txt s3://cloudops-bucket/a1b2c3/data/file3.txt
aws s3 cp file4.txt s3://cloudops-bucket/d4e5f6/data/file4.txt
```

## Lab 6: Data Lake Architecture

### Create Data Lake Structure
```bash
# Create data lake bucket structure
aws s3api put-object --bucket cloudops-datalake --key raw-data/
aws s3api put-object --bucket cloudops-datalake --key processed-data/
aws s3api put-object --bucket cloudops-datalake --key curated-data/
aws s3api put-object --bucket cloudops-datalake --key analytics-results/

# Set up partitioned structure
aws s3api put-object --bucket cloudops-datalake --key raw-data/year=2024/month=01/day=15/
aws s3api put-object --bucket cloudops-datalake --key processed-data/year=2024/month=01/day=15/
```

### Athena Data Lake Queries
```sql
-- Create external table for partitioned data
CREATE EXTERNAL TABLE web_logs (
  timestamp STRING,
  ip_address STRING,
  user_agent STRING,
  request_uri STRING,
  status_code INT,
  response_size BIGINT
)
PARTITIONED BY (
  year STRING,
  month STRING,
  day STRING
)
STORED AS PARQUET
LOCATION 's3://cloudops-datalake/processed-data/';

-- Add partitions
ALTER TABLE web_logs ADD PARTITION (year='2024', month='01', day='15')
LOCATION 's3://cloudops-datalake/processed-data/year=2024/month=01/day=15/';

-- Query partitioned data
SELECT 
  status_code,
  COUNT(*) as request_count
FROM web_logs
WHERE year = '2024' AND month = '01' AND day = '15'
GROUP BY status_code
ORDER BY request_count DESC;
```

## Best Practices

1. **Use appropriate storage classes** for cost optimization
2. **Implement partitioning** for better query performance
3. **Use columnar formats** (Parquet, ORC) for analytics
4. **Optimize request patterns** with proper prefixes
5. **Enable compression** to reduce storage costs
6. **Use S3 Select** for simple filtering operations
7. **Monitor performance** with CloudWatch metrics

## Monitoring and Optimization

```bash
# Monitor S3 request metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/S3 \
  --metric-name AllRequests \
  --dimensions Name=BucketName,Value=cloudops-bucket Name=FilterId,Value=EntireBucket \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-01T23:59:59Z \
  --period 3600 \
  --statistics Sum

# Monitor Athena query performance
aws athena get-query-execution \
  --query-execution-id query-execution-id
```

## Cleanup

```bash
# Cancel running Athena queries
aws athena stop-query-execution --query-execution-id query-execution-id

# Delete Athena database
aws athena start-query-execution \
  --query-string "DROP DATABASE cloudops_analytics CASCADE" \
  --result-configuration OutputLocation=s3://athena-results-bucket/

# Delete S3 objects and buckets
aws s3 rm s3://cloudops-datalake --recursive
aws s3 rb s3://cloudops-datalake
```