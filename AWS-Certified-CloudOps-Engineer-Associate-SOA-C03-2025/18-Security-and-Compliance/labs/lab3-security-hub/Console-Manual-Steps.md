# Lab 3: AWS Security Hub - Console Manual Steps

## Step 1: Enable Security Hub

1. **Go to Security Hub Console**
2. **Go to Security Hub** → **Enable Security Hub**
3. **Security standards:**
   - ☑️ AWS Foundational Security Best Practices
   - ☑️ CIS AWS Foundations Benchmark v1.2.0
4. **Enable Security Hub**

## Step 2: Configure SNS for Alerts

1. **Go to SNS Console**
2. **Create topic**: `security-hub-alerts`
3. **Create subscription**: Email → your-email@example.com
4. **Confirm subscription**

## Step 3: Create EventBridge Rule

1. **Go to EventBridge Console**
2. **Create rule**: `security-hub-critical-findings`
3. **Event pattern:**
```json
{
  "source": ["aws.securityhub"],
  "detail-type": ["Security Hub Findings - Imported"],
  "detail": {
    "findings": {
      "Severity": {
        "Label": ["CRITICAL", "HIGH"]
      }
    }
  }
}
```
4. **Target**: SNS topic → `security-hub-alerts`
5. **Create rule**

## Step 4: Wait for Initial Scan

1. **Wait 30 minutes** for initial security checks
2. **Dashboard** will populate with findings

## Testing After Creation

### Test 1: View Summary Dashboard

1. **Security Hub Console** → **Summary**
2. **Observe:**
   - Security score (percentage)
   - Failed findings by severity
   - Top failed security checks
   - Findings by resource type

### Test 2: Review Findings

1. **Findings** tab
2. **Filter by:**
   - **Workflow status**: New
   - **Severity**: Critical, High
   - **Compliance status**: Failed
3. **Click finding** for details:
   - Description
   - Remediation steps
   - Affected resource
   - Compliance standard

### Test 3: Check Compliance Standards

1. **Security standards** tab
2. **View each standard:**
   - **AWS Foundational**: Score and controls
   - **CIS Benchmark**: Score and controls
3. **Click standard** to see:
   - Enabled controls
   - Failed controls
   - Passed controls

### Test 4: Create Custom Insight

1. **Insights** → **Create insight**
2. **Configure filters:**
   - **Resource type**: AwsEc2Instance
   - **Compliance status**: FAILED
3. **Group by**: ResourceId
4. **Name**: `Non-compliant EC2 instances`
5. **Create insight**

## What to Observe

### 1. Dashboard Metrics
- **Security score**: 0-100%
- **New findings**: Last 24 hours
- **Failed checks**: By severity
- **Trends**: Over time

### 2. Common Failed Checks

**High Severity:**
- **EC2.2**: Security groups allow unrestricted access
- **IAM.4**: Root account access key exists
- **CloudTrail.1**: CloudTrail not enabled
- **S3.8**: S3 bucket public access not blocked

**Medium Severity:**
- **S3.1**: S3 bucket logging not enabled
- **RDS.3**: RDS encryption not enabled
- **IAM.1**: Password policy not configured
- **EC2.8**: EC2 instance IMDSv2 not enabled

### 3. Finding Details Include
- **Title**: Brief description
- **Severity**: Critical/High/Medium/Low
- **Resource**: Affected AWS resource
- **Compliance**: Which standard failed
- **Remediation**: Step-by-step fix
- **Status**: New/Notified/Resolved/Suppressed

### 4. Compliance Standards

**AWS Foundational Security Best Practices:**
- **Compute**: EC2, Lambda security
- **Storage**: S3, EBS encryption
- **Database**: RDS, DynamoDB security
- **Networking**: VPC, security groups
- **Identity**: IAM best practices

**CIS AWS Foundations Benchmark:**
- **Section 1**: Identity and Access Management
- **Section 2**: Storage
- **Section 3**: Logging
- **Section 4**: Monitoring

## Remediation Examples

### Fix 1: Enable S3 Block Public Access
1. **Go to S3 Console**
2. **Select bucket** from finding
3. **Permissions** → **Block public access**
4. **Edit** → ☑️ Block all public access
5. **Save changes**

### Fix 2: Restrict Security Group
1. **Go to EC2 Console** → **Security Groups**
2. **Select security group** from finding
3. **Inbound rules** → **Edit**
4. **Remove 0.0.0.0/0 rules**
5. **Add specific IP ranges**
6. **Save rules**

### Fix 3: Enable CloudTrail
1. **Go to CloudTrail Console**
2. **Create trail**
3. **Enable for all regions**
4. **Configure S3 bucket**
5. **Create trail**

### Fix 4: Update IAM Password Policy
1. **Go to IAM Console**
2. **Account settings**
3. **Password policy** → **Edit**
4. **Configure:**
   - Minimum length: 14
   - Require uppercase
   - Require lowercase
   - Require numbers
   - Require symbols
   - Password expiration: 90 days
5. **Save changes**

## Automated Actions

### For Critical/High Findings:
1. **Email sent** via SNS
2. **Can trigger Lambda** for:
   - Auto-remediation
   - Ticket creation
   - Slack notification
   - Security team alert

### Integration Options:
- **GuardDuty**: Threat detection findings
- **Inspector**: Vulnerability findings
- **Macie**: Data security findings
- **IAM Access Analyzer**: Access findings
- **Firewall Manager**: Firewall findings

## Troubleshooting

### Issue: Low security score
**Actions:**
1. Review failed findings
2. Prioritize by severity
3. Remediate high/critical first
4. Document exceptions
5. Suppress false positives

### Issue: Too many findings
**Actions:**
1. Disable non-relevant controls
2. Suppress expected findings
3. Focus on critical/high
4. Create remediation plan
5. Automate fixes

### Issue: Finding not updating
**Actions:**
1. Wait 24 hours for re-check
2. Verify fix was applied correctly
3. Check resource still exists
4. Manual re-scan if needed

## Best Practices

1. **Review daily**: Check new findings
2. **Prioritize**: Focus on critical/high
3. **Automate**: Use Lambda for common fixes
4. **Document**: Track exceptions and waivers
5. **Integrate**: Connect with SIEM/ticketing
6. **Multi-account**: Use Organizations integration
7. **Custom insights**: Create for your use cases

## Cleanup

1. **Security Hub Console** → **Settings**
2. **General** → **Disable AWS Security Hub**
3. **Confirm disable**
4. **Delete EventBridge rule**
5. **Delete SNS topic**

## Key Takeaways

- Security Hub aggregates security findings
- Checks against industry standards
- Provides compliance scoring
- Automated security checks
- Centralized security view
- Integrates with AWS security services
- Essential for compliance and governance
