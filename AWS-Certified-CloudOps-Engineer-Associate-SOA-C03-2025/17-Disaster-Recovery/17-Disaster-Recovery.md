# 17. Disaster Recovery

## Lab 1: Multi-Region Backup Strategy

### Create Cross-Region Backup
```bash
# Create backup plan
aws backup create-backup-plan \
  --backup-plan '{
    "BackupPlanName": "CloudOps-DR-Plan",
    "Rules": [{
      "RuleName": "DailyBackups",
      "TargetBackupVault": "default",
      "ScheduleExpression": "cron(0 5 ? * * *)",
      "Lifecycle": {
        "DeleteAfterDays": 30,
        "MoveToColdStorageAfterDays": 7
      },
      "CopyActions": [{
        "DestinationBackupVaultArn": "arn:aws:backup:us-west-2:123456789012:backup-vault:dr-vault",
        "Lifecycle": {
          "DeleteAfterDays": 90
        }
      }]
    }]
  }'

# Create backup selection
aws backup create-backup-selection \
  --backup-plan-id backup-plan-id \
  --backup-selection '{
    "SelectionName": "CloudOps-Resources",
    "IamRoleArn": "arn:aws:iam::123456789012:role/aws-backup-service-role",
    "Resources": [
      "arn:aws:ec2:us-east-1:123456789012:instance/*",
      "arn:aws:rds:us-east-1:123456789012:db:*"
    ],
    "Conditions": {
      "StringEquals": {
        "aws:ResourceTag/Environment": ["Production"]
      }
    }
  }'
```

### Terraform Backup Configuration
```hcl
# backup.tf
resource "aws_backup_vault" "cloudops_vault" {
  name        = "cloudops-backup-vault"
  kms_key_arn = aws_kms_key.backup_key.arn
  
  tags = {
    Name = "CloudOps Backup Vault"
  }
}

resource "aws_backup_vault" "dr_vault" {
  provider    = aws.dr_region
  name        = "cloudops-dr-vault"
  kms_key_arn = aws_kms_key.dr_backup_key.arn
  
  tags = {
    Name = "CloudOps DR Vault"
  }
}

resource "aws_backup_plan" "cloudops_backup" {
  name = "CloudOps-DR-Plan"
  
  rule {
    rule_name         = "DailyBackups"
    target_vault_name = aws_backup_vault.cloudops_vault.name
    schedule          = "cron(0 5 ? * * *)"
    
    lifecycle {
      delete_after                = 30
      move_to_cold_storage_after = 7
    }
    
    copy_action {
      destination_vault_arn = aws_backup_vault.dr_vault.arn
      
      lifecycle {
        delete_after = 90
      }
    }
    
    recovery_point_tags = {
      Environment = "Production"
    }
  }
  
  tags = {
    Name = "CloudOps Backup Plan"
  }
}

resource "aws_backup_selection" "cloudops_selection" {
  iam_role_arn = aws_iam_role.backup_role.arn
  name         = "CloudOps-Resources"
  plan_id      = aws_backup_plan.cloudops_backup.id
  
  resources = [
    "arn:aws:ec2:*:*:instance/*",
    "arn:aws:rds:*:*:db:*"
  ]
  
  condition {
    string_equals {
      key   = "aws:ResourceTag/Environment"
      value = "Production"
    }
  }
}

resource "aws_kms_key" "backup_key" {
  description = "KMS key for backup encryption"
  
  tags = {
    Name = "Backup Encryption Key"
  }
}
```

## Lab 2: RDS Multi-Region Setup

### Create RDS with Cross-Region Replica
```bash
# Create primary RDS instance
aws rds create-db-instance \
  --db-instance-identifier cloudops-db-primary \
  --db-instance-class db.t3.micro \
  --engine mysql \
  --engine-version 8.0.35 \
  --master-username admin \
  --master-user-password MySecurePassword123! \
  --allocated-storage 20 \
  --backup-retention-period 7 \
  --multi-az \
  --storage-encrypted

# Create cross-region read replica
aws rds create-db-instance-read-replica \
  --db-instance-identifier cloudops-db-replica \
  --source-db-instance-identifier arn:aws:rds:us-east-1:123456789012:db:cloudops-db-primary \
  --db-instance-class db.t3.micro \
  --region us-west-2

# Promote read replica (for failover)
aws rds promote-read-replica \
  --db-instance-identifier cloudops-db-replica \
  --backup-retention-period 7 \
  --region us-west-2
```

### Terraform RDS DR Configuration
```hcl
# rds-dr.tf
resource "aws_db_instance" "primary" {
  identifier = "cloudops-db-primary"
  
  engine         = "mysql"
  engine_version = "8.0.35"
  instance_class = "db.t3.micro"
  
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp2"
  storage_encrypted     = true
  
  db_name  = "cloudops"
  username = "admin"
  password = var.db_password
  
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.primary.name
  
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  multi_az               = true
  skip_final_snapshot    = false
  final_snapshot_identifier = "cloudops-db-final-snapshot"
  
  tags = {
    Name = "CloudOps Primary Database"
  }
}

resource "aws_db_instance" "replica" {
  provider = aws.dr_region
  
  identifier = "cloudops-db-replica"
  
  replicate_source_db = aws_db_instance.primary.arn
  instance_class      = "db.t3.micro"
  
  vpc_security_group_ids = [aws_security_group.rds_sg_dr.id]
  
  skip_final_snapshot = true
  
  tags = {
    Name = "CloudOps Replica Database"
  }
}
```

