# 19. Identity

## Lab 1: IAM Users and Groups

### Create IAM Users
```bash
# Create IAM user
aws iam create-user \
  --user-name cloudops-user \
  --path /cloudops/

# Create user with tags
aws iam create-user \
  --user-name developer-user \
  --path /developers/ \
  --tags Key=Department,Value=Engineering Key=Project,Value=CloudOps

# Set user password
aws iam create-login-profile \
  --user-name cloudops-user \
  --password MySecurePassword123! \
  --password-reset-required

# Create access key
aws iam create-access-key \
  --user-name cloudops-user

# List users
aws iam list-users --path-prefix /cloudops/
```

### Create IAM Groups
```bash
# Create group
aws iam create-group \
  --group-name CloudOpsAdmins \
  --path /cloudops/

# Add user to group
aws iam add-user-to-group \
  --group-name CloudOpsAdmins \
  --user-name cloudops-user

# List group members
aws iam get-group \
  --group-name CloudOpsAdmins
```

## Terraform IAM Configuration

```hcl
# iam.tf
resource "aws_iam_user" "cloudops_users" {
  for_each = toset(["alice", "bob", "charlie"])
  
  name = "cloudops-${each.key}"
  path = "/cloudops/"
  
  tags = {
    Department = "Engineering"
    Project    = "CloudOps"
  }
}

resource "aws_iam_group" "cloudops_admins" {
  name = "CloudOpsAdmins"
  path = "/cloudops/"
}

resource "aws_iam_group" "cloudops_developers" {
  name = "CloudOpsDevelopers"
  path = "/cloudops/"
}

resource "aws_iam_group_membership" "admins" {
  name = "cloudops-admins-membership"
  
  users = [
    aws_iam_user.cloudops_users["alice"].name,
    aws_iam_user.cloudops_users["bob"].name
  ]
  
  group = aws_iam_group.cloudops_admins.name
}

resource "aws_iam_group_membership" "developers" {
  name = "cloudops-developers-membership"
  
  users = [
    aws_iam_user.cloudops_users["charlie"].name
  ]
  
  group = aws_iam_group.cloudops_developers.name
}
```

## Lab 2: IAM Policies

### Create Custom Policies
```bash
# Create custom policy
cat > cloudops-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "ec2:StartInstances",
        "ec2:StopInstances",
        "ec2:RebootInstances"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "ec2:ResourceTag/Environment": ["Development", "Staging"]
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "cloudwatch:GetMetricStatistics",
        "cloudwatch:ListMetrics"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Deny",
      "Action": [
        "ec2:TerminateInstances"
      ],
      "Resource": "*"
    }
  ]
}
EOF

# Create policy
aws iam create-policy \
  --policy-name CloudOpsPolicy \
  --policy-document file://cloudops-policy.json \
  --description "CloudOps team permissions"

# Attach policy to group
aws iam attach-group-policy \
  --group-name CloudOpsAdmins \
  --policy-arn arn:aws:iam::123456789012:policy/CloudOpsPolicy
```

### Terraform Custom Policies
```hcl
# policies.tf
resource "aws_iam_policy" "cloudops_policy" {
  name        = "CloudOpsPolicy"
  description = "CloudOps team permissions"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:RebootInstances"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "ec2:ResourceTag/Environment" = ["Development", "Staging"]
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics"
        ]
        Resource = "*"
      },
      {
        Effect = "Deny"
        Action = [
          "ec2:TerminateInstances"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_group_policy_attachment" "cloudops_admins_policy" {
  group      = aws_iam_group.cloudops_admins.name
  policy_arn = aws_iam_policy.cloudops_policy.arn
}

resource "aws_iam_policy" "s3_access_policy" {
  name        = "CloudOpsS3Access"
  description = "S3 access for CloudOps team"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "arn:aws:s3:::cloudops-*/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = "arn:aws:s3:::cloudops-*"
      }
    ]
  })
}
```

## Lab 3: IAM Roles

### Create IAM Roles
```bash
# Create trust policy for EC2
cat > ec2-trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Create role
aws iam create-role \
  --role-name CloudOpsEC2Role \
  --assume-role-policy-document file://ec2-trust-policy.json \
  --description "Role for CloudOps EC2 instances"

# Attach managed policy
aws iam attach-role-policy \
  --role-name CloudOpsEC2Role \
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore

# Create instance profile
aws iam create-instance-profile \
  --instance-profile-name CloudOpsEC2Profile

# Add role to instance profile
aws iam add-role-to-instance-profile \
  --instance-profile-name CloudOpsEC2Profile \
  --role-name CloudOpsEC2Role
```

