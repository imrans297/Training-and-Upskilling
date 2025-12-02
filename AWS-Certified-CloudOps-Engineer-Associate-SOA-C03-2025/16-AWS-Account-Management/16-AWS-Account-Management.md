# 16. AWS Account Management

## Lab 1: AWS Organizations

### Create Organization
```bash
# Create organization
aws organizations create-organization \
  --feature-set ALL

# Get organization details
aws organizations describe-organization

# List accounts in organization
aws organizations list-accounts

# Create organizational unit
aws organizations create-organizational-unit \
  --parent-id r-xxxxxxxxx \
  --name "Development" \
  --tags Key=Environment,Value=Dev Key=CostCenter,Value=Engineering
```

### Create Member Accounts
```bash
# Create new account
aws organizations create-account \
  --email dev-account@cloudops.example.com \
  --account-name "CloudOps Development Account" \
  --role-name OrganizationAccountAccessRole \
  --iam-user-access-to-billing ALLOW

# Invite existing account
aws organizations invite-account-to-organization \
  --target Id=123456789012,Type=ACCOUNT \
  --notes "Invitation to join CloudOps organization"

# Move account to OU
aws organizations move-account \
  --account-id 123456789012 \
  --source-parent-id r-xxxxxxxxx \
  --destination-parent-id ou-xxxxxxxxx
```

### Service Control Policies (SCPs)
```bash
# Create SCP to deny certain actions
cat > deny-high-cost-services.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Action": [
        "ec2:RunInstances"
      ],
      "Resource": "*",
      "Condition": {
        "ForAnyValue:StringNotEquals": {
          "ec2:InstanceType": [
            "t3.micro",
            "t3.small",
            "t3.medium"
          ]
        }
      }
    },
    {
      "Effect": "Deny",
      "Action": [
        "rds:CreateDBInstance"
      ],
      "Resource": "*",
      "Condition": {
        "ForAnyValue:StringNotEquals": {
          "rds:db-instance-class": [
            "db.t3.micro",
            "db.t3.small"
          ]
        }
      }
    }
  ]
}
EOF

# Create SCP
aws organizations create-policy \
  --name "DenyHighCostServices" \
  --description "Prevent creation of expensive resources" \
  --type SERVICE_CONTROL_POLICY \
  --content file://deny-high-cost-services.json

# Attach SCP to OU
aws organizations attach-policy \
  --policy-id p-xxxxxxxxx \
  --target-id ou-xxxxxxxxx
```

## Terraform Organizations Configuration

```hcl
# organizations.tf
resource "aws_organizations_organization" "main" {
  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "guardduty.amazonaws.com",
    "securityhub.amazonaws.com",
    "sso.amazonaws.com"
  ]
  
  feature_set = "ALL"
  
  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY",
    "TAG_POLICY",
    "BACKUP_POLICY"
  ]
}

resource "aws_organizations_organizational_unit" "development" {
  name      = "Development"
  parent_id = aws_organizations_organization.main.roots[0].id
  
  tags = {
    Environment = "Dev"
    CostCenter  = "Engineering"
  }
}

resource "aws_organizations_organizational_unit" "production" {
  name      = "Production"
  parent_id = aws_organizations_organization.main.roots[0].id
  
  tags = {
    Environment = "Prod"
    CostCenter  = "Operations"
  }
}

resource "aws_organizations_account" "dev_account" {
  name      = "CloudOps Development Account"
  email     = "dev-account@cloudops.example.com"
  parent_id = aws_organizations_organizational_unit.development.id
  
  role_name               = "OrganizationAccountAccessRole"
  iam_user_access_to_billing = "ALLOW"
  
  tags = {
    Environment = "Development"
  }
}

resource "aws_organizations_policy" "deny_high_cost" {
  name        = "DenyHighCostServices"
  description = "Prevent creation of expensive resources"
  type        = "SERVICE_CONTROL_POLICY"
  
  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Deny"
        Action = [
          "ec2:RunInstances"
        ]
        Resource = "*"
        Condition = {
          ForAnyValue:StringNotEquals = {
            "ec2:InstanceType" = [
              "t3.micro",
              "t3.small",
              "t3.medium"
            ]
          }
        }
      }
    ]
  })
}

resource "aws_organizations_policy_attachment" "dev_scp" {
  policy_id = aws_organizations_policy.deny_high_cost.id
  target_id = aws_organizations_organizational_unit.development.id
}
```

## Lab 2: AWS Control Tower

