# 18. Security and Compliance

## Lab 1: AWS CloudTrail

### Enable CloudTrail
```bash
# Create S3 bucket for CloudTrail logs
aws s3 mb s3://cloudops-cloudtrail-logs-$(date +%s)

# Create CloudTrail
aws cloudtrail create-trail \
  --name cloudops-trail \
  --s3-bucket-name cloudops-cloudtrail-logs-$(date +%s) \
  --include-global-service-events \
  --is-multi-region-trail \
  --enable-log-file-validation \
  --event-selectors '[
    {
      "ReadWriteType": "All",
      "IncludeManagementEvents": true,
      "DataResources": [
        {
          "Type": "AWS::S3::Object",
          "Values": ["arn:aws:s3:::cloudops-sensitive-bucket/*"]
        }
      ]
    }
  ]'

# Start logging
aws cloudtrail start-logging --name cloudops-trail

# Create event data store for advanced queries
aws cloudtrail create-event-data-store \
  --name cloudops-event-store \
  --multi-region-enabled \
  --organization-enabled \
  --advanced-event-selectors '[
    {
      "Name": "S3 Data Events",
      "FieldSelectors": [
        {
          "Field": "eventCategory",
          "Equals": ["Data"]
        },
        {
          "Field": "resources.type",
          "Equals": ["AWS::S3::Object"]
        }
      ]
    }
  ]'
```

### CloudTrail Log Analysis
```bash
# Query CloudTrail logs
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=RunInstances \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z

# Query event data store
aws cloudtrail start-query \
  --query-statement "
    SELECT eventTime, eventName, userIdentity.type, sourceIPAddress 
    FROM cloudops-event-store 
    WHERE eventTime > '2024-01-01 00:00:00' 
    AND eventName = 'RunInstances'
  "

# Get query results
aws cloudtrail get-query-results --query-id query-id-here
```

## Terraform CloudTrail Configuration

```hcl
# cloudtrail.tf
resource "aws_s3_bucket" "cloudtrail_bucket" {
  bucket        = "cloudops-cloudtrail-${random_string.suffix.result}"
  force_destroy = true
}

resource "aws_s3_bucket_policy" "cloudtrail_bucket_policy" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail_bucket.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

resource "aws_cloudtrail" "main" {
  name           = "cloudops-trail"
  s3_bucket_name = aws_s3_bucket.cloudtrail_bucket.bucket
  
  include_global_service_events = true
  is_multi_region_trail        = true
  enable_log_file_validation   = true
  
  event_selector {
    read_write_type                 = "All"
    include_management_events       = true
    
    data_resource {
      type   = "AWS::S3::Object"
      values = ["${aws_s3_bucket.sensitive_data.arn}/*"]
    }
    
    data_resource {
      type   = "AWS::Lambda::Function"
      values = ["arn:aws:lambda:*:*:function:*"]
    }
  }
  
  insight_selector {
    insight_type = "ApiCallRateInsight"
  }
  
  tags = {
    Name = "CloudOps Trail"
  }
}

resource "aws_cloudtrail_event_data_store" "main" {
  name                          = "cloudops-event-store"
  multi_region_enabled         = true
  organization_enabled         = false
  retention_period            = 90
  termination_protection_enabled = false
  
  advanced_event_selector {
    name = "S3 Data Events"
    
    field_selector {
      field  = "eventCategory"
      equals = ["Data"]
    }
    
    field_selector {
      field  = "resources.type"
      equals = ["AWS::S3::Object"]
    }
  }
  
  advanced_event_selector {
    name = "Lambda Function Invocations"
    
    field_selector {
      field  = "eventCategory"
      equals = ["Data"]
    }
    
    field_selector {
      field  = "resources.type"
      equals = ["AWS::Lambda::Function"]
    }
  }
}
```

## Lab 2: AWS GuardDuty