### Cross-Account Role
```bash
# Create cross-account trust policy
cat > cross-account-trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::987654321098:root"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "unique-external-id"
        }
      }
    }
  ]
}
EOF

# Create cross-account role
aws iam create-role \
  --role-name CrossAccountCloudOpsRole \
  --assume-role-policy-document file://cross-account-trust-policy.json
```

### Terraform Roles Configuration
```hcl
# roles.tf
resource "aws_iam_role" "cloudops_ec2_role" {
  name = "CloudOpsEC2Role"
  
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
  
  tags = {
    Name = "CloudOps EC2 Role"
  }
}

resource "aws_iam_role_policy_attachment" "cloudops_ec2_ssm" {
  role       = aws_iam_role.cloudops_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "cloudops_ec2_profile" {
  name = "CloudOpsEC2Profile"
  role = aws_iam_role.cloudops_ec2_role.name
}

resource "aws_iam_role" "lambda_execution_role" {
  name = "CloudOpsLambdaRole"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "CloudOpsLambdaPolicy"
  role = aws_iam_role.lambda_execution_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:StartInstances",
          "ec2:StopInstances"
        ]
        Resource = "*"
      }
    ]
  })
}
```

## Lab 4: MFA and Security

### Enable MFA
```bash
# Create virtual MFA device
aws iam create-virtual-mfa-device \
  --virtual-mfa-device-name cloudops-user-mfa \
  --outfile QRCode.png \
  --bootstrap-method QRCodePNG

# Enable MFA device (after scanning QR code)
aws iam enable-mfa-device \
  --user-name cloudops-user \
  --serial-number arn:aws:iam::123456789012:mfa/cloudops-user-mfa \
  --authentication-code1 123456 \
  --authentication-code2 789012

# Create policy requiring MFA
cat > mfa-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "*",
      "Resource": "*",
      "Condition": {
        "Bool": {
          "aws:MultiFactorAuthPresent": "true"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "iam:GetUser",
        "iam:ListMFADevices",
        "iam:GetMFADevice"
      ],
      "Resource": "*"
    }
  ]
}
EOF

aws iam create-policy \
  --policy-name RequireMFAPolicy \
  --policy-document file://mfa-policy.json
```

### Password Policy
```bash
# Set account password policy
aws iam update-account-password-policy \
  --minimum-password-length 12 \
  --require-symbols \
  --require-numbers \
  --require-uppercase-characters \
  --require-lowercase-characters \
  --allow-users-to-change-password \
  --max-password-age 90 \
  --password-reuse-prevention 5

# Get password policy
aws iam get-account-password-policy
```

### Terraform Security Configuration
```hcl
# security.tf
resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length        = 12
  require_lowercase_characters   = true
  require_numbers               = true
  require_uppercase_characters   = true
  require_symbols               = true
  allow_users_to_change_password = true
  max_password_age              = 90
  password_reuse_prevention     = 5
}

resource "aws_iam_policy" "require_mfa" {
  name        = "RequireMFAPolicy"
  description = "Policy requiring MFA for all actions"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "*"
        Resource = "*"
        Condition = {
          Bool = {
            "aws:MultiFactorAuthPresent" = "true"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "iam:GetUser",
          "iam:ListMFADevices",
          "iam:GetMFADevice",
          "iam:CreateVirtualMFADevice",
          "iam:EnableMFADevice"
        ]
        Resource = "*"
      }
    ]
  })
}
```

## Lab 5: Service-Linked Roles

### Create Service-Linked Roles
```bash
# Create service-linked role for Auto Scaling
aws iam create-service-linked-role \
  --aws-service-name autoscaling.amazonaws.com

# Create service-linked role for ELB
aws iam create-service-linked-role \
  --aws-service-name elasticloadbalancing.amazonaws.com

# List service-linked roles
aws iam list-roles \
  --path-prefix /aws-service-role/
```

