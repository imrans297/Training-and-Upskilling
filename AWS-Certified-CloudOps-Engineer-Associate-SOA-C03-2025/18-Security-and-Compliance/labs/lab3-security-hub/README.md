# Lab 3: AWS Security Hub

## What is Security Hub?
AWS Security Hub provides a comprehensive view of your security state within AWS and helps you check your environment against security industry standards and best practices.

## Why Use Security Hub?
- **Centralized Security**: Aggregates findings from multiple AWS services
- **Compliance Checking**: Automated compliance checks against standards
- **Prioritization**: Severity-based finding prioritization
- **Integration**: Works with GuardDuty, Inspector, Macie, IAM Access Analyzer

## Where is it Used?
- Security posture management
- Compliance auditing (CIS, PCI-DSS, AWS Best Practices)
- Multi-account security monitoring
- Security findings aggregation

## Resources Created
- Security Hub account
- AWS Foundational Security Best Practices standard
- CIS AWS Foundations Benchmark v1.2.0
- Custom insights for critical findings
- SNS topic for alerts
- EventBridge rule for high/critical findings

## Deployment

```bash
terraform init
terraform plan
terraform apply -auto-approve

# Confirm SNS subscription via email
```

## What to Observe After Deployment

### 1. Security Hub Status
```bash
# Check Security Hub status
aws securityhub describe-hub

# List enabled standards
aws securityhub get-enabled-standards
```

### 2. View Findings
```bash
# Get all findings
aws securityhub get-findings --max-items 10

# Get critical findings
aws securityhub get-findings \
  --filters '{"SeverityLabel":[{"Value":"CRITICAL","Comparison":"EQUALS"}]}'

# Get failed compliance checks
aws securityhub get-findings \
  --filters '{"ComplianceStatus":[{"Value":"FAILED","Comparison":"EQUALS"}]}'
```

### 3. Check Compliance Score
```bash
# Get standards compliance
aws securityhub get-compliance-summary-by-resource-type
```

## Testing

### Test 1: View Security Standards
```bash
# List all standards
aws securityhub describe-standards

# Get standard controls
aws securityhub describe-standards-controls \
  --standards-subscription-arn <arn>
```

### Test 2: Create Non-Compliant Resource
```bash
# Create S3 bucket without encryption (triggers finding)
aws s3 mb s3://test-non-compliant-$(date +%s)

# Wait 15-30 minutes for Security Hub to detect
# Check findings
aws securityhub get-findings \
  --filters '{"ResourceType":[{"Value":"AwsS3Bucket","Comparison":"EQUALS"}]}'
```

### Test 3: Review Insights
```bash
# List custom insights
aws securityhub get-insights

# Get insight results
aws securityhub get-insight-results \
  --insight-arn <insight-arn>
```

## Key Observations

### Security Standards

**AWS Foundational Security Best Practices:**
- 50+ automated security checks
- Covers EC2, S3, IAM, RDS, Lambda, etc.
- Best practices from AWS security experts

**CIS AWS Foundations Benchmark:**
- Industry-standard security framework
- 43 controls across 4 sections
- Compliance-focused checks

### Finding Severity
- **CRITICAL**: Immediate action required
- **HIGH**: Important security issue
- **MEDIUM**: Should be addressed
- **LOW**: Minor security concern
- **INFORMATIONAL**: For awareness

### Common Findings

1. **S3.1 - S3 Block Public Access**
   - S3 buckets should have block public access enabled
   - Severity: MEDIUM

2. **EC2.2 - Security Group Rules**
   - Security groups should not allow unrestricted access
   - Severity: HIGH

3. **IAM.1 - IAM Password Policy**
   - Password policy should meet requirements
   - Severity: MEDIUM

4. **RDS.3 - RDS Encryption**
   - RDS instances should have encryption enabled
   - Severity: MEDIUM

5. **CloudTrail.1 - CloudTrail Enabled**
   - CloudTrail should be enabled
   - Severity: HIGH

## Compliance Dashboard

### Metrics to Monitor:
- **Security score**: Overall percentage
- **Failed checks**: Count by severity
- **Passed checks**: Compliant controls
- **Unknown**: Not evaluated yet

### By Resource Type:
- EC2 instances
- S3 buckets
- IAM users/roles
- RDS databases
- Lambda functions

## Automated Remediation

EventBridge triggers SNS for CRITICAL/HIGH findings:
- Email notification
- Can trigger Lambda for auto-fix
- Integration with ticketing systems

### Example Auto-Remediation:
- Enable S3 encryption
- Remove unrestricted security group rules
- Enable CloudTrail logging
- Rotate IAM access keys

## Troubleshooting

### Issue: No findings appearing
```bash
# Wait 30 minutes after enabling
# Check if standards are enabled
aws securityhub get-enabled-standards

# Verify resources exist to check
aws ec2 describe-instances
aws s3 ls
```

### Issue: Too many findings
```bash
# Suppress specific findings
aws securityhub batch-update-findings \
  --finding-identifiers Id=<finding-id>,ProductArn=<product-arn> \
  --workflow Status=SUPPRESSED

# Disable specific controls
aws securityhub update-standards-control \
  --standards-control-arn <control-arn> \
  --control-status DISABLED
```

## Cleanup
```bash
terraform destroy -auto-approve
```

## Cost Considerations
- **Security checks**: $0.0010 per check per month
- **Finding ingestion**: $0.00003 per finding
- **Typical cost**: $10-100/month depending on resources
- **30-day free trial**: 10,000 checks/month