### Set Up Control Tower
```bash
# Control Tower is primarily managed through the console
# But we can check the status and manage guardrails via CLI

# List enabled guardrails
aws controltower list-enabled-controls \
  --target-identifier arn:aws:organizations::123456789012:ou/o-xxxxxxxxx/ou-xxxxxxxxx

# Enable a guardrail
aws controltower enable-control \
  --control-identifier arn:aws:controltower:us-east-1::control/AWS-GR_ENCRYPTED_VOLUMES \
  --target-identifier arn:aws:organizations::123456789012:ou/o-xxxxxxxxx/ou-xxxxxxxxx

# Get control operation status
aws controltower get-control-operation \
  --operation-identifier operation-id
```

### Terraform Control Tower Configuration
```hcl
# control-tower.tf
resource "aws_controltower_control" "encrypted_volumes" {
  control_identifier = "arn:aws:controltower:us-east-1::control/AWS-GR_ENCRYPTED_VOLUMES"
  target_identifier  = aws_organizations_organizational_unit.production.arn
}

resource "aws_controltower_control" "mfa_enabled" {
  control_identifier = "arn:aws:controltower:us-east-1::control/AWS-GR_MFA_ENABLED_FOR_IAM_CONSOLE_ACCESS"
  target_identifier  = aws_organizations_organizational_unit.production.arn
}

resource "aws_controltower_control" "root_access_key" {
  control_identifier = "arn:aws:controltower:us-east-1::control/AWS-GR_ROOT_ACCESS_KEY_CHECK"
  target_identifier  = aws_organizations_organization.main.roots[0].arn
}
```

## Lab 3: AWS Single Sign-On (SSO)

### Configure SSO
```bash
# Enable SSO (typically done through console first)
# Then manage permission sets and assignments

# Create permission set
aws sso-admin create-permission-set \
  --instance-arn arn:aws:sso:::instance/ssoins-xxxxxxxxx \
  --name "CloudOpsAdminAccess" \
  --description "Full administrative access for CloudOps team" \
  --session-duration PT8H

# Attach managed policy to permission set
aws sso-admin attach-managed-policy-to-permission-set \
  --instance-arn arn:aws:sso:::instance/ssoins-xxxxxxxxx \
  --permission-set-arn arn:aws:sso:::permissionSet/ssoins-xxxxxxxxx/ps-xxxxxxxxx \
  --managed-policy-arn arn:aws:iam::aws:policy/AdministratorAccess

# Create account assignment
aws sso-admin create-account-assignment \
  --instance-arn arn:aws:sso:::instance/ssoins-xxxxxxxxx \
  --target-id 123456789012 \
  --target-type AWS_ACCOUNT \
  --permission-set-arn arn:aws:sso:::permissionSet/ssoins-xxxxxxxxx/ps-xxxxxxxxx \
  --principal-type GROUP \
  --principal-id group-id
```

### Terraform SSO Configuration
```hcl
# sso.tf
data "aws_ssoadmin_instances" "main" {}

resource "aws_ssoadmin_permission_set" "cloudops_admin" {
  name             = "CloudOpsAdminAccess"
  description      = "Full administrative access for CloudOps team"
  instance_arn     = tolist(data.aws_ssoadmin_instances.main.arns)[0]
  session_duration = "PT8H"
  
  tags = {
    Name = "CloudOps Admin Access"
  }
}

resource "aws_ssoadmin_managed_policy_attachment" "admin_policy" {
  instance_arn       = tolist(data.aws_ssoadmin_instances.main.arns)[0]
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  permission_set_arn = aws_ssoadmin_permission_set.cloudops_admin.arn
}

resource "aws_ssoadmin_permission_set" "cloudops_readonly" {
  name             = "CloudOpsReadOnlyAccess"
  description      = "Read-only access for CloudOps team"
  instance_arn     = tolist(data.aws_ssoadmin_instances.main.arns)[0]
  session_duration = "PT4H"
}

resource "aws_ssoadmin_managed_policy_attachment" "readonly_policy" {
  instance_arn       = tolist(data.aws_ssoadmin_instances.main.arns)[0]
  managed_policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
  permission_set_arn = aws_ssoadmin_permission_set.cloudops_readonly.arn
}

# Custom permission set with inline policy
resource "aws_ssoadmin_permission_set" "cloudops_developer" {
  name         = "CloudOpsDeveloperAccess"
  description  = "Developer access for CloudOps team"
  instance_arn = tolist(data.aws_ssoadmin_instances.main.arns)[0]
}

resource "aws_ssoadmin_permission_set_inline_policy" "developer_policy" {
  inline_policy      = data.aws_iam_policy_document.developer_policy.json
  instance_arn       = tolist(data.aws_ssoadmin_instances.main.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.cloudops_developer.arn
}

data "aws_iam_policy_document" "developer_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:*",
      "s3:*",
      "lambda:*",
      "logs:*",
      "cloudwatch:*"
    ]
    resources = ["*"]
  }
  
  statement {
    effect = "Deny"
    actions = [
      "ec2:TerminateInstances",
      "rds:DeleteDBInstance",
      "s3:DeleteBucket"
    ]
    resources = ["*"]
  }
}
```