### Terraform Service-Linked Roles
```hcl
# service-linked-roles.tf
resource "aws_iam_service_linked_role" "autoscaling" {
  aws_service_name = "autoscaling.amazonaws.com"
  description      = "Service-linked role for Auto Scaling"
}

resource "aws_iam_service_linked_role" "elasticloadbalancing" {
  aws_service_name = "elasticloadbalancing.amazonaws.com"
  description      = "Service-linked role for Elastic Load Balancing"
}
```

## Lab 6: IAM Access Analyzer

### Enable Access Analyzer
```bash
# Create access analyzer
aws accessanalyzer create-analyzer \
  --analyzer-name cloudops-analyzer \
  --type ACCOUNT \
  --tags Key=Environment,Value=Production

# List findings
aws accessanalyzer list-findings \
  --analyzer-arn arn:aws:access-analyzer:us-east-1:123456789012:analyzer/cloudops-analyzer

# Get finding details
aws accessanalyzer get-finding \
  --analyzer-arn arn:aws:access-analyzer:us-east-1:123456789012:analyzer/cloudops-analyzer \
  --id finding-id-here
```

### Terraform Access Analyzer
```hcl
# access-analyzer.tf
resource "aws_accessanalyzer_analyzer" "cloudops_analyzer" {
  analyzer_name = "cloudops-analyzer"
  type         = "ACCOUNT"
  
  tags = {
    Environment = "Production"
  }
}
```

## Lab 7: IAM Credential Reports

### Generate Credential Report
```bash
# Generate credential report
aws iam generate-credential-report

# Get credential report
aws iam get-credential-report \
  --output text \
  --query 'Content' | base64 --decode > credential-report.csv

# View report
cat credential-report.csv
```

### Automated Credential Monitoring
```python
# credential-monitor.py
import boto3
import csv
import io
from datetime import datetime, timedelta

def lambda_handler(event, context):
    iam = boto3.client('iam')
    sns = boto3.client('sns')
    
    # Generate credential report
    iam.generate_credential_report()
    
    # Wait for report generation
    import time
    time.sleep(10)
    
    # Get credential report
    response = iam.get_credential_report()
    report_content = response['Content'].decode('utf-8')
    
    # Parse CSV
    csv_reader = csv.DictReader(io.StringIO(report_content))
    
    alerts = []
    for row in csv_reader:
        user = row['user']
        
        # Check for old access keys
        if row['access_key_1_last_used_date'] != 'N/A':
            last_used = datetime.strptime(row['access_key_1_last_used_date'], '%Y-%m-%dT%H:%M:%S+00:00')
            if (datetime.now() - last_used).days > 90:
                alerts.append(f"User {user} has unused access key (90+ days)")
        
        # Check for users without MFA
        if row['mfa_active'] == 'false' and row['password_enabled'] == 'true':
            alerts.append(f"User {user} does not have MFA enabled")
    
    # Send alerts
    if alerts:
        message = '\n'.join(alerts)
        sns.publish(
            TopicArn='arn:aws:sns:us-east-1:123456789012:iam-alerts',
            Message=message,
            Subject='IAM Security Alert'
        )
    
    return {
        'statusCode': 200,
        'body': f'Found {len(alerts)} security issues'
    }
```

## Best Practices

1. **Follow principle of least privilege**
2. **Use roles instead of users** for applications
3. **Enable MFA** for all users
4. **Rotate access keys** regularly
5. **Use strong password policies**
6. **Monitor IAM activity** with CloudTrail
7. **Regular access reviews** and cleanup

## Monitoring IAM

```bash
# List access keys
aws iam list-access-keys --user-name cloudops-user

# Get last activity for access key
aws iam get-access-key-last-used --access-key-id AKIAIOSFODNN7EXAMPLE

# List attached policies
aws iam list-attached-user-policies --user-name cloudops-user
aws iam list-attached-group-policies --group-name CloudOpsAdmins
aws iam list-attached-role-policies --role-name CloudOpsEC2Role
```

## Cleanup

```bash
# Remove user from group
aws iam remove-user-from-group \
  --group-name CloudOpsAdmins \
  --user-name cloudops-user

# Delete access key
aws iam delete-access-key \
  --user-name cloudops-user \
  --access-key-id AKIAIOSFODNN7EXAMPLE

# Delete user
aws iam delete-user --user-name cloudops-user

# Delete group
aws iam delete-group --group-name CloudOpsAdmins

# Delete role
aws iam delete-role --role-name CloudOpsEC2Role
```