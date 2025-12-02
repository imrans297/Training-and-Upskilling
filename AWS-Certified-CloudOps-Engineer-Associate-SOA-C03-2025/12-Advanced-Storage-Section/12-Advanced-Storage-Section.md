# 12. Advanced Storage Section

## Lab 1: AWS Storage Gateway

### File Gateway Setup
```bash
# Create file gateway
aws storagegateway create-gateway \
  --gateway-name CloudOps-File-Gateway \
  --gateway-timezone GMT \
  --gateway-region us-east-1 \
  --gateway-type FILE_S3

# Create NFS file share
aws storagegateway create-nfs-file-share \
  --client-token "nfs-share-$(date +%s)" \
  --gateway-arn arn:aws:storagegateway:us-east-1:123456789012:gateway/sgw-xxxxxxxxx \
  --location-arn arn:aws:s3:::cloudops-file-gateway-bucket \
  --role arn:aws:iam::123456789012:role/storagegateway-role \
  --client-list 10.0.0.0/24 \
  --squash RootSquash \
  --read-only false

# Create SMB file share
aws storagegateway create-smb-file-share \
  --client-token "smb-share-$(date +%s)" \
  --gateway-arn arn:aws:storagegateway:us-east-1:123456789012:gateway/sgw-xxxxxxxxx \
  --location-arn arn:aws:s3:::cloudops-file-gateway-bucket \
  --role arn:aws:iam::123456789012:role/storagegateway-role \
  --valid-user-list user1,user2 \
  --authentication ActiveDirectory
```

### Volume Gateway Setup
```bash
# Create stored volume
aws storagegateway create-stored-iscsi-volume \
  --gateway-arn arn:aws:storagegateway:us-east-1:123456789012:gateway/sgw-xxxxxxxxx \
  --disk-id pci-0000:00:1f.0-scsi-0:0:0:0 \
  --preserve-existing-data false \
  --target-name cloudops-stored-volume \
  --network-interface-id 192.168.1.100

# Create cached volume
aws storagegateway create-cached-iscsi-volume \
  --gateway-arn arn:aws:storagegateway:us-east-1:123456789012:gateway/sgw-xxxxxxxxx \
  --volume-size-in-bytes 107374182400 \
  --snapshot-id snap-xxxxxxxxx \
  --target-name cloudops-cached-volume \
  --network-interface-id 192.168.1.101
```

## Terraform Storage Gateway Configuration

```hcl
# storage-gateway.tf
resource "aws_storagegateway_gateway" "file_gateway" {
  gateway_name     = "CloudOps-File-Gateway"
  gateway_timezone = "GMT"
  gateway_type     = "FILE_S3"
  
  tags = {
    Name = "CloudOps File Gateway"
  }
}

resource "aws_s3_bucket" "gateway_bucket" {
  bucket = "cloudops-file-gateway-${random_string.suffix.result}"
}

resource "aws_storagegateway_nfs_file_share" "nfs_share" {
  client_list  = ["10.0.0.0/24"]
  gateway_arn  = aws_storagegateway_gateway.file_gateway.arn
  location_arn = aws_s3_bucket.gateway_bucket.arn
  role_arn     = aws_iam_role.storagegateway_role.arn
  
  default_storage_class = "S3_STANDARD"
  guess_mime_type_enabled = true
  read_only = false
  squash = "RootSquash"
  
  tags = {
    Name = "CloudOps NFS Share"
  }
}

resource "aws_storagegateway_smb_file_share" "smb_share" {
  authentication    = "ActiveDirectory"
  gateway_arn      = aws_storagegateway_gateway.file_gateway.arn
  location_arn     = aws_s3_bucket.gateway_bucket.arn
  role_arn         = aws_iam_role.storagegateway_role.arn
  valid_user_list  = ["user1", "user2"]
  
  tags = {
    Name = "CloudOps SMB Share"
  }
}

resource "aws_iam_role" "storagegateway_role" {
  name = "StorageGatewayRole"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "storagegateway.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "storagegateway_policy" {
  name = "StorageGatewayPolicy"
  role = aws_iam_role.storagegateway_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetAccelerateConfiguration",
          "s3:GetBucketLocation",
          "s3:GetBucketVersioning",
          "s3:ListBucket",
          "s3:ListBucketVersions",
          "s3:ListBucketMultipartUploads"
        ]
        Resource = aws_s3_bucket.gateway_bucket.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:AbortMultipartUpload",
          "s3:DeleteObject",
          "s3:DeleteObjectVersion",
          "s3:GetObject",
          "s3:GetObjectAcl",
          "s3:GetObjectVersion",
          "s3:ListMultipartUploadParts",
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = "${aws_s3_bucket.gateway_bucket.arn}/*"
      }
    ]
  })
}
```

