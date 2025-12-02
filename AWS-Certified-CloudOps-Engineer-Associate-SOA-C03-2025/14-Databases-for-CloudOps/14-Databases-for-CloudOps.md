# 14. Databases for CloudOps

## Lab 1: RDS Instance Management

### Create RDS Instance
```bash
# Create DB subnet group
aws rds create-db-subnet-group \
  --db-subnet-group-name cloudops-db-subnet-group \
  --db-subnet-group-description "CloudOps DB Subnet Group" \
  --subnet-ids subnet-xxxxxxxxx subnet-yyyyyyyyy

# Create RDS instance
aws rds create-db-instance \
  --db-instance-identifier cloudops-db \
  --db-instance-class db.t3.micro \
  --engine mysql \
  --engine-version 8.0.35 \
  --master-username admin \
  --master-user-password MySecurePassword123! \
  --allocated-storage 20 \
  --db-subnet-group-name cloudops-db-subnet-group \
  --vpc-security-group-ids sg-xxxxxxxxx \
  --backup-retention-period 7 \
  --preferred-backup-window "03:00-04:00" \
  --preferred-maintenance-window "sun:04:00-sun:05:00" \
  --multi-az \
  --storage-encrypted

# Check instance status
aws rds describe-db-instances \
  --db-instance-identifier cloudops-db \
  --query 'DBInstances[0].DBInstanceStatus'
```

### Modify RDS Instance
```bash
# Modify instance class
aws rds modify-db-instance \
  --db-instance-identifier cloudops-db \
  --db-instance-class db.t3.small \
  --apply-immediately

# Enable automated backups
aws rds modify-db-instance \
  --db-instance-identifier cloudops-db \
  --backup-retention-period 14 \
  --apply-immediately

# Enable performance insights
aws rds modify-db-instance \
  --db-instance-identifier cloudops-db \
  --enable-performance-insights \
  --performance-insights-retention-period 7
```

## Terraform RDS Configuration

```hcl
# rds.tf
resource "aws_db_subnet_group" "cloudops_subnet_group" {
  name       = "cloudops-db-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  
  tags = {
    Name = "CloudOps DB subnet group"
  }
}

resource "aws_db_instance" "cloudops_db" {
  identifier = "cloudops-db"
  
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
  db_subnet_group_name   = aws_db_subnet_group.cloudops_subnet_group.name
  
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  multi_az               = true
  publicly_accessible    = false
  
  performance_insights_enabled = true
  performance_insights_retention_period = 7
  
  skip_final_snapshot       = false
  final_snapshot_identifier = "cloudops-db-final-snapshot"
  
  tags = {
    Name = "CloudOps Database"
  }
}

resource "aws_security_group" "rds_sg" {
  name_prefix = "rds-sg"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "RDS Security Group"
  }
}
```

## Lab 2: RDS Read Replicas

### Create Read Replica
```bash
# Create read replica
aws rds create-db-instance-read-replica \
  --db-instance-identifier cloudops-db-replica \
  --source-db-instance-identifier cloudops-db \
  --db-instance-class db.t3.micro

# Create cross-region read replica
aws rds create-db-instance-read-replica \
  --db-instance-identifier cloudops-db-replica-west \
  --source-db-instance-identifier arn:aws:rds:us-east-1:123456789012:db:cloudops-db \
  --db-instance-class db.t3.micro \
  --region us-west-2

# Promote read replica
aws rds promote-read-replica \
  --db-instance-identifier cloudops-db-replica \
  --backup-retention-period 7
```

### Terraform Read Replica
```hcl
# read-replica.tf
resource "aws_db_instance" "cloudops_replica" {
  identifier = "cloudops-db-replica"
  
  replicate_source_db = aws_db_instance.cloudops_db.identifier
  instance_class      = "db.t3.micro"
  
  publicly_accessible = false
  
  tags = {
    Name = "CloudOps Database Replica"
  }
}

resource "aws_db_instance" "cloudops_cross_region_replica" {
  provider = aws.west
  
  identifier = "cloudops-db-replica-west"
  
  replicate_source_db = aws_db_instance.cloudops_db.arn
  instance_class      = "db.t3.micro"
  
  skip_final_snapshot = true
  
  tags = {
    Name = "CloudOps Cross-Region Replica"
  }
}
```

## Lab 3: RDS Snapshots and Backups

### Manual Snapshots
```bash
# Create manual snapshot
aws rds create-db-snapshot \
  --db-instance-identifier cloudops-db \
  --db-snapshot-identifier cloudops-db-snapshot-$(date +%Y%m%d)

# List snapshots
aws rds describe-db-snapshots \
  --db-instance-identifier cloudops-db

# Restore from snapshot
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier cloudops-db-restored \
  --db-snapshot-identifier cloudops-db-snapshot-20240101 \
  --db-instance-class db.t3.micro

# Copy snapshot to another region
aws rds copy-db-snapshot \
  --source-db-snapshot-identifier arn:aws:rds:us-east-1:123456789012:snapshot:cloudops-db-snapshot-20240101 \
  --target-db-snapshot-identifier cloudops-db-snapshot-copy \
  --region us-west-2

# Share snapshot with another account
aws rds modify-db-snapshot-attribute \
  --db-snapshot-identifier cloudops-db-snapshot-20240101 \
  --attribute-name restore \
  --values-to-add 123456789012
```