## Lab 3: S3 Cross-Region Replication

### Configure S3 Replication
```bash
# Create replication role
cat > replication-role-trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

aws iam create-role \
  --role-name S3ReplicationRole \
  --assume-role-policy-document file://replication-role-trust-policy.json

# Create replication policy
cat > replication-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObjectVersionForReplication",
        "s3:GetObjectVersionAcl"
      ],
      "Resource": "arn:aws:s3:::cloudops-primary-bucket/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket"
      ],
      "Resource": "arn:aws:s3:::cloudops-primary-bucket"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:ReplicateObject",
        "s3:ReplicateDelete"
      ],
      "Resource": "arn:aws:s3:::cloudops-dr-bucket/*"
    }
  ]
}
EOF

aws iam put-role-policy \
  --role-name S3ReplicationRole \
  --policy-name S3ReplicationPolicy \
  --policy-document file://replication-policy.json

# Configure replication
cat > replication-config.json << EOF
{
  "Role": "arn:aws:iam::123456789012:role/S3ReplicationRole",
  "Rules": [
    {
      "ID": "ReplicateEverything",
      "Status": "Enabled",
      "Priority": 1,
      "Filter": {
        "Prefix": ""
      },
      "Destination": {
        "Bucket": "arn:aws:s3:::cloudops-dr-bucket",
        "StorageClass": "STANDARD_IA"
      }
    }
  ]
}
EOF

aws s3api put-bucket-replication \
  --bucket cloudops-primary-bucket \
  --replication-configuration file://replication-config.json
```

### Terraform S3 Replication
```hcl
# s3-replication.tf
resource "aws_s3_bucket" "primary" {
  bucket = "cloudops-primary-${random_string.bucket_suffix.result}"
  
  tags = {
    Name = "CloudOps Primary Bucket"
  }
}

resource "aws_s3_bucket" "dr" {
  provider = aws.dr_region
  bucket   = "cloudops-dr-${random_string.bucket_suffix.result}"
  
  tags = {
    Name = "CloudOps DR Bucket"
  }
}

resource "aws_s3_bucket_versioning" "primary" {
  bucket = aws_s3_bucket.primary.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "dr" {
  provider = aws.dr_region
  bucket   = aws_s3_bucket.dr.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_replication_configuration" "replication" {
  role   = aws_iam_role.replication.arn
  bucket = aws_s3_bucket.primary.id
  
  rule {
    id     = "ReplicateEverything"
    status = "Enabled"
    
    destination {
      bucket        = aws_s3_bucket.dr.arn
      storage_class = "STANDARD_IA"
    }
  }
  
  depends_on = [aws_s3_bucket_versioning.primary]
}

resource "aws_iam_role" "replication" {
  name = "S3ReplicationRole"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}
```

## Lab 4: Route 53 Health Checks and Failover

### Create Health Checks
```bash
# Create health check for primary region
aws route53 create-health-check \
  --caller-reference "primary-health-check-$(date +%s)" \
  --health-check-config '{
    "Type": "HTTP",
    "ResourcePath": "/health",
    "FullyQualifiedDomainName": "primary.cloudops.example.com",
    "Port": 80,
    "RequestInterval": 30,
    "FailureThreshold": 3
  }'

# Create health check for DR region
aws route53 create-health-check \
  --caller-reference "dr-health-check-$(date +%s)" \
  --health-check-config '{
    "Type": "HTTP",
    "ResourcePath": "/health",
    "FullyQualifiedDomainName": "dr.cloudops.example.com",
    "Port": 80,
    "RequestInterval": 30,
    "FailureThreshold": 3
  }'

# Configure DNS failover
cat > primary-record.json << EOF
{
  "Changes": [
    {
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "app.cloudops.example.com",
        "Type": "A",
        "SetIdentifier": "Primary",
        "Failover": "PRIMARY",
        "HealthCheckId": "health-check-id-primary",
        "TTL": 60,
        "ResourceRecords": [
          {
            "Value": "1.2.3.4"
          }
        ]
      }
    }
  ]
}
EOF

aws route53 change-resource-record-sets \
  --hosted-zone-id Z123456789 \
  --change-batch file://primary-record.json
```