### Enable GuardDuty
```bash
# Enable GuardDuty
aws guardduty create-detector \
  --enable \
  --finding-publishing-frequency FIFTEEN_MINUTES \
  --data-sources S3Logs='{Enable=true}',Kubernetes='{AuditLogs={Enable=true}}',MalwareProtection='{ScanEc2InstanceWithFindings={EbsVolumes=true}}'

# Create IP set for trusted IPs
aws guardduty create-ip-set \
  --detector-id detector-id \
  --name trusted-ips \
  --format TXT \
  --location s3://cloudops-guardduty-ipsets/trusted-ips.txt \
  --activate

# Create threat intel set
aws guardduty create-threat-intel-set \
  --detector-id detector-id \
  --name known-threats \
  --format TXT \
  --location s3://cloudops-guardduty-ipsets/threat-ips.txt \
  --activate

# Get findings
aws guardduty list-findings \
  --detector-id detector-id \
  --finding-criteria Criterion='{
    "severity": {
      "Gte": 7.0
    },
    "updatedAt": {
      "Gte": 1640995200000
    }
  }'
```

### GuardDuty Automation
```python
# guardduty-response.py
import json
import boto3

def lambda_handler(event, context):
    guardduty = boto3.client('guardduty')
    ec2 = boto3.client('ec2')
    sns = boto3.client('sns')
    
    # Parse GuardDuty finding
    detail = event['detail']
    finding_type = detail['type']
    severity = detail['severity']
    
    # High severity findings
    if severity >= 7.0:
        # Get affected instance
        if 'instanceDetails' in detail['service']:
            instance_id = detail['service']['instanceDetails']['instanceId']
            
            # Isolate instance by modifying security group
            response = ec2.describe_instances(InstanceIds=[instance_id])
            instance = response['Reservations'][0]['Instances'][0]
            
            # Create isolation security group
            isolation_sg = ec2.create_security_group(
                GroupName=f'isolation-{instance_id}',
                Description='Isolation security group for compromised instance',
                VpcId=instance['VpcId']
            )
            
            # Modify instance security groups
            ec2.modify_instance_attribute(
                InstanceId=instance_id,
                Groups=[isolation_sg['GroupId']]
            )
            
            # Send notification
            sns.publish(
                TopicArn='arn:aws:sns:us-east-1:123456789012:security-alerts',
                Message=f'High severity GuardDuty finding: {finding_type}\nInstance {instance_id} has been isolated.',
                Subject='Security Alert: Instance Isolated'
            )
    
    return {
        'statusCode': 200,
        'body': json.dumps('GuardDuty finding processed')
    }
```

## Terraform GuardDuty Configuration

```hcl
# guardduty.tf
resource "aws_guardduty_detector" "main" {
  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"
  
  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = true
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes = true
      }
    }
  }
  
  tags = {
    Name = "CloudOps GuardDuty"
  }
}

resource "aws_guardduty_ipset" "trusted_ips" {
  activate    = true
  detector_id = aws_guardduty_detector.main.id
  format      = "TXT"
  location    = "s3://${aws_s3_bucket.guardduty_ipsets.bucket}/trusted-ips.txt"
  name        = "trusted-ips"
}

resource "aws_guardduty_threatintelset" "threat_ips" {
  activate    = true
  detector_id = aws_guardduty_detector.main.id
  format      = "TXT"
  location    = "s3://${aws_s3_bucket.guardduty_ipsets.bucket}/threat-ips.txt"
  name        = "known-threats"
}

resource "aws_s3_bucket" "guardduty_ipsets" {
  bucket = "cloudops-guardduty-ipsets-${random_string.suffix.result}"
}

resource "aws_s3_object" "trusted_ips" {
  bucket = aws_s3_bucket.guardduty_ipsets.bucket
  key    = "trusted-ips.txt"
  content = "10.0.0.0/8\n172.16.0.0/12\n192.168.0.0/16"
}

# EventBridge rule for GuardDuty findings
resource "aws_cloudwatch_event_rule" "guardduty_findings" {
  name        = "guardduty-findings"
  description = "Capture GuardDuty findings"
  
  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
    detail = {
      severity = [
        {
          numeric = [">", 7.0]
        }
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.guardduty_findings.name
  target_id = "GuardDutyResponseLambda"
  arn       = aws_lambda_function.guardduty_response.arn
}

resource "aws_lambda_function" "guardduty_response" {
  filename         = "guardduty-response.zip"
  function_name    = "guardduty-response"
  role            = aws_iam_role.guardduty_lambda_role.arn
  handler         = "lambda_function.lambda_handler"
  runtime         = "python3.9"
  timeout         = 60
}
```