### Terraform Snapshot Management
```hcl
# snapshots.tf
resource "aws_db_snapshot" "cloudops_snapshot" {
  db_instance_identifier = aws_db_instance.cloudops_db.id
  db_snapshot_identifier = "cloudops-db-snapshot-${formatdate("YYYYMMDD", timestamp())}"
  
  tags = {
    Name = "CloudOps Manual Snapshot"
  }
}

resource "aws_db_instance" "cloudops_restored" {
  identifier = "cloudops-db-restored"
  
  snapshot_identifier = aws_db_snapshot.cloudops_snapshot.id
  instance_class      = "db.t3.micro"
  
  skip_final_snapshot = true
  
  tags = {
    Name = "CloudOps Restored Database"
  }
}
```

## Lab 4: RDS Parameter Groups

### Create Custom Parameter Group
```bash
# Create parameter group
aws rds create-db-parameter-group \
  --db-parameter-group-name cloudops-mysql-params \
  --db-parameter-group-family mysql8.0 \
  --description "CloudOps MySQL parameter group"

# Modify parameters
aws rds modify-db-parameter-group \
  --db-parameter-group-name cloudops-mysql-params \
  --parameters "ParameterName=max_connections,ParameterValue=200,ApplyMethod=immediate" \
               "ParameterName=innodb_buffer_pool_size,ParameterValue={DBInstanceClassMemory*3/4},ApplyMethod=pending-reboot"

# Apply parameter group to instance
aws rds modify-db-instance \
  --db-instance-identifier cloudops-db \
  --db-parameter-group-name cloudops-mysql-params \
  --apply-immediately
```

### Terraform Parameter Groups
```hcl
# parameter-groups.tf
resource "aws_db_parameter_group" "cloudops_params" {
  family = "mysql8.0"
  name   = "cloudops-mysql-params"
  
  parameter {
    name  = "max_connections"
    value = "200"
  }
  
  parameter {
    name  = "innodb_buffer_pool_size"
    value = "{DBInstanceClassMemory*3/4}"
  }
  
  parameter {
    name  = "slow_query_log"
    value = "1"
  }
  
  tags = {
    Name = "CloudOps MySQL Parameters"
  }
}

resource "aws_db_instance" "cloudops_db_with_params" {
  identifier = "cloudops-db-custom"
  
  engine         = "mysql"
  engine_version = "8.0.35"
  instance_class = "db.t3.micro"
  
  parameter_group_name = aws_db_parameter_group.cloudops_params.name
  
  # ... other configuration
}
```

## Lab 5: DynamoDB Operations

### Create DynamoDB Table
```bash
# Create table
aws dynamodb create-table \
  --table-name CloudOpsData \
  --attribute-definitions \
    AttributeName=id,AttributeType=S \
    AttributeName=timestamp,AttributeType=N \
  --key-schema \
    AttributeName=id,KeyType=HASH \
    AttributeName=timestamp,KeyType=RANGE \
  --billing-mode PAY_PER_REQUEST \
  --tags Key=Environment,Value=Lab

# Put item
aws dynamodb put-item \
  --table-name CloudOpsData \
  --item '{
    "id": {"S": "user123"},
    "timestamp": {"N": "1640995200"},
    "data": {"S": "Sample data"},
    "status": {"S": "active"}
  }'

# Get item
aws dynamodb get-item \
  --table-name CloudOpsData \
  --key '{
    "id": {"S": "user123"},
    "timestamp": {"N": "1640995200"}
  }'

# Query items
aws dynamodb query \
  --table-name CloudOpsData \
  --key-condition-expression "id = :id" \
  --expression-attribute-values '{
    ":id": {"S": "user123"}
  }'
```

### Terraform DynamoDB Configuration
```hcl
# dynamodb.tf
resource "aws_dynamodb_table" "cloudops_data" {
  name           = "CloudOpsData"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"
  range_key      = "timestamp"
  
  attribute {
    name = "id"
    type = "S"
  }
  
  attribute {
    name = "timestamp"
    type = "N"
  }
  
  attribute {
    name = "status"
    type = "S"
  }
  
  global_secondary_index {
    name     = "StatusIndex"
    hash_key = "status"
    
    projection_type = "ALL"
  }
  
  point_in_time_recovery {
    enabled = true
  }
  
  server_side_encryption {
    enabled = true
  }
  
  tags = {
    Name = "CloudOps Data Table"
  }
}

resource "aws_dynamodb_table_item" "sample_item" {
  table_name = aws_dynamodb_table.cloudops_data.name
  hash_key   = aws_dynamodb_table.cloudops_data.hash_key
  range_key  = aws_dynamodb_table.cloudops_data.range_key
  
  item = jsonencode({
    id = {
      S = "user123"
    }
    timestamp = {
      N = "1640995200"
    }
    data = {
      S = "Sample data"
    }
    status = {
      S = "active"
    }
  })
}
```