## Lab 2: AWS DataSync

### Create DataSync Task
```bash
# Create source location (on-premises)
aws datasync create-location-nfs \
  --server-hostname 192.168.1.100 \
  --subdirectory /data \
  --on-prem-config AgentArns=arn:aws:datasync:us-east-1:123456789012:agent/agent-xxxxxxxxx

# Create destination location (S3)
aws datasync create-location-s3 \
  --s3-bucket-arn arn:aws:s3:::cloudops-datasync-destination \
  --subdirectory /migrated-data \
  --s3-config BucketAccessRoleArn=arn:aws:iam::123456789012:role/datasync-role

# Create DataSync task
aws datasync create-task \
  --source-location-arn arn:aws:datasync:us-east-1:123456789012:location/loc-xxxxxxxxx \
  --destination-location-arn arn:aws:datasync:us-east-1:123456789012:location/loc-yyyyyyyyy \
  --name CloudOps-Migration-Task \
  --options VerifyMode=POINT_IN_TIME_CONSISTENT,OverwriteMode=ALWAYS,Atime=BEST_EFFORT,Mtime=PRESERVE,Uid=INT_VALUE,Gid=INT_VALUE,PreserveDeletedFiles=PRESERVE,PreserveDevices=NONE,PosixPermissions=PRESERVE,BytesPerSecond=104857600

# Start task execution
aws datasync start-task-execution \
  --task-arn arn:aws:datasync:us-east-1:123456789012:task/task-xxxxxxxxx
```

### Monitor DataSync Progress
```bash
# Check task execution status
aws datasync describe-task-execution \
  --task-execution-arn arn:aws:datasync:us-east-1:123456789012:task/task-xxxxxxxxx/execution/exec-xxxxxxxxx

# List task executions
aws datasync list-task-executions \
  --task-arn arn:aws:datasync:us-east-1:123456789012:task/task-xxxxxxxxx

# Get task execution metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/DataSync \
  --metric-name BytesTransferred \
  --dimensions Name=TaskId,Value=task-xxxxxxxxx \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-01T23:59:59Z \
  --period 3600 \
  --statistics Sum
```

## Terraform DataSync Configuration

```hcl
# datasync.tf
resource "aws_datasync_location_s3" "source" {
  s3_bucket_arn = aws_s3_bucket.source.arn
  subdirectory  = "/source-data"
  
  s3_config {
    bucket_access_role_arn = aws_iam_role.datasync_role.arn
  }
  
  tags = {
    Name = "DataSync Source Location"
  }
}

resource "aws_datasync_location_s3" "destination" {
  s3_bucket_arn = aws_s3_bucket.destination.arn
  subdirectory  = "/migrated-data"
  
  s3_config {
    bucket_access_role_arn = aws_iam_role.datasync_role.arn
  }
  
  tags = {
    Name = "DataSync Destination Location"
  }
}

resource "aws_datasync_task" "migration_task" {
  destination_location_arn = aws_datasync_location_s3.destination.arn
  name                     = "CloudOps-Migration-Task"
  source_location_arn      = aws_datasync_location_s3.source.arn
  
  options {
    bytes_per_second      = 104857600  # 100 MB/s
    verify_mode          = "POINT_IN_TIME_CONSISTENT"
    overwrite_mode       = "ALWAYS"
    preserve_deleted_files = "PRESERVE"
    preserve_devices     = "NONE"
    posix_permissions    = "PRESERVE"
    uid                  = "INT_VALUE"
    gid                  = "INT_VALUE"
    atime                = "BEST_EFFORT"
    mtime                = "PRESERVE"
  }
  
  tags = {
    Name = "CloudOps Migration Task"
  }
}

resource "aws_iam_role" "datasync_role" {
  name = "DataSyncRole"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "datasync.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "datasync_policy" {
  name = "DataSyncPolicy"
  role = aws_iam_role.datasync_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads"
        ]
        Resource = [
          aws_s3_bucket.source.arn,
          aws_s3_bucket.destination.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:AbortMultipartUpload",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:ListMultipartUploadParts",
          "s3:PutObject",
          "s3:GetObjectTagging",
          "s3:PutObjectTagging"
        ]
        Resource = [
          "${aws_s3_bucket.source.arn}/*",
          "${aws_s3_bucket.destination.arn}/*"
        ]
      }
    ]
  })
}
```

