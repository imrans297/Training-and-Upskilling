# Security and Compliance Labs

## Overview
Comprehensive security setup with CloudTrail, GuardDuty, Security Hub, KMS encryption, and Secrets Manager.

## Resources Created
- CloudTrail with S3 logging
- GuardDuty detector
- Security Hub with AWS Foundational and CIS standards
- KMS encryption key
- Secrets Manager secret
- SNS topic for security alerts
- EventBridge rules for automated responses

## Usage

```bash
# Initialize
terraform init

# Plan
terraform plan

# Apply
terraform apply -auto-approve

# View GuardDuty findings
aws guardduty list-findings --detector-id $(terraform output -raw guardduty_detector_id)

# View Security Hub findings
aws securityhub get-findings --max-items 10

# Retrieve secret
aws secretsmanager get-secret-value --secret-id $(terraform output -raw secret_arn)

# Destroy
terraform destroy -auto-approve
```

## Security Monitoring
- CloudTrail logs all API calls
- GuardDuty detects threats
- Security Hub aggregates findings
- SNS alerts on high severity findings

## Compliance Standards
- AWS Foundational Security Best Practices
- CIS AWS Foundations Benchmark v1.2.0