### Terraform Route 53 Failover
```hcl
# route53-failover.tf
resource "aws_route53_zone" "main" {
  name = "cloudops.example.com"
  
  tags = {
    Name = "CloudOps Zone"
  }
}

resource "aws_route53_health_check" "primary" {
  fqdn                            = "primary.cloudops.example.com"
  port                            = 80
  type                            = "HTTP"
  resource_path                   = "/health"
  failure_threshold               = "3"
  request_interval                = "30"
  
  tags = {
    Name = "Primary Health Check"
  }
}

resource "aws_route53_health_check" "dr" {
  fqdn                            = "dr.cloudops.example.com"
  port                            = 80
  type                            = "HTTP"
  resource_path                   = "/health"
  failure_threshold               = "3"
  request_interval                = "30"
  
  tags = {
    Name = "DR Health Check"
  }
}

resource "aws_route53_record" "primary" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "app.cloudops.example.com"
  type    = "A"
  ttl     = 60
  
  set_identifier = "Primary"
  failover_routing_policy {
    type = "PRIMARY"
  }
  
  health_check_id = aws_route53_health_check.primary.id
  records         = [aws_eip.primary.public_ip]
}

resource "aws_route53_record" "dr" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "app.cloudops.example.com"
  type    = "A"
  ttl     = 60
  
  set_identifier = "DR"
  failover_routing_policy {
    type = "SECONDARY"
  }
  
  records = [aws_eip.dr.public_ip]
}
```

## Lab 5: Automated DR Testing

### DR Test Script
```bash
#!/bin/bash
# dr-test.sh

echo "Starting DR test..."

# 1. Simulate primary region failure
echo "Simulating primary region failure..."
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name primary-asg \
  --desired-capacity 0 \
  --region us-east-1

# 2. Wait for health check failure
echo "Waiting for health check failure..."
sleep 300

# 3. Check Route 53 failover
echo "Checking DNS resolution..."
nslookup app.cloudops.example.com

# 4. Promote RDS replica
echo "Promoting RDS replica..."
aws rds promote-read-replica \
  --db-instance-identifier cloudops-db-replica \
  --region us-west-2

# 5. Scale up DR region
echo "Scaling up DR region..."
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name dr-asg \
  --desired-capacity 2 \
  --region us-west-2

# 6. Verify application availability
echo "Testing application availability..."
curl -f http://app.cloudops.example.com/health

if [ $? -eq 0 ]; then
    echo "DR test successful!"
else
    echo "DR test failed!"
    exit 1
fi

echo "DR test completed."
```

### Terraform DR Test Automation
```hcl
# dr-test.tf
resource "aws_lambda_function" "dr_test" {
  filename         = "dr-test.zip"
  function_name    = "cloudops-dr-test"
  role            = aws_iam_role.dr_test_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 900
  
  environment {
    variables = {
      PRIMARY_ASG = "primary-asg"
      DR_ASG      = "dr-asg"
      DB_REPLICA  = "cloudops-db-replica"
    }
  }
}

resource "aws_cloudwatch_event_rule" "monthly_dr_test" {
  name                = "monthly-dr-test"
  description         = "Monthly DR test"
  schedule_expression = "cron(0 2 1 * ? *)"
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.monthly_dr_test.name
  target_id = "TriggerDRTest"
  arn       = aws_lambda_function.dr_test.arn
}
```

## Lab 6: Recovery Time and Point Objectives

### RTO/RPO Monitoring
```bash
# Create CloudWatch custom metrics for RTO/RPO
aws cloudwatch put-metric-data \
  --namespace "CloudOps/DR" \
  --metric-data '[
    {
      "MetricName": "RecoveryTimeObjective",
      "Value": 15,
      "Unit": "Minutes",
      "Dimensions": [
        {
          "Name": "Service",
          "Value": "WebApplication"
        }
      ]
    },
    {
      "MetricName": "RecoveryPointObjective",
      "Value": 5,
      "Unit": "Minutes",
      "Dimensions": [
        {
          "Name": "Service",
          "Value": "Database"
        }
      ]
    }
  ]'

# Create alarm for RTO breach
aws cloudwatch put-metric-alarm \
  --alarm-name "RTO-Breach" \
  --alarm-description "RTO objective breached" \
  --metric-name "RecoveryTimeObjective" \
  --namespace "CloudOps/DR" \
  --statistic "Maximum" \
  --period 300 \
  --threshold 15 \
  --comparison-operator "GreaterThanThreshold" \
  --evaluation-periods 1
```

## Best Practices

1. **Define clear RTO/RPO** objectives
2. **Regular DR testing** and validation
3. **Automate failover** processes
4. **Monitor replication lag**
5. **Document procedures** thoroughly
6. **Train team members** on DR processes
7. **Review and update** DR plans regularly

## Monitoring DR Health

```bash
# Check backup job status
aws backup list-backup-jobs \
  --by-state COMPLETED \
  --by-backup-vault-name cloudops-backup-vault

# Check replication status
aws s3api get-bucket-replication \
  --bucket cloudops-primary-bucket

# Check RDS replica lag
aws rds describe-db-instances \
  --db-instance-identifier cloudops-db-replica \
  --query 'DBInstances[0].ReadReplicaSourceDBInstanceIdentifier'
```

## Cleanup

```bash
# Delete backup plan
aws backup delete-backup-plan --backup-plan-id backup-plan-id

# Delete RDS replica
aws rds delete-db-instance \
  --db-instance-identifier cloudops-db-replica \
  --skip-final-snapshot

# Delete replication configuration
aws s3api delete-bucket-replication \
  --bucket cloudops-primary-bucket
```