## Lab 3: AWS Backup

### Create Backup Plan
```bash
# Create backup plan
aws backup create-backup-plan \
  --backup-plan '{
    "BackupPlanName": "CloudOps-Comprehensive-Backup",
    "Rules": [
      {
        "RuleName": "DailyBackups",
        "TargetBackupVault": "default",
        "ScheduleExpression": "cron(0 5 ? * * *)",
        "StartWindowMinutes": 480,
        "CompletionWindowMinutes": 10080,
        "Lifecycle": {
          "MoveToColdStorageAfterDays": 30,
          "DeleteAfterDays": 120
        },
        "RecoveryPointTags": {
          "BackupType": "Daily",
          "Environment": "Production"
        }
      },
      {
        "RuleName": "WeeklyBackups",
        "TargetBackupVault": "default",
        "ScheduleExpression": "cron(0 5 ? * SUN *)",
        "StartWindowMinutes": 480,
        "CompletionWindowMinutes": 10080,
        "Lifecycle": {
          "MoveToColdStorageAfterDays": 7,
          "DeleteAfterDays": 365
        }
      }
    ]
  }'

# Create backup selection
aws backup create-backup-selection \
  --backup-plan-id backup-plan-id \
  --backup-selection '{
    "SelectionName": "CloudOps-Resources",
    "IamRoleArn": "arn:aws:iam::123456789012:role/aws-backup-service-role",
    "Resources": [
      "arn:aws:ec2:*:*:volume/*",
      "arn:aws:rds:*:*:db:*",
      "arn:aws:efs:*:*:file-system/*"
    ],
    "Conditions": {
      "StringEquals": {
        "aws:ResourceTag/Environment": ["Production", "Staging"]
      }
    }
  }'
```

### Cross-Region Backup
```bash
# Create backup vault in secondary region
aws backup create-backup-vault \
  --backup-vault-name CloudOps-DR-Vault \
  --encryption-key-arn arn:aws:kms:us-west-2:123456789012:key/12345678-1234-1234-1234-123456789012 \
  --region us-west-2

# Create backup plan with cross-region copy
aws backup create-backup-plan \
  --backup-plan '{
    "BackupPlanName": "CloudOps-DR-Backup",
    "Rules": [{
      "RuleName": "CrossRegionBackup",
      "TargetBackupVault": "default",
      "ScheduleExpression": "cron(0 5 ? * * *)",
      "Lifecycle": {
        "DeleteAfterDays": 35
      },
      "CopyActions": [{
        "DestinationBackupVaultArn": "arn:aws:backup:us-west-2:123456789012:backup-vault:CloudOps-DR-Vault",
        "Lifecycle": {
          "DeleteAfterDays": 90
        }
      }]
    }]
  }'
```

## Terraform Backup Configuration