## Lab 3: AWS Security Hub

### Enable Security Hub
```bash
# Enable Security Hub
aws securityhub enable-security-hub \
  --enable-default-standards

# Enable specific standards
aws securityhub batch-enable-standards \
  --standards-subscription-requests '[
    {
      "StandardsArn": "arn:aws:securityhub:::ruleset/finding-format/aws-foundational-security-standard/v/1.0.0"
    },
    {
      "StandardsArn": "arn:aws:securityhub:::ruleset/finding-format/cis-aws-foundations-benchmark/v/1.2.0"
    }
  ]'

# Get findings
aws securityhub get-findings \
  --filters '{
    "SeverityLabel": [{"Value": "HIGH", "Comparison": "EQUALS"}],
    "ComplianceStatus": [{"Value": "FAILED", "Comparison": "EQUALS"}]
  }' \
  --max-items 10

# Create custom insight
aws securityhub create-insight \
  --filters '{
    "ResourceType": [{"Value": "AwsEc2Instance", "Comparison": "EQUALS"}],
    "ComplianceStatus": [{"Value": "FAILED", "Comparison": "EQUALS"}]
  }' \
  --group-by-attribute "ResourceId" \
  --name "Non-compliant EC2 instances"
```

### Security Hub Automation
```python
# security-hub-remediation.py
import json
import boto3

def lambda_handler(event, context):
    securityhub = boto3.client('securityhub')
    ec2 = boto3.client('ec2')
    
    # Parse Security Hub finding
    detail = event['detail']
    finding_id = detail['findings'][0]['Id']
    resource_id = detail['findings'][0]['Resources'][0]['Id']
    
    # Auto-remediate specific findings
    if 'EC2.2' in finding_id:  # Security group allows unrestricted access
        # Extract security group ID from resource ARN
        sg_id = resource_id.split('/')[-1]
        
        # Remove unrestricted rules
        try:
            ec2.revoke_security_group_ingress(
                GroupId=sg_id,
                IpPermissions=[
                    {
                        'IpProtocol': '-1',
                        'IpRanges': [{'CidrIp': '0.0.0.0/0'}]
                    }
                ]
            )
            
            # Update finding status
            securityhub.batch_update_findings(
                FindingIdentifiers=[
                    {
                        'Id': finding_id,
                        'ProductArn': detail['findings'][0]['ProductArn']
                    }
                ],
                Workflow={'Status': 'RESOLVED'},
                Note={
                    'Text': 'Auto-remediated: Removed unrestricted access',
                    'UpdatedBy': 'AutoRemediation'
                }
            )
            
        except Exception as e:
            print(f"Remediation failed: {str(e)}")
    
    return {
        'statusCode': 200,
        'body': json.dumps('Security Hub finding processed')
    }
```

## Terraform Security Hub Configuration

```hcl
# security-hub.tf
resource "aws_securityhub_account" "main" {
  enable_default_standards = true
}

resource "aws_securityhub_standards_subscription" "aws_foundational" {
  standards_arn = "arn:aws:securityhub:::ruleset/finding-format/aws-foundational-security-standard/v/1.0.0"
  depends_on    = [aws_securityhub_account.main]
}

resource "aws_securityhub_standards_subscription" "cis" {
  standards_arn = "arn:aws:securityhub:::ruleset/finding-format/cis-aws-foundations-benchmark/v/1.2.0"
  depends_on    = [aws_securityhub_account.main]
}

resource "aws_securityhub_insight" "critical_findings" {
  filters {
    severity_label {
      comparison = "EQUALS"
      value      = "CRITICAL"
    }
  }
  
  group_by_attribute = "ResourceId"
  name              = "Critical findings by resource"
}

resource "aws_securityhub_insight" "ec2_compliance" {
  filters {
    resource_type {
      comparison = "EQUALS"
      value      = "AwsEc2Instance"
    }
    compliance_status {
      comparison = "EQUALS"
      value      = "FAILED"
    }
  }
  
  group_by_attribute = "ComplianceStatus"
  name              = "Non-compliant EC2 instances"
}

# Custom finding format
resource "aws_securityhub_finding_aggregator" "main" {
  linking_mode = "ALL_REGIONS"
}
```