## Lab 4: Cost Management and Billing

### Set Up Budgets
```bash
# Create cost budget
aws budgets create-budget \
  --account-id 123456789012 \
  --budget '{
    "BudgetName": "CloudOps-Monthly-Budget",
    "BudgetLimit": {
      "Amount": "1000",
      "Unit": "USD"
    },
    "TimeUnit": "MONTHLY",
    "BudgetType": "COST",
    "CostFilters": {
      "Service": ["Amazon Elastic Compute Cloud - Compute"]
    }
  }' \
  --notifications-with-subscribers '[
    {
      "Notification": {
        "NotificationType": "ACTUAL",
        "ComparisonOperator": "GREATER_THAN",
        "Threshold": 80,
        "ThresholdType": "PERCENTAGE"
      },
      "Subscribers": [
        {
          "SubscriptionType": "EMAIL",
          "Address": "admin@cloudops.example.com"
        }
      ]
    }
  ]'

# Create usage budget
aws budgets create-budget \
  --account-id 123456789012 \
  --budget '{
    "BudgetName": "EC2-Usage-Budget",
    "BudgetLimit": {
      "Amount": "100",
      "Unit": "GB-Month"
    },
    "TimeUnit": "MONTHLY",
    "BudgetType": "USAGE",
    "CostFilters": {
      "Service": ["Amazon Elastic Compute Cloud - Compute"]
    }
  }'
```

### Cost and Usage Reports
```bash
# Create cost and usage report
aws cur put-report-definition \
  --report-definition '{
    "ReportName": "CloudOps-CUR",
    "TimeUnit": "DAILY",
    "Format": "textORcsv",
    "Compression": "GZIP",
    "AdditionalSchemaElements": ["RESOURCES"],
    "S3Bucket": "cloudops-cur-reports",
    "S3Prefix": "cur-reports/",
    "S3Region": "us-east-1",
    "AdditionalArtifacts": ["REDSHIFT", "ATHENA"],
    "RefreshClosedReports": true,
    "ReportVersioning": "OVERWRITE_REPORT"
  }'

# Get cost and usage data
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE
```

### Terraform Cost Management
```hcl
# cost-management.tf
resource "aws_budgets_budget" "monthly_cost" {
  name         = "CloudOps-Monthly-Budget"
  budget_type  = "COST"
  limit_amount = "1000"
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
    subscriber_email_addresses = ["admin@cloudops.example.com"]
  }
  
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 100
    threshold_type            = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = ["admin@cloudops.example.com"]
  }
}

resource "aws_budgets_budget" "ec2_usage" {
  name         = "EC2-Usage-Budget"
  budget_type  = "USAGE"
  limit_amount = "100"
  limit_unit   = "GB-Month"
  time_unit    = "MONTHLY"
  
  cost_filters = {
    Service = ["Amazon Elastic Compute Cloud - Compute"]
  }
}

resource "aws_cur_report_definition" "main" {
  report_name                = "CloudOps-CUR"
  time_unit                  = "DAILY"
  format                     = "textORcsv"
  compression                = "GZIP"
  additional_schema_elements = ["RESOURCES"]
  s3_bucket                  = aws_s3_bucket.cur_reports.bucket
  s3_prefix                  = "cur-reports/"
  s3_region                  = "us-east-1"
  additional_artifacts       = ["REDSHIFT", "ATHENA"]
  refresh_closed_reports     = true
  report_versioning          = "OVERWRITE_REPORT"
}

resource "aws_s3_bucket" "cur_reports" {
  bucket = "cloudops-cur-reports-${random_string.suffix.result}"
}

resource "aws_s3_bucket_policy" "cur_reports_policy" {
  bucket = aws_s3_bucket.cur_reports.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "billingreports.amazonaws.com"
        }
        Action = [
          "s3:GetBucketAcl",
          "s3:GetBucketPolicy"
        ]
        Resource = aws_s3_bucket.cur_reports.arn
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "billingreports.amazonaws.com"
        }
        Action = "s3:PutObject"
        Resource = "${aws_s3_bucket.cur_reports.arn}/*"
      }
    ]
  })
}
```

