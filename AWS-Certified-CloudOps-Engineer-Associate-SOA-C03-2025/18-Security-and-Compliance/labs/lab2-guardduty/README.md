# Lab 2: AWS GuardDuty

## What is GuardDuty?
AWS GuardDuty is a threat detection service that continuously monitors for malicious activity and unauthorized behavior to protect your AWS accounts, workloads, and data.

## Why Use GuardDuty?
- **Threat Detection**: Identifies malicious or unauthorized activity
- **Continuous Monitoring**: 24/7 security monitoring
- **Machine Learning**: Uses ML to detect anomalies
- **No Infrastructure**: Fully managed service

## Where is it Used?
- Security threat detection
- Compromised instance identification
- Reconnaissance activity detection
- Cryptocurrency mining detection
- Data exfiltration monitoring

## Resources Created
- GuardDuty detector
- S3 bucket for trusted IP lists
- SNS topic for high-severity alerts
- EventBridge rule for automated responses

## Deployment

```bash
terraform init
terraform plan
terraform apply -auto-approve

# Confirm SNS subscription via email
```

## What to Observe After Deployment

### 1. GuardDuty Status
```bash
# Check detector status
aws guardduty get-detector \
  --detector-id $(terraform output -raw guardduty_detector_id)

# Expected: Status: ENABLED
```

### 2. List Findings
```bash
# List all findings
aws guardduty list-findings \
  --detector-id $(terraform output -raw guardduty_detector_id)

# Get finding details
aws guardduty get-findings \
  --detector-id $(terraform output -raw guardduty_detector_id) \
  --finding-ids <finding-id>
```

### 3. Check Finding Statistics
```bash
# Get finding statistics
aws guardduty get-findings-statistics \
  --detector-id $(terraform output -raw guardduty_detector_id) \
  --finding-statistic-types COUNT_BY_SEVERITY
```

## Testing

### Test 1: Generate Sample Findings
```bash
# Generate sample findings (for testing)
aws guardduty create-sample-findings \
  --detector-id $(terraform output -raw guardduty_detector_id) \
  --finding-types Backdoor:EC2/C&CActivity.B!DNS

# Wait 5 minutes, then list findings
aws guardduty list-findings \
  --detector-id $(terraform output -raw guardduty_detector_id)
```

### Test 2: Monitor High Severity Findings
```bash
# Filter high severity findings
aws guardduty list-findings \
  --detector-id $(terraform output -raw guardduty_detector_id) \
  --finding-criteria '{"Criterion":{"severity":{"Gte":7}}}'
```

### Test 3: Check SNS Notifications
- Check email for GuardDuty alerts
- High severity findings trigger SNS notifications
- Review alert details

## Key Observations

### Finding Types
1. **Backdoor**: Compromised EC2 instances
2. **Behavior**: Unusual API activity
3. **CryptoCurrency**: Mining activity
4. **PenTest**: Penetration testing activity
5. **Recon**: Reconnaissance activity
6. **Trojan**: Malware detected
7. **UnauthorizedAccess**: Unauthorized access attempts

### Severity Levels
- **Low**: 0.1 - 3.9
- **Medium**: 4.0 - 6.9
- **High**: 7.0 - 8.9
- **Critical**: 9.0 - 10.0

### Finding Details Include
- **Resource affected**: EC2, IAM, S3
- **Action type**: Network, AWS API, DNS
- **Actor**: IP address, location
- **Severity**: Numerical score
- **Confidence**: Detection confidence level

## Common Findings

1. **UnauthorizedAccess:EC2/SSHBruteForce**
   - SSH brute force attempts
   - Action: Review security groups

2. **Recon:EC2/PortProbeUnprotectedPort**
   - Port scanning detected
   - Action: Restrict security groups

3. **CryptoCurrency:EC2/BitcoinTool.B!DNS**
   - Crypto mining activity
   - Action: Investigate instance

4. **Backdoor:EC2/C&CActivity.B!DNS**
   - Command & control communication
   - Action: Isolate instance immediately

## Automated Response

EventBridge rule triggers SNS for findings with severity > 7.0:
- Email notification sent
- Can extend to Lambda for auto-remediation
- Can integrate with Security Hub

## Troubleshooting

### Issue: No findings
```bash
# Check detector status
aws guardduty get-detector \
  --detector-id $(terraform output -raw guardduty_detector_id)

# Generate sample findings for testing
aws guardduty create-sample-findings \
  --detector-id $(terraform output -raw guardduty_detector_id) \
  --finding-types Recon:EC2/PortProbeUnprotectedPort
```

### Issue: SNS not receiving alerts
```bash
# Check SNS subscription
aws sns list-subscriptions-by-topic \
  --topic-arn $(terraform output -raw sns_topic_arn)

# Verify EventBridge rule
aws events list-rules --name-prefix guardduty
```

## Cleanup
```bash
terraform destroy -auto-approve
```

## Cost Considerations
- **30-day free trial**: Full features
- **After trial**: 
  - CloudTrail analysis: $4.40 per million events
  - VPC Flow Logs: $1.18 per GB
  - DNS Logs: $0.40 per million queries
- **Typical cost**: $5-50/month depending on usage
