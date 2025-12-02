# AWS Certified CloudOps Engineer Associate SOA-C03 2025
## Complete Hands-on Practice Labs with CLI Commands and Terraform

---

## Table of Contents

1. [Introduction & Requirements - AWS Certified CloudOps Engineer Associate](#1-introduction--requirements)
2. [EC2 for CloudOps](#2-ec2-for-cloudops)
3. [AMI - Amazon Machine Image](#3-ami---amazon-machine-image)
4. [Managing EC2 at Scale - Systems Manager (SSM)](#4-managing-ec2-at-scale---systems-manager-ssm)
5. [EC2 High Availability and Scalability](#5-ec2-high-availability-and-scalability)
6. [CloudFormation for CloudOps](#6-cloudformation-for-cloudops)
7. [Lambda for CloudOps](#7-lambda-for-cloudops)
8. [EC2 Storage and Data Management - EBS and EFS](#8-ec2-storage-and-data-management---ebs-and-efs)
9. [Amazon S3 Introduction](#9-amazon-s3-introduction)
10. [Advanced Amazon S3 & Athena](#10-advanced-amazon-s3--athena)
11. [Amazon S3 Security](#11-amazon-s3-security)
12. [Advanced Storage Section](#12-advanced-storage-section)
13. [CloudFront](#13-cloudfront)
14. [Databases for CloudOps](#14-databases-for-cloudops)
15. [Monitoring, Auditing and Performance](#15-monitoring-auditing-and-performance)
16. [AWS Account Management](#16-aws-account-management)
17. [Disaster Recovery](#17-disaster-recovery)
18. [Security and Compliance](#18-security-and-compliance)
19. [Identity](#19-identity)
20. [Networking - Route 53](#20-networking---route-53)
21. [Networking - VPC](#21-networking---vpc)

---

## 1. Introduction & Requirements

### AWS Certified CloudOps Engineer Associate Overview

**Exam Details:**
- **Exam Code:** SOA-C03
- **Duration:** 130 minutes
- **Format:** Multiple choice and multiple response
- **Passing Score:** 720/1000
- **Cost:** $150 USD

**Prerequisites:**
```bash
# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install Terraform
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Configure AWS CLI
aws configure
```

**Terraform Setup:**
```hcl
# provider.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}
```

---

## 2. EC2 for CloudOps

### Lab 1: EC2 Instance Management

**CLI Commands:**
```bash
# Launch EC2 instance
aws ec2 run-instances \
  --image-id ami-0c02fb55956c7d316 \
  --instance-type t3.micro \
  --key-name my-key-pair \
  --security-group-ids sg-xxxxxxxxx \
  --subnet-id subnet-xxxxxxxxx \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=CloudOps-Instance}]'

# Start/Stop instances
aws ec2 start-instances --instance-ids i-xxxxxxxxx
aws ec2 stop-instances --instance-ids i-xxxxxxxxx

# Modify instance attributes
aws ec2 modify-instance-attribute \
  --instance-id i-xxxxxxxxx \
  --instance-type Value=t3.small
```

**Terraform:**
```hcl
# ec2.tf
resource "aws_instance" "cloudops_instance" {
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "t3.micro"
  key_name      = aws_key_pair.cloudops_key.key_name
  
  vpc_security_group_ids = [aws_security_group.cloudops_sg.id]
  subnet_id              = aws_subnet.public.id
  
  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y amazon-cloudwatch-agent
    EOF
  )
  
  tags = {
    Name = "CloudOps-Instance"
    Environment = "Lab"
  }
}

resource "aws_key_pair" "cloudops_key" {
  key_name   = "cloudops-key"
  public_key = file("~/.ssh/id_rsa.pub")
}
```

---

## 3. AMI - Amazon Machine Image

### Lab 2: Custom AMI Creation

**CLI Commands:**
```bash
# Create AMI from instance
aws ec2 create-image \
  --instance-id i-xxxxxxxxx \
  --name "CloudOps-Custom-AMI-$(date +%Y%m%d)" \
  --description "Custom AMI for CloudOps"

# Copy AMI to another region
aws ec2 copy-image \
  --source-region us-east-1 \
  --source-image-id ami-xxxxxxxxx \
  --name "CloudOps-Custom-AMI-Copy" \
  --region us-west-2

# Share AMI with another account
aws ec2 modify-image-attribute \
  --image-id ami-xxxxxxxxx \
  --launch-permission "Add=[{UserId=123456789012}]"
```

**Terraform:**
```hcl
# ami.tf
resource "aws_ami_from_instance" "cloudops_ami" {
  name               = "cloudops-custom-ami-${formatdate("YYYYMMDD", timestamp())}"
  source_instance_id = aws_instance.cloudops_instance.id
  
  tags = {
    Name = "CloudOps Custom AMI"
  }
}

resource "aws_ami_copy" "cloudops_ami_copy" {
  name              = "cloudops-ami-copy"
  source_ami_id     = aws_ami_from_instance.cloudops_ami.id
  source_ami_region = "us-east-1"
  
  tags = {
    Name = "CloudOps AMI Copy"
  }
}
```

---

## 4. Managing EC2 at Scale - Systems Manager (SSM)

### Lab 3: SSM Configuration

**CLI Commands:**
```bash
# Install SSM agent (if not pre-installed)
aws ssm send-command \
  --document-name "AWS-UpdateSSMAgent" \
  --targets "Key=tag:Environment,Values=Lab"

# Run commands on instances
aws ssm send-command \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=["yum update -y","systemctl status amazon-ssm-agent"]' \
  --targets "Key=tag:Environment,Values=Lab"

# Create maintenance window
aws ssm create-maintenance-window \
  --name "CloudOps-Maintenance" \
  --schedule "cron(0 2 ? * SUN *)" \
  --duration 4 \
  --cutoff 1 \
  --allow-unassociated-targets
```

**Terraform:**
```hcl
# ssm.tf
resource "aws_iam_role" "ssm_role" {
  name = "SSMRole"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "SSMInstanceProfile"
  role = aws_iam_role.ssm_role.name
}

resource "aws_ssm_maintenance_window" "cloudops_window" {
  name     = "CloudOps-Maintenance"
  schedule = "cron(0 2 ? * SUN *)"
  duration = 4
  cutoff   = 1
}
```

---

## 5. EC2 High Availability and Scalability

### Lab 4: Auto Scaling and Load Balancing

**CLI Commands:**
```bash
# Create launch template
aws ec2 create-launch-template \
  --launch-template-name cloudops-template \
  --launch-template-data '{
    "ImageId": "ami-0c02fb55956c7d316",
    "InstanceType": "t3.micro",
    "KeyName": "cloudops-key",
    "SecurityGroupIds": ["sg-xxxxxxxxx"],
    "UserData": "IyEvYmluL2Jhc2gKeXVtIHVwZGF0ZSAteQ=="
  }'

# Create Auto Scaling Group
aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name cloudops-asg \
  --launch-template LaunchTemplateName=cloudops-template,Version=1 \
  --min-size 2 \
  --max-size 6 \
  --desired-capacity 2 \
  --vpc-zone-identifier "subnet-xxxxxxxxx,subnet-yyyyyyyyy"

# Create Application Load Balancer
aws elbv2 create-load-balancer \
  --name cloudops-alb \
  --subnets subnet-xxxxxxxxx subnet-yyyyyyyyy \
  --security-groups sg-xxxxxxxxx
```

**Terraform:**
```hcl
# autoscaling.tf
resource "aws_launch_template" "cloudops_template" {
  name_prefix   = "cloudops-"
  image_id      = "ami-0c02fb55956c7d316"
  instance_type = "t3.micro"
  key_name      = aws_key_pair.cloudops_key.key_name
  
  vpc_security_group_ids = [aws_security_group.cloudops_sg.id]
  
  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>CloudOps Instance</h1>" > /var/www/html/index.html
    EOF
  )
}

resource "aws_autoscaling_group" "cloudops_asg" {
  name                = "cloudops-asg"
  vpc_zone_identifier = [aws_subnet.public.id, aws_subnet.public_2.id]
  min_size            = 2
  max_size            = 6
  desired_capacity    = 2
  
  launch_template {
    id      = aws_launch_template.cloudops_template.id
    version = "$Latest"
  }
  
  tag {
    key                 = "Name"
    value               = "CloudOps-ASG-Instance"
    propagate_at_launch = true
  }
}

resource "aws_lb" "cloudops_alb" {
  name               = "cloudops-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.cloudops_sg.id]
  subnets            = [aws_subnet.public.id, aws_subnet.public_2.id]
}
```

---

## 6. CloudFormation for CloudOps

### Lab 5: Infrastructure as Code

**CLI Commands:**
```bash
# Deploy CloudFormation stack
aws cloudformation create-stack \
  --stack-name cloudops-infrastructure \
  --template-body file://cloudops-template.yaml \
  --parameters ParameterKey=InstanceType,ParameterValue=t3.micro \
  --capabilities CAPABILITY_IAM

# Update stack
aws cloudformation update-stack \
  --stack-name cloudops-infrastructure \
  --template-body file://cloudops-template-updated.yaml

# Delete stack
aws cloudformation delete-stack \
  --stack-name cloudops-infrastructure
```

**CloudFormation Template:**
```yaml
# cloudops-template.yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: 'CloudOps Infrastructure'

Parameters:
  InstanceType:
    Type: String
    Default: t3.micro
    AllowedValues: [t3.micro, t3.small, t3.medium]

Resources:
  CloudOpsVPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: 10.0.0.0/16
      EnableDnsHostnames: true
      EnableDnsSupport: true
      Tags:
        - Key: Name
          Value: CloudOps-VPC

  PublicSubnet:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref CloudOpsVPC
      CidrBlock: 10.0.1.0/24
      AvailabilityZone: !Select [0, !GetAZs '']
      MapPublicIpOnLaunch: true

  CloudOpsInstance:
    Type: AWS::EC2::Instance
    Properties:
      ImageId: ami-0c02fb55956c7d316
      InstanceType: !Ref InstanceType
      SubnetId: !Ref PublicSubnet
      Tags:
        - Key: Name
          Value: CloudOps-CF-Instance

Outputs:
  InstanceId:
    Description: Instance ID
    Value: !Ref CloudOpsInstance
```

---

## 7. Lambda for CloudOps

### Lab 6: Serverless Operations

**CLI Commands:**
```bash
# Create Lambda function
aws lambda create-function \
  --function-name cloudops-automation \
  --runtime python3.9 \
  --role arn:aws:iam::ACCOUNT-ID:role/lambda-execution-role \
  --handler lambda_function.lambda_handler \
  --zip-file fileb://function.zip

# Invoke function
aws lambda invoke \
  --function-name cloudops-automation \
  --payload '{"key1":"value1"}' \
  response.json

# Update function code
aws lambda update-function-code \
  --function-name cloudops-automation \
  --zip-file fileb://updated-function.zip
```

**Lambda Function:**
```python
# lambda_function.py
import json
import boto3

def lambda_handler(event, context):
    ec2 = boto3.client('ec2')
    
    # Stop instances with specific tag
    response = ec2.describe_instances(
        Filters=[
            {'Name': 'tag:AutoStop', 'Values': ['true']},
            {'Name': 'instance-state-name', 'Values': ['running']}
        ]
    )
    
    instance_ids = []
    for reservation in response['Reservations']:
        for instance in reservation['Instances']:
            instance_ids.append(instance['InstanceId'])
    
    if instance_ids:
        ec2.stop_instances(InstanceIds=instance_ids)
        return {
            'statusCode': 200,
            'body': json.dumps(f'Stopped instances: {instance_ids}')
        }
    
    return {
        'statusCode': 200,
        'body': json.dumps('No instances to stop')
    }
```

**Terraform:**
```hcl
# lambda.tf
resource "aws_lambda_function" "cloudops_automation" {
  filename         = "function.zip"
  function_name    = "cloudops-automation"
  role            = aws_iam_role.lambda_role.arn
  handler         = "lambda_function.lambda_handler"
  runtime         = "python3.9"
  
  environment {
    variables = {
      ENVIRONMENT = "production"
    }
  }
}

resource "aws_cloudwatch_event_rule" "daily_stop" {
  name                = "daily-instance-stop"
  description         = "Stop instances daily"
  schedule_expression = "cron(0 18 * * ? *)"
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.daily_stop.name
  target_id = "TriggerLambda"
  arn       = aws_lambda_function.cloudops_automation.arn
}
```

---

## 8. EC2 Storage and Data Management - EBS and EFS

### Lab 7: Storage Management

**CLI Commands:**
```bash
# Create EBS volume
aws ec2 create-volume \
  --size 20 \
  --volume-type gp3 \
  --availability-zone us-east-1a \
  --tag-specifications 'ResourceType=volume,Tags=[{Key=Name,Value=CloudOps-Volume}]'

# Attach volume to instance
aws ec2 attach-volume \
  --volume-id vol-xxxxxxxxx \
  --instance-id i-xxxxxxxxx \
  --device /dev/sdf

# Create EFS file system
aws efs create-file-system \
  --creation-token cloudops-efs-$(date +%s) \
  --performance-mode generalPurpose \
  --throughput-mode provisioned \
  --provisioned-throughput-in-mibps 100
```

**Terraform:**
```hcl
# storage.tf
resource "aws_ebs_volume" "cloudops_volume" {
  availability_zone = "us-east-1a"
  size              = 20
  type              = "gp3"
  
  tags = {
    Name = "CloudOps-Volume"
  }
}

resource "aws_volume_attachment" "cloudops_attachment" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.cloudops_volume.id
  instance_id = aws_instance.cloudops_instance.id
}

resource "aws_efs_file_system" "cloudops_efs" {
  creation_token = "cloudops-efs"
  
  performance_mode = "generalPurpose"
  throughput_mode  = "provisioned"
  provisioned_throughput_in_mibps = 100
  
  tags = {
    Name = "CloudOps-EFS"
  }
}

resource "aws_efs_mount_target" "cloudops_mount" {
  file_system_id = aws_efs_file_system.cloudops_efs.id
  subnet_id      = aws_subnet.public.id
  security_groups = [aws_security_group.efs_sg.id]
}
```

---

## 9. Amazon S3 Introduction

### Lab 8: S3 Basic Operations

**CLI Commands:**
```bash
# Create S3 bucket
aws s3 mb s3://cloudops-bucket-$(date +%s)

# Upload files
aws s3 cp file.txt s3://cloudops-bucket-$(date +%s)/
aws s3 sync ./local-folder s3://cloudops-bucket-$(date +%s)/folder/

# Set bucket versioning
aws s3api put-bucket-versioning \
  --bucket cloudops-bucket-$(date +%s) \
  --versioning-configuration Status=Enabled

# Configure lifecycle policy
aws s3api put-bucket-lifecycle-configuration \
  --bucket cloudops-bucket-$(date +%s) \
  --lifecycle-configuration file://lifecycle.json
```

**Terraform:**
```hcl
# s3.tf
resource "aws_s3_bucket" "cloudops_bucket" {
  bucket = "cloudops-bucket-${random_string.bucket_suffix.result}"
}

resource "aws_s3_bucket_versioning" "cloudops_versioning" {
  bucket = aws_s3_bucket.cloudops_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudops_lifecycle" {
  bucket = aws_s3_bucket.cloudops_bucket.id
  
  rule {
    id     = "transition_to_ia"
    status = "Enabled"
    
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    
    transition {
      days          = 90
      storage_class = "GLACIER"
    }
  }
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}
```

---

## 10. Advanced Amazon S3 & Athena

### Lab 9: S3 Analytics and Querying

**CLI Commands:**
```bash
# Enable S3 analytics
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
            "Bucket": "arn:aws:s3:::analytics-bucket",
            "Prefix": "analytics/"
          }
        }
      }
    }
  }'

# Create Athena database
aws athena start-query-execution \
  --query-string "CREATE DATABASE cloudops_analytics" \
  --result-configuration OutputLocation=s3://athena-results-bucket/
```

**Terraform:**
```hcl
# athena.tf
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
    }
  }
}

resource "aws_s3_bucket" "athena_results" {
  bucket = "cloudops-athena-results-${random_string.bucket_suffix.result}"
}
```

---

## 11. Amazon S3 Security

### Lab 10: S3 Security Configuration

**CLI Commands:**
```bash
# Block public access
aws s3api put-public-access-block \
  --bucket cloudops-bucket \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

# Enable server-side encryption
aws s3api put-bucket-encryption \
  --bucket cloudops-bucket \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Set bucket policy
aws s3api put-bucket-policy \
  --bucket cloudops-bucket \
  --policy file://bucket-policy.json
```

**Bucket Policy:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyInsecureConnections",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::cloudops-bucket",
        "arn:aws:s3:::cloudops-bucket/*"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
```

**Terraform:**
```hcl
# s3-security.tf
resource "aws_s3_bucket_public_access_block" "cloudops_pab" {
  bucket = aws_s3_bucket.cloudops_bucket.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudops_encryption" {
  bucket = aws_s3_bucket.cloudops_bucket.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "cloudops_policy" {
  bucket = aws_s3_bucket.cloudops_bucket.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureConnections"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.cloudops_bucket.arn,
          "${aws_s3_bucket.cloudops_bucket.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}
```

---

## 12. Advanced Storage Section

### Lab 11: Storage Gateway and DataSync

**CLI Commands:**
```bash
# Create Storage Gateway
aws storagegateway create-gateway \
  --gateway-name CloudOps-Gateway \
  --gateway-timezone GMT \
  --gateway-region us-east-1 \
  --gateway-type FILE_S3

# Create DataSync task
aws datasync create-task \
  --source-location-arn arn:aws:datasync:us-east-1:account:location/loc-xxxxxxxxx \
  --destination-location-arn arn:aws:datasync:us-east-1:account:location/loc-yyyyyyyyy \
  --name CloudOps-DataSync-Task
```

**Terraform:**
```hcl
# datasync.tf
resource "aws_datasync_location_s3" "source" {
  s3_bucket_arn = aws_s3_bucket.source_bucket.arn
  subdirectory  = "/source"
  
  s3_config {
    bucket_access_role_arn = aws_iam_role.datasync_role.arn
  }
}

resource "aws_datasync_location_s3" "destination" {
  s3_bucket_arn = aws_s3_bucket.destination_bucket.arn
  subdirectory  = "/destination"
  
  s3_config {
    bucket_access_role_arn = aws_iam_role.datasync_role.arn
  }
}

resource "aws_datasync_task" "cloudops_sync" {
  destination_location_arn = aws_datasync_location_s3.destination.arn
  name                     = "CloudOps-DataSync-Task"
  source_location_arn      = aws_datasync_location_s3.source.arn
}
```

---

## 13. CloudFront

### Lab 12: Content Delivery Network

**CLI Commands:**
```bash
# Create CloudFront distribution
aws cloudfront create-distribution \
  --distribution-config file://distribution-config.json

# Invalidate cache
aws cloudfront create-invalidation \
  --distribution-id E1234567890123 \
  --invalidation-batch Paths="/*",CallerReference="$(date +%s)"
```

**Terraform:**
```hcl
# cloudfront.tf
resource "aws_cloudfront_distribution" "cloudops_distribution" {
  origin {
    domain_name = aws_s3_bucket.cloudops_bucket.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.cloudops_bucket.id}"
    
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }
  
  enabled             = true
  default_root_object = "index.html"
  
  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.cloudops_bucket.id}"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
    
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }
  
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "CloudOps OAI"
}
```

---

## 14. Databases for CloudOps

### Lab 13: RDS Management

**CLI Commands:**
```bash
# Create RDS instance
aws rds create-db-instance \
  --db-instance-identifier cloudops-db \
  --db-instance-class db.t3.micro \
  --engine mysql \
  --master-username admin \
  --master-user-password MySecurePassword123! \
  --allocated-storage 20 \
  --backup-retention-period 7

# Create read replica
aws rds create-db-instance-read-replica \
  --db-instance-identifier cloudops-db-replica \
  --source-db-instance-identifier cloudops-db

# Create snapshot
aws rds create-db-snapshot \
  --db-instance-identifier cloudops-db \
  --db-snapshot-identifier cloudops-db-snapshot-$(date +%Y%m%d)
```

**Terraform:**
```hcl
# rds.tf
resource "aws_db_instance" "cloudops_db" {
  identifier = "cloudops-db"
  
  engine         = "mysql"
  engine_version = "8.0"
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
  
  skip_final_snapshot = true
  
  tags = {
    Name = "CloudOps Database"
  }
}

resource "aws_db_subnet_group" "cloudops_subnet_group" {
  name       = "cloudops-subnet-group"
  subnet_ids = [aws_subnet.private.id, aws_subnet.private_2.id]
  
  tags = {
    Name = "CloudOps DB subnet group"
  }
}
```

---

## 15. Monitoring, Auditing and Performance

### Lab 14: CloudWatch and Performance Monitoring

**CLI Commands:**
```bash
# Create CloudWatch alarm
aws cloudwatch put-metric-alarm \
  --alarm-name "High-CPU-Usage" \
  --alarm-description "Alarm when CPU exceeds 80%" \
  --metric-name CPUUtilization \
  --namespace AWS/EC2 \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=InstanceId,Value=i-xxxxxxxxx \
  --evaluation-periods 2

# Create custom metric
aws cloudwatch put-metric-data \
  --namespace "CloudOps/Application" \
  --metric-data MetricName=CustomMetric,Value=100,Unit=Count

# Create log group
aws logs create-log-group \
  --log-group-name /cloudops/application
```

**Terraform:**
```hcl
# monitoring.tf
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "High-CPU-Usage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  
  dimensions = {
    InstanceId = aws_instance.cloudops_instance.id
  }
  
  alarm_actions = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_log_group" "cloudops_logs" {
  name              = "/cloudops/application"
  retention_in_days = 14
}

resource "aws_sns_topic" "alerts" {
  name = "cloudops-alerts"
}
```

---

## 16. AWS Account Management

### Lab 15: Organizations and Billing

**CLI Commands:**
```bash
# Create organization
aws organizations create-organization \
  --feature-set ALL

# Create organizational unit
aws organizations create-organizational-unit \
  --parent-id r-xxxxxxxxx \
  --name "Development"

# Create account
aws organizations create-account \
  --email dev-account@example.com \
  --account-name "Development Account"

# Set up billing alerts
aws cloudwatch put-metric-alarm \
  --alarm-name "Billing-Alert" \
  --alarm-description "Alert when billing exceeds $100" \
  --metric-name EstimatedCharges \
  --namespace AWS/Billing \
  --statistic Maximum \
  --period 86400 \
  --threshold 100 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=Currency,Value=USD
```

**Terraform:**
```hcl
# organizations.tf
resource "aws_organizations_organization" "cloudops_org" {
  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com"
  ]
  
  feature_set = "ALL"
}

resource "aws_organizations_organizational_unit" "development" {
  name      = "Development"
  parent_id = aws_organizations_organization.cloudops_org.roots[0].id
}

resource "aws_budgets_budget" "cloudops_budget" {
  name         = "CloudOps-Monthly-Budget"
  budget_type  = "COST"
  limit_amount = "100"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"
  
  cost_filters = {
    Service = ["Amazon Elastic Compute Cloud - Compute"]
  }
  
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 80
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_email_addresses = ["admin@example.com"]
  }
}
```

---

## 17. Disaster Recovery

### Lab 16: Multi-Region DR Setup

**CLI Commands:**
```bash
# Create cross-region backup
aws backup create-backup-plan \
  --backup-plan '{
    "BackupPlanName": "CloudOps-DR-Plan",
    "Rules": [{
      "RuleName": "DailyBackups",
      "TargetBackupVault": "default",
      "ScheduleExpression": "cron(0 5 ? * * *)",
      "Lifecycle": {
        "DeleteAfterDays": 30
      }
    }]
  }'

# Create Route 53 health check
aws route53 create-health-check \
  --caller-reference "health-check-$(date +%s)" \
  --health-check-config '{
    "Type": "HTTP",
    "ResourcePath": "/health",
    "FullyQualifiedDomainName": "example.com",
    "Port": 80
  }'
```

**Terraform:**
```hcl
# disaster-recovery.tf
resource "aws_backup_plan" "cloudops_backup" {
  name = "CloudOps-DR-Plan"
  
  rule {
    rule_name         = "DailyBackups"
    target_vault_name = aws_backup_vault.cloudops_vault.name
    schedule          = "cron(0 5 ? * * *)"
    
    lifecycle {
      delete_after = 30
    }
    
    recovery_point_tags = {
      Environment = "Production"
    }
  }
}

resource "aws_backup_vault" "cloudops_vault" {
  name        = "cloudops-backup-vault"
  kms_key_arn = aws_kms_key.backup_key.arn
}

resource "aws_route53_health_check" "primary" {
  fqdn                            = "example.com"
  port                            = 80
  type                            = "HTTP"
  resource_path                   = "/health"
  failure_threshold               = "5"
  request_interval                = "30"
  
  tags = {
    Name = "Primary Health Check"
  }
}
```

---

## 18. Security and Compliance

### Lab 17: Security Configuration

**CLI Commands:**
```bash
# Enable CloudTrail
aws cloudtrail create-trail \
  --name cloudops-trail \
  --s3-bucket-name cloudops-cloudtrail-bucket

# Enable Config
aws configservice put-configuration-recorder \
  --configuration-recorder name=cloudops-recorder,roleARN=arn:aws:iam::ACCOUNT:role/config-role

# Enable GuardDuty
aws guardduty create-detector \
  --enable \
  --finding-publishing-frequency FIFTEEN_MINUTES

# Create security group
aws ec2 create-security-group \
  --group-name cloudops-secure-sg \
  --description "Secure security group for CloudOps"
```

**Terraform:**
```hcl
# security.tf
resource "aws_cloudtrail" "cloudops_trail" {
  name           = "cloudops-trail"
  s3_bucket_name = aws_s3_bucket.cloudtrail_bucket.bucket
  
  event_selector {
    read_write_type                 = "All"
    include_management_events       = true
    
    data_resource {
      type   = "AWS::S3::Object"
      values = ["${aws_s3_bucket.cloudops_bucket.arn}/*"]
    }
  }
}

resource "aws_guardduty_detector" "cloudops_detector" {
  enable = true
  
  finding_publishing_frequency = "FIFTEEN_MINUTES"
  
  tags = {
    Name = "CloudOps GuardDuty"
  }
}

resource "aws_config_configuration_recorder" "cloudops_recorder" {
  name     = "cloudops-recorder"
  role_arn = aws_iam_role.config_role.arn
  
  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}
```

---

## 19. Identity

### Lab 18: IAM and Identity Management

**CLI Commands:**
```bash
# Create IAM user
aws iam create-user \
  --user-name cloudops-user

# Create IAM role
aws iam create-role \
  --role-name CloudOpsRole \
  --assume-role-policy-document file://trust-policy.json

# Attach policy to role
aws iam attach-role-policy \
  --role-name CloudOpsRole \
  --policy-arn arn:aws:iam::aws:policy/PowerUserAccess

# Create access key
aws iam create-access-key \
  --user-name cloudops-user
```

**Terraform:**
```hcl
# iam.tf
resource "aws_iam_user" "cloudops_user" {
  name = "cloudops-user"
  path = "/cloudops/"
}

resource "aws_iam_role" "cloudops_role" {
  name = "CloudOpsRole"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "cloudops_policy" {
  name        = "CloudOpsPolicy"
  description = "Policy for CloudOps operations"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:*",
          "s3:*",
          "cloudwatch:*"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloudops_attachment" {
  role       = aws_iam_role.cloudops_role.name
  policy_arn = aws_iam_policy.cloudops_policy.arn
}
```

---

## 20. Networking - Route 53

### Lab 19: DNS Management

**CLI Commands:**
```bash
# Create hosted zone
aws route53 create-hosted-zone \
  --name cloudops.example.com \
  --caller-reference "$(date +%s)"

# Create A record
aws route53 change-resource-record-sets \
  --hosted-zone-id Z123456789 \
  --change-batch '{
    "Changes": [{
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "www.cloudops.example.com",
        "Type": "A",
        "TTL": 300,
        "ResourceRecords": [{"Value": "1.2.3.4"}]
      }
    }]
  }'

# Create alias record
aws route53 change-resource-record-sets \
  --hosted-zone-id Z123456789 \
  --change-batch '{
    "Changes": [{
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "app.cloudops.example.com",
        "Type": "A",
        "AliasTarget": {
          "DNSName": "example-alb-123456789.us-east-1.elb.amazonaws.com",
          "EvaluateTargetHealth": true,
          "HostedZoneId": "Z35SXDOTRQ7X7K"
        }
      }
    }]
  }'
```

**Terraform:**
```hcl
# route53.tf
resource "aws_route53_zone" "cloudops_zone" {
  name = "cloudops.example.com"
  
  tags = {
    Name = "CloudOps Zone"
  }
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.cloudops_zone.zone_id
  name    = "www.cloudops.example.com"
  type    = "A"
  ttl     = 300
  records = ["1.2.3.4"]
}

resource "aws_route53_record" "app" {
  zone_id = aws_route53_zone.cloudops_zone.zone_id
  name    = "app.cloudops.example.com"
  type    = "A"
  
  alias {
    name                   = aws_lb.cloudops_alb.dns_name
    zone_id                = aws_lb.cloudops_alb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_health_check" "app_health" {
  fqdn                            = "app.cloudops.example.com"
  port                            = 80
  type                            = "HTTP"
  resource_path                   = "/health"
  failure_threshold               = "3"
  request_interval                = "30"
  
  tags = {
    Name = "App Health Check"
  }
}
```

---

## 21. Networking - VPC

### Lab 20: VPC Configuration

**CLI Commands:**
```bash
# Create VPC
aws ec2 create-vpc \
  --cidr-block 10.0.0.0/16 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=CloudOps-VPC}]'

# Create subnets
aws ec2 create-subnet \
  --vpc-id vpc-xxxxxxxxx \
  --cidr-block 10.0.1.0/24 \
  --availability-zone us-east-1a \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Public-Subnet-1a}]'

# Create internet gateway
aws ec2 create-internet-gateway \
  --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=CloudOps-IGW}]'

# Attach internet gateway
aws ec2 attach-internet-gateway \
  --internet-gateway-id igw-xxxxxxxxx \
  --vpc-id vpc-xxxxxxxxx

# Create NAT gateway
aws ec2 create-nat-gateway \
  --subnet-id subnet-xxxxxxxxx \
  --allocation-id eipalloc-xxxxxxxxx
```

**Terraform:**
```hcl
# vpc.tf
resource "aws_vpc" "cloudops_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "CloudOps-VPC"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.cloudops_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "Public-Subnet-1a"
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.cloudops_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"
  
  tags = {
    Name = "Private-Subnet-1a"
  }
}

resource "aws_internet_gateway" "cloudops_igw" {
  vpc_id = aws_vpc.cloudops_vpc.id
  
  tags = {
    Name = "CloudOps-IGW"
  }
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"
  
  tags = {
    Name = "CloudOps-NAT-EIP"
  }
}

resource "aws_nat_gateway" "cloudops_nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public.id
  
  tags = {
    Name = "CloudOps-NAT"
  }
  
  depends_on = [aws_internet_gateway.cloudops_igw]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.cloudops_vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cloudops_igw.id
  }
  
  tags = {
    Name = "Public-Route-Table"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.cloudops_vpc.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.cloudops_nat.id
  }
  
  tags = {
    Name = "Private-Route-Table"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}
```

---

## 🎯 Exam Preparation Tips

### Key Focus Areas:
1. **Monitoring and Logging** - CloudWatch, CloudTrail, Config
2. **High Availability** - Auto Scaling, Load Balancing, Multi-AZ
3. **Security** - IAM, Security Groups, Encryption
4. **Cost Optimization** - Right-sizing, Reserved Instances, Spot
5. **Automation** - CloudFormation, Systems Manager, Lambda

### Practice Commands:
```bash
# Quick environment setup
aws configure set region us-east-1
aws sts get-caller-identity

# Common troubleshooting
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name,Tags[?Key==`Name`].Value|[0]]'
aws logs describe-log-groups --query 'logGroups[*].logGroupName'
aws cloudwatch list-metrics --namespace AWS/EC2
```

### Terraform Best Practices:
```hcl
# variables.tf
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "cloudops"
}

# locals.tf
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

# Use locals in resources
resource "aws_instance" "example" {
  # ... other configuration
  tags = local.common_tags
}
```

---

## 🔧 Cleanup Scripts

### Complete Environment Cleanup:
```bash
#!/bin/bash
# cleanup.sh

echo "Starting CloudOps environment cleanup..."

# Delete Auto Scaling Groups
aws autoscaling delete-auto-scaling-group --auto-scaling-group-name cloudops-asg --force-delete

# Delete Load Balancers
aws elbv2 delete-load-balancer --load-balancer-arn $(aws elbv2 describe-load-balancers --names cloudops-alb --query 'LoadBalancers[0].LoadBalancerArn' --output text)

# Delete Lambda functions
aws lambda delete-function --function-name cloudops-automation

# Delete RDS instances
aws rds delete-db-instance --db-instance-identifier cloudops-db --skip-final-snapshot

# Delete S3 buckets
aws s3 rb s3://cloudops-bucket-* --force

# Delete CloudFormation stacks
aws cloudformation delete-stack --stack-name cloudops-infrastructure

echo "Cleanup completed!"
```

### Terraform Cleanup:
```bash
# Destroy all resources
terraform destroy -auto-approve

# Clean up state files
rm -rf .terraform/
rm terraform.tfstate*
```

---

## 📚 Additional Resources

- [AWS CLI Command Reference](https://docs.aws.amazon.com/cli/latest/reference/)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS CloudOps Best Practices](https://aws.amazon.com/architecture/well-architected/)
- [AWS Systems Manager User Guide](https://docs.aws.amazon.com/systems-manager/)

---

**🎉 Congratulations!** You've completed the AWS Certified CloudOps Engineer Associate SOA-C03 hands-on labs. Practice these scenarios regularly to master CloudOps skills and ace your certification exam!