## Lab 4: AWS Inspector

### Enable Inspector
```bash
# Enable Inspector V2
aws inspector2 enable \
  --account-ids 123456789012 \
  --resource-types ECR EC2

# Get findings
aws inspector2 list-findings \
  --filter-criteria '{
    "severity": [{"comparison": "EQUALS", "value": "HIGH"}],
    "findingStatus": [{"comparison": "EQUALS", "value": "ACTIVE"}]
  }'

# Create findings report
aws inspector2 create-findings-report \
  --report-format JSON \
  --s3-destination bucketName=cloudops-inspector-reports,keyPrefix=reports/,kmsKeyArn=arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012 \
  --filter-criteria '{
    "severity": [{"comparison": "EQUALS", "value": "HIGH"}]
  }'
```

### Terraform Inspector Configuration
```hcl
# inspector.tf
resource "aws_inspector2_enabler" "main" {
  account_ids    = [data.aws_caller_identity.current.account_id]
  resource_types = ["ECR", "EC2"]
}

resource "aws_inspector2_delegated_admin_account" "main" {
  account_id = data.aws_caller_identity.current.account_id
}

# EventBridge rule for Inspector findings
resource "aws_cloudwatch_event_rule" "inspector_findings" {
  name        = "inspector-findings"
  description = "Capture Inspector findings"
  
  event_pattern = jsonencode({
    source      = ["aws.inspector2"]
    detail-type = ["Inspector2 Finding"]
    detail = {
      severity = ["HIGH", "CRITICAL"]
    }
  })
}
```

## Lab 5: AWS Secrets Manager

### Create and Manage Secrets
```bash
# Create secret
aws secretsmanager create-secret \
  --name cloudops/database/credentials \
  --description "Database credentials for CloudOps application" \
  --secret-string '{
    "username": "admin",
    "password": "MySecurePassword123!",
    "host": "db.cloudops.example.com",
    "port": 3306
  }' \
  --kms-key-id arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012

# Retrieve secret
aws secretsmanager get-secret-value \
  --secret-id cloudops/database/credentials \
  --query SecretString \
  --output text

# Update secret
aws secretsmanager update-secret \
  --secret-id cloudops/database/credentials \
  --secret-string '{
    "username": "admin",
    "password": "NewSecurePassword456!",
    "host": "db.cloudops.example.com",
    "port": 3306
  }'

# Enable automatic rotation
aws secretsmanager rotate-secret \
  --secret-id cloudops/database/credentials \
  --rotation-lambda-arn arn:aws:lambda:us-east-1:123456789012:function:SecretsManagerRDSMySQLRotationSingleUser \
  --rotation-rules AutomaticallyAfterDays=30
```

### Terraform Secrets Manager Configuration
```hcl
# secrets-manager.tf
resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "cloudops/database/credentials"
  description = "Database credentials for CloudOps application"
  kms_key_id  = aws_kms_key.secrets_key.arn
  
  replica {
    region = "us-west-2"
  }
  
  tags = {
    Name = "CloudOps DB Credentials"
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = "admin"
    password = var.db_password
    host     = aws_db_instance.main.endpoint
    port     = aws_db_instance.main.port
  })
}

resource "aws_secretsmanager_secret_rotation" "db_credentials" {
  secret_id           = aws_secretsmanager_secret.db_credentials.id
  rotation_lambda_arn = aws_lambda_function.rotation_lambda.arn
  
  rotation_rules {
    automatically_after_days = 30
  }
}

resource "aws_kms_key" "secrets_key" {
  description = "KMS key for Secrets Manager"
  
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
      }
    ]
  })
}
```