## Lab 6: Database Monitoring

### RDS Enhanced Monitoring
```bash
# Enable enhanced monitoring
aws rds modify-db-instance \
  --db-instance-identifier cloudops-db \
  --monitoring-interval 60 \
  --monitoring-role-arn arn:aws:iam::123456789012:role/rds-monitoring-role

# Create CloudWatch alarm for CPU
aws cloudwatch put-metric-alarm \
  --alarm-name "RDS-High-CPU" \
  --alarm-description "RDS CPU utilization high" \
  --metric-name CPUUtilization \
  --namespace AWS/RDS \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=DBInstanceIdentifier,Value=cloudops-db \
  --evaluation-periods 2

# Create alarm for database connections
aws cloudwatch put-metric-alarm \
  --alarm-name "RDS-High-Connections" \
  --alarm-description "RDS connection count high" \
  --metric-name DatabaseConnections \
  --namespace AWS/RDS \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=DBInstanceIdentifier,Value=cloudops-db \
  --evaluation-periods 2
```

### Terraform Database Monitoring
```hcl
# db-monitoring.tf
resource "aws_iam_role" "rds_monitoring" {
  name = "rds-monitoring-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "RDS-High-CPU"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "RDS CPU utilization high"
  
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.cloudops_db.id
  }
  
  alarm_actions = [aws_sns_topic.db_alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "rds_connections" {
  alarm_name          = "RDS-High-Connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "RDS connection count high"
  
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.cloudops_db.id
  }
  
  alarm_actions = [aws_sns_topic.db_alerts.arn]
}

resource "aws_sns_topic" "db_alerts" {
  name = "database-alerts"
}
```

## Lab 7: Database Security

### RDS Security Configuration
```bash
# Create option group for SSL
aws rds create-option-group \
  --option-group-name cloudops-mysql-ssl \
  --engine-name mysql \
  --major-engine-version 8.0 \
  --option-group-description "SSL options for MySQL"

# Force SSL connections
aws rds modify-db-parameter-group \
  --db-parameter-group-name cloudops-mysql-params \
  --parameters "ParameterName=require_secure_transport,ParameterValue=ON,ApplyMethod=immediate"

# Enable encryption at rest
aws rds modify-db-instance \
  --db-instance-identifier cloudops-db \
  --storage-encrypted \
  --kms-key-id arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012
```

### Terraform Database Security
```hcl
# db-security.tf
resource "aws_kms_key" "rds_key" {
  description = "KMS key for RDS encryption"
  
  tags = {
    Name = "RDS Encryption Key"
  }
}

resource "aws_db_option_group" "ssl_options" {
  name                     = "cloudops-mysql-ssl"
  option_group_description = "SSL options for MySQL"
  engine_name              = "mysql"
  major_engine_version     = "8.0"
  
  tags = {
    Name = "CloudOps SSL Options"
  }
}

resource "aws_db_instance" "secure_db" {
  identifier = "cloudops-secure-db"
  
  engine         = "mysql"
  engine_version = "8.0.35"
  instance_class = "db.t3.micro"
  
  storage_encrypted = true
  kms_key_id       = aws_kms_key.rds_key.arn
  
  option_group_name    = aws_db_option_group.ssl_options.name
  parameter_group_name = aws_db_parameter_group.secure_params.name
  
  # ... other configuration
}

resource "aws_db_parameter_group" "secure_params" {
  family = "mysql8.0"
  name   = "cloudops-secure-params"
  
  parameter {
    name  = "require_secure_transport"
    value = "ON"
  }
  
  parameter {
    name  = "log_bin_trust_function_creators"
    value = "1"
  }
}
```

## Best Practices

1. **Use Multi-AZ** for high availability
2. **Enable automated backups** with appropriate retention
3. **Create read replicas** for read scaling
4. **Use parameter groups** for configuration management
5. **Enable encryption** at rest and in transit
6. **Monitor performance** metrics regularly
7. **Implement proper security groups**

## Troubleshooting

```bash
# Check RDS logs
aws rds describe-db-log-files \
  --db-instance-identifier cloudops-db

# Download log file
aws rds download-db-log-file-portion \
  --db-instance-identifier cloudops-db \
  --log-file-name error/mysql-error.log

# Check parameter group status
aws rds describe-db-instances \
  --db-instance-identifier cloudops-db \
  --query 'DBInstances[0].DBParameterGroups'
```

## Cleanup

```bash
# Delete read replica
aws rds delete-db-instance \
  --db-instance-identifier cloudops-db-replica \
  --skip-final-snapshot

# Delete main instance
aws rds delete-db-instance \
  --db-instance-identifier cloudops-db \
  --final-db-snapshot-identifier cloudops-db-final-snapshot

# Delete DynamoDB table
aws dynamodb delete-table \
  --table-name CloudOpsData
```