## Lab 5: AWS Config for Compliance

### Set Up Config Rules
```bash
# Enable Config
aws configservice put-configuration-recorder \
  --configuration-recorder name=default,roleARN=arn:aws:iam::123456789012:role/aws-config-role \
  --recording-group allSupported=true,includeGlobalResourceTypes=true

aws configservice put-delivery-channel \
  --delivery-channel name=default,s3BucketName=cloudops-config-bucket

aws configservice start-configuration-recorder \
  --configuration-recorder-name default

# Create Config rules
aws configservice put-config-rule \
  --config-rule '{
    "ConfigRuleName": "required-tags",
    "Source": {
      "Owner": "AWS",
      "SourceIdentifier": "REQUIRED_TAGS"
    },
    "InputParameters": "{\"tag1Key\":\"Environment\",\"tag1Value\":\"Production,Development,Staging\"}"
  }'

aws configservice put-config-rule \
  --config-rule '{
    "ConfigRuleName": "encrypted-volumes",
    "Source": {
      "Owner": "AWS",
      "SourceIdentifier": "ENCRYPTED_VOLUMES"
    }
  }'
```

### Terraform Config Configuration
```hcl
# config.tf
resource "aws_config_configuration_recorder" "main" {
  name     = "cloudops-recorder"
  role_arn = aws_iam_role.config_role.arn
  
  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "main" {
  name           = "cloudops-delivery-channel"
  s3_bucket_name = aws_s3_bucket.config_bucket.bucket
}

resource "aws_config_config_rule" "required_tags" {
  name = "required-tags"
  
  source {
    owner             = "AWS"
    source_identifier = "REQUIRED_TAGS"
  }
  
  input_parameters = jsonencode({
    tag1Key   = "Environment"
    tag1Value = "Production,Development,Staging"
  })
  
  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_config_rule" "encrypted_volumes" {
  name = "encrypted-volumes"
  
  source {
    owner             = "AWS"
    source_identifier = "ENCRYPTED_VOLUMES"
  }
  
  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_remediation_configuration" "encrypted_volumes" {
  config_rule_name = aws_config_config_rule.encrypted_volumes.name
  
  resource_type    = "AWS::EC2::Volume"
  target_type      = "SSM_DOCUMENT"
  target_id        = "AWSConfigRemediation-EncryptUnencryptedEBSVolumes"
  target_version   = "1"
  
  parameter {
    name           = "AutomationAssumeRole"
    static_value   = aws_iam_role.remediation_role.arn
  }
  
  automatic                = true
  maximum_automatic_attempts = 3
}
```

## Lab 6: Account Security and Compliance

### Security Hub Setup
```bash
# Enable Security Hub
aws securityhub enable-security-hub \
  --enable-default-standards

# Enable standards
aws securityhub batch-enable-standards \
  --standards-subscription-requests StandardsArn=arn:aws:securityhub:::ruleset/finding-format/aws-foundational-security-standard/v/1.0.0

# Get compliance score
aws securityhub get-findings \
  --filters ComplianceStatus=FAILED \
  --max-items 10
```

### Terraform Security Hub
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
```

## Best Practices

1. **Use Organizations** for centralized management
2. **Implement SCPs** for governance
3. **Set up SSO** for centralized access
4. **Monitor costs** with budgets and alerts
5. **Enable Config** for compliance monitoring
6. **Use Control Tower** for landing zones
7. **Regular security assessments** with Security Hub

## Account Monitoring

```bash
# Check organization compliance
aws organizations list-policies --filter SERVICE_CONTROL_POLICY

# Monitor account activity
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=AssumeRole \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-01T23:59:59Z

# Check cost trends
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity DAILY \
  --metrics BlendedCost
```

## Cleanup

```bash
# Remove account from organization
aws organizations remove-account-from-organization \
  --account-id 123456789012

# Delete organizational unit
aws organizations delete-organizational-unit \
  --organizational-unit-id ou-xxxxxxxxx

# Delete budget
aws budgets delete-budget \
  --account-id 123456789012 \
  --budget-name CloudOps-Monthly-Budget
```