## Lab 6: AWS KMS

### Create and Manage KMS Keys
```bash
# Create KMS key
aws kms create-key \
  --description "CloudOps encryption key" \
  --key-usage ENCRYPT_DECRYPT \
  --key-spec SYMMETRIC_DEFAULT

# Create alias
aws kms create-alias \
  --alias-name alias/cloudops-key \
  --target-key-id key-id

# Encrypt data
aws kms encrypt \
  --key-id alias/cloudops-key \
  --plaintext "Sensitive data to encrypt" \
  --output text \
  --query CiphertextBlob

# Decrypt data
aws kms decrypt \
  --ciphertext-blob fileb://encrypted-data.bin \
  --output text \
  --query Plaintext | base64 --decode

# Generate data key
aws kms generate-data-key \
  --key-id alias/cloudops-key \
  --key-spec AES_256
```

### Terraform KMS Configuration
```hcl
# kms.tf
resource "aws_kms_key" "cloudops_key" {
  description             = "CloudOps encryption key"
  deletion_window_in_days = 7
  
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
        Sid    = "Allow CloudOps Role"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.cloudops_role.arn
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
  
  tags = {
    Name = "CloudOps Encryption Key"
  }
}

resource "aws_kms_alias" "cloudops_key_alias" {
  name          = "alias/cloudops-key"
  target_key_id = aws_kms_key.cloudops_key.key_id
}

resource "aws_kms_grant" "cloudops_grant" {
  name              = "cloudops-grant"
  key_id            = aws_kms_key.cloudops_key.key_id
  grantee_principal = aws_iam_role.cloudops_role.arn
  operations        = ["Encrypt", "Decrypt", "GenerateDataKey"]
}
```

## Best Practices

1. **Enable CloudTrail** in all regions
2. **Use GuardDuty** for threat detection
3. **Implement Security Hub** for centralized findings
4. **Regular security assessments** with Inspector
5. **Use Secrets Manager** for credentials
6. **Encrypt data** with KMS
7. **Automate security responses**

## Security Monitoring Dashboard

```python
# security-dashboard.py
import boto3
import json

def create_security_dashboard():
    cloudwatch = boto3.client('cloudwatch')
    
    dashboard_body = {
        "widgets": [
            {
                "type": "metric",
                "properties": {
                    "metrics": [
                        ["AWS/GuardDuty", "FindingCount"],
                        ["AWS/SecurityHub", "Findings"]
                    ],
                    "period": 300,
                    "stat": "Sum",
                    "region": "us-east-1",
                    "title": "Security Findings"
                }
            },
            {
                "type": "log",
                "properties": {
                    "query": "SOURCE '/aws/lambda/guardduty-response' | fields @timestamp, @message | filter @message like /HIGH/",
                    "region": "us-east-1",
                    "title": "High Severity Alerts"
                }
            }
        ]
    }
    
    cloudwatch.put_dashboard(
        DashboardName='CloudOps-Security-Dashboard',
        DashboardBody=json.dumps(dashboard_body)
    )
```

## Compliance Reporting

```bash
# Generate compliance report
aws securityhub get-findings \
  --filters '{
    "ComplianceStatus": [{"Value": "FAILED", "Comparison": "EQUALS"}]
  }' \
  --query 'Findings[*].[Id,Title,Severity.Label,Compliance.Status]' \
  --output table

# Export findings to S3
aws securityhub get-findings \
  --filters '{}' \
  --query 'Findings' > security-findings.json

aws s3 cp security-findings.json s3://cloudops-compliance-reports/
```

## Cleanup

```bash
# Disable GuardDuty
aws guardduty delete-detector --detector-id detector-id

# Disable Security Hub
aws securityhub disable-security-hub

# Delete CloudTrail
aws cloudtrail delete-trail --name cloudops-trail

# Delete secrets
aws secretsmanager delete-secret \
  --secret-id cloudops/database/credentials \
  --force-delete-without-recovery
```