```hcl
# backup.tf
resource "aws_backup_vault" "main" {
  name        = "CloudOps-Backup-Vault"
  kms_key_arn = aws_kms_key.backup_key.arn
  
  tags = {
    Name = "CloudOps Backup Vault"
  }
}

resource "aws_backup_vault" "dr" {
  provider = aws.dr_region
  
  name        = "CloudOps-DR-Vault"
  kms_key_arn = aws_kms_key.dr_backup_key.arn
  
  tags = {
    Name = "CloudOps DR Vault"
  }
}

resource "aws_backup_plan" "comprehensive" {
  name = "CloudOps-Comprehensive-Backup"
  
  rule {
    rule_name         = "DailyBackups"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 5 ? * * *)"
    
    start_window      = 480
    completion_window = 10080
    
    lifecycle {
      cold_storage_after = 30
      delete_after      = 120
    }
    
    recovery_point_tags = {
      BackupType  = "Daily"
      Environment = "Production"
    }
    
    copy_action {
      destination_vault_arn = aws_backup_vault.dr.arn
      
      lifecycle {
        cold_storage_after = 7
        delete_after      = 90
      }
    }
  }
  
  rule {
    rule_name         = "WeeklyBackups"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 5 ? * SUN *)"
    
    lifecycle {
      cold_storage_after = 7
      delete_after      = 365
    }
  }
  
  tags = {
    Name = "CloudOps Backup Plan"
  }
}

resource "aws_backup_selection" "resources" {
  iam_role_arn = aws_iam_role.backup_role.arn
  name         = "CloudOps-Resources"
  plan_id      = aws_backup_plan.comprehensive.id
  
  resources = [
    "arn:aws:ec2:*:*:volume/*",
    "arn:aws:rds:*:*:db:*",
    "arn:aws:efs:*:*:file-system/*"
  ]
  
  condition {
    string_equals {
      key   = "aws:ResourceTag/Environment"
      value = "Production"
    }
  }
  
  condition {
    string_equals {
      key   = "aws:ResourceTag/BackupEnabled"
      value = "true"
    }
  }
}

resource "aws_kms_key" "backup_key" {
  description = "KMS key for backup encryption"
  
  tags = {
    Name = "Backup Encryption Key"
  }
}

resource "aws_iam_role" "backup_role" {
  name = "AWSBackupServiceRole"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "backup_policy" {
  role       = aws_iam_role.backup_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}
```

## Lab 4: AWS FSx

### Create FSx for Windows File Server
```bash
# Create FSx Windows file system
aws fsx create-file-system \
  --file-system-type WINDOWS \
  --storage-capacity 32 \
  --subnet-ids subnet-xxxxxxxxx \
  --security-group-ids sg-xxxxxxxxx \
  --windows-configuration '{
    "ActiveDirectoryId": "d-xxxxxxxxx",
    "ThroughputCapacity": 8,
    "WeeklyMaintenanceStartTime": "1:00:00",
    "DailyAutomaticBackupStartTime": "01:00",
    "AutomaticBackupRetentionDays": 7,
    "CopyTagsToBackups": true
  }'

# Create FSx backup
aws fsx create-backup \
  --file-system-id fs-xxxxxxxxx \
  --tags Key=Name,Value="CloudOps FSx Backup"
```

### Create FSx for Lustre
```bash
# Create FSx Lustre file system
aws fsx create-file-system \
  --file-system-type LUSTRE \
  --storage-capacity 1200 \
  --subnet-ids subnet-xxxxxxxxx \
  --security-group-ids sg-xxxxxxxxx \
  --lustre-configuration '{
    "ImportPath": "s3://cloudops-lustre-data",
    "ExportPath": "s3://cloudops-lustre-data/exports",
    "ImportedFileChunkSize": 1024,
    "DeploymentType": "SCRATCH_2",
    "PerUnitStorageThroughput": 125
  }'
```

## Terraform FSx Configuration

```hcl
# fsx.tf
resource "aws_fsx_windows_file_system" "main" {
  storage_capacity    = 32
  subnet_ids         = [aws_subnet.private.id]
  throughput_capacity = 8
  security_group_ids = [aws_security_group.fsx_sg.id]
  
  active_directory_id = aws_directory_service_directory.main.id
  
  automatic_backup_retention_days   = 7
  daily_automatic_backup_start_time = "01:00"
  weekly_maintenance_start_time     = "1:00:00"
  copy_tags_to_backups             = true
  
  tags = {
    Name = "CloudOps FSx Windows"
  }
}

resource "aws_fsx_lustre_file_system" "main" {
  storage_capacity      = 1200
  subnet_ids           = [aws_subnet.private.id]
  deployment_type      = "SCRATCH_2"
  per_unit_storage_throughput = 125
  
  import_path = "s3://${aws_s3_bucket.lustre_data.bucket}"
  export_path = "s3://${aws_s3_bucket.lustre_data.bucket}/exports"
  imported_file_chunk_size = 1024
  
  security_group_ids = [aws_security_group.fsx_sg.id]
  
  tags = {
    Name = "CloudOps FSx Lustre"
  }
}

resource "aws_security_group" "fsx_sg" {
  name_prefix = "fsx-sg"
  vpc_id      = aws_vpc.main.id
  
  # Windows File Server ports
  ingress {
    from_port   = 445
    to_port     = 445
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }
  
  # Lustre ports
  ingress {
    from_port   = 988
    to_port     = 988
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }
  
  ingress {
    from_port   = 1021
    to_port     = 1023
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

## Lab 5: Storage Performance Monitoring

### CloudWatch Storage Metrics
```bash
# Monitor EBS performance
aws cloudwatch get-metric-statistics \
  --namespace AWS/EBS \
  --metric-name VolumeReadOps \
  --dimensions Name=VolumeId,Value=vol-xxxxxxxxx \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-01T23:59:59Z \
  --period 3600 \
  --statistics Sum

# Monitor EFS performance
aws cloudwatch get-metric-statistics \
  --namespace AWS/EFS \
  --metric-name TotalIOBytes \
  --dimensions Name=FileSystemId,Value=fs-xxxxxxxxx \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-01T23:59:59Z \
  --period 3600 \
  --statistics Sum

# Monitor FSx performance
aws cloudwatch get-metric-statistics \
  --namespace AWS/FSx \
  --metric-name DataReadBytes \
  --dimensions Name=FileSystemId,Value=fs-xxxxxxxxx \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-01T23:59:59Z \
  --period 3600 \
  --statistics Sum
```

### Storage Cost Optimization
```bash
# Analyze S3 storage costs
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE \
  --filter '{
    "Dimensions": {
      "Key": "SERVICE",
      "Values": ["Amazon Simple Storage Service"]
    }
  }'

# Get S3 storage class analysis
aws s3api get-bucket-analytics-configuration \
  --bucket cloudops-bucket \
  --id analytics-config
```

## Best Practices

1. **Choose appropriate storage types** for workload requirements
2. **Implement lifecycle policies** for cost optimization
3. **Use encryption** for data at rest and in transit
4. **Monitor performance** metrics regularly
5. **Implement backup strategies** with cross-region replication
6. **Use DataSync** for large-scale migrations
7. **Optimize storage costs** with intelligent tiering

## Storage Migration Strategy

```bash
# Pre-migration assessment
aws datasync create-task \
  --source-location-arn arn:aws:datasync:us-east-1:123456789012:location/loc-source \
  --destination-location-arn arn:aws:datasync:us-east-1:123456789012:location/loc-dest \
  --name Assessment-Task \
  --options VerifyMode=ONLY_FILES_TRANSFERRED,OverwriteMode=NEVER

# Execute migration
aws datasync start-task-execution \
  --task-arn arn:aws:datasync:us-east-1:123456789012:task/task-xxxxxxxxx \
  --override-options VerifyMode=POINT_IN_TIME_CONSISTENT,OverwriteMode=ALWAYS
```

## Cleanup

```bash
# Delete DataSync task
aws datasync delete-task \
  --task-arn arn:aws:datasync:us-east-1:123456789012:task/task-xxxxxxxxx

# Delete Storage Gateway
aws storagegateway delete-gateway \
  --gateway-arn arn:aws:storagegateway:us-east-1:123456789012:gateway/sgw-xxxxxxxxx

# Delete FSx file system
aws fsx delete-file-system \
  --file-system-id fs-xxxxxxxxx

# Delete backup plan
aws backup delete-backup-plan \
  --backup-plan-id backup-plan-id
```