# Lab 2: AWS GuardDuty - Console Manual Steps

## Step 1: Enable GuardDuty

1. **Go to GuardDuty Console**
2. **Get Started** → **Enable GuardDuty**
3. **Configure options:**
   - **Finding export frequency**: 15 minutes
   - **S3 Protection**: ☑️ Enable
   - **Malware Protection**: ☑️ Enable
4. **Enable GuardDuty**

## Step 2: Configure SNS for Alerts

1. **Go to SNS Console**
2. **Topics** → **Create topic**
3. **Configure:**
   - **Type**: Standard
   - **Name**: `guardduty-alerts`
4. **Create topic**
5. **Create subscription:**
   - **Protocol**: Email
   - **Endpoint**: your-email@example.com
6. **Confirm subscription** via email

## Step 3: Create EventBridge Rule

1. **Go to EventBridge Console**
2. **Rules** → **Create rule**
3. **Configure:**
   - **Name**: `guardduty-high-severity`
   - **Event bus**: default
   - **Rule type**: Rule with an event pattern
4. **Event pattern:**
```json
{
  "source": ["aws.guardduty"],
  "detail-type": ["GuardDuty Finding"],
  "detail": {
    "severity": [{"numeric": [">", 7.0]}]
  }
}
```
5. **Target**: SNS topic → Select `guardduty-alerts`
6. **Create rule**

## Step 4: Generate Sample Findings

1. **GuardDuty Console** → **Settings**
2. **Sample findings** → **Generate sample findings**
3. **Wait 5 minutes**
4. **Go to Findings** tab

## Testing After Creation

### Test 1: View Findings

1. **GuardDuty Console** → **Findings**
2. **Observe sample findings:**
   - Finding type
   - Severity
   - Resource affected
   - Count
3. **Click a finding** for details

### Test 2: Filter Findings

1. **Add filter:**
   - **Severity**: High
   - **Finding type**: Backdoor
   - **Resource type**: Instance
2. **Apply filters**
3. **View filtered results**

### Test 3: Archive Findings

1. **Select a finding**
2. **Actions** → **Archive**
3. **Confirm**
4. **View archived findings** (toggle filter)

### Test 4: Check Email Alerts

1. **Generate high severity sample finding**
2. **Wait 5-10 minutes**
3. **Check email** for SNS notification
4. **Verify alert contains:**
   - Finding type
   - Severity
   - Resource ID
   - Account ID

## What to Observe

### 1. Dashboard Metrics
- **Total findings**: Count by severity
- **Most prevalent**: Common finding types
- **Resources at risk**: Affected resources
- **Recent findings**: Last 7 days

### 2. Finding Details
Each finding shows:
- **Severity**: Low/Medium/High/Critical
- **Finding type**: Category and subcategory
- **Resource**: Affected AWS resource
- **Action**: Network/AWS API/DNS activity
- **Actor**: Source IP and location
- **Additional info**: Detailed description

### 3. Finding Categories

**Backdoor Findings:**
- C&C activity detected
- Compromised instance communication

**Behavior Findings:**
- Unusual API calls
- Anomalous behavior patterns

**CryptoCurrency Findings:**
- Bitcoin/mining activity
- Crypto-related DNS queries

**PenTest Findings:**
- Kali Linux usage
- Penetration testing tools

**Recon Findings:**
- Port scanning
- Network probing

**Trojan Findings:**
- Malware detected
- Suspicious file activity

**UnauthorizedAccess Findings:**
- Brute force attempts
- Unauthorized API calls

### 4. Threat Intelligence
- **Known malicious IPs**: Flagged automatically
- **Threat lists**: Updated continuously
- **Reputation scores**: IP/domain reputation

## Common Observations

### High Severity Findings
1. **Backdoor:EC2/C&CActivity.B!DNS**
   - Instance communicating with C&C server
   - **Action**: Isolate instance immediately

2. **UnauthorizedAccess:IAMUser/MaliciousIPCaller.Custom**
   - API calls from malicious IP
   - **Action**: Review IAM credentials

3. **CryptoCurrency:EC2/BitcoinTool.B!DNS**
   - Crypto mining detected
   - **Action**: Terminate instance

### Medium Severity Findings
1. **Recon:EC2/PortProbeUnprotectedPort**
   - Port scanning detected
   - **Action**: Review security groups

2. **Behavior:EC2/NetworkPortUnusual**
   - Unusual network port usage
   - **Action**: Investigate application

## Automated Actions

### For High Severity Findings:
1. **Email notification** sent via SNS
2. **Can trigger Lambda** for auto-remediation:
   - Isolate instance (change security group)
   - Create snapshot
   - Notify security team
   - Create incident ticket

### Integration Options:
- **Security Hub**: Aggregate findings
- **Detective**: Investigate further
- **Lambda**: Auto-remediation
- **SIEM**: Export to external tools

## Troubleshooting

### Issue: No findings appearing
**Check:**
1. GuardDuty is enabled
2. Wait 15-30 minutes for initial analysis
3. Generate sample findings for testing

### Issue: Email alerts not received
**Check:**
1. SNS subscription confirmed
2. EventBridge rule active
3. Rule pattern matches findings
4. Check spam folder

### Issue: Too many false positives
**Actions:**
1. Add trusted IPs to IP set
2. Suppress specific finding types
3. Archive non-actionable findings
4. Adjust severity thresholds

## Best Practices

1. **Enable in all regions**: Multi-region coverage
2. **Review findings daily**: Stay on top of threats
3. **Automate responses**: Use Lambda for remediation
4. **Integrate with Security Hub**: Centralized view
5. **Create runbooks**: Document response procedures
6. **Test regularly**: Generate sample findings

## Cleanup

1. **GuardDuty Console** → **Settings**
2. **Suspend GuardDuty** (or Disable)
3. **Confirm suspension**
4. **Delete EventBridge rule**
5. **Delete SNS topic**
6. **Delete S3 bucket** (if created)

## Key Takeaways

- GuardDuty provides continuous threat monitoring
- Uses ML to detect anomalies
- Analyzes CloudTrail, VPC Flow Logs, DNS logs
- Findings categorized by severity
- Can automate responses via EventBridge
- 30-day free trial available
- Essential for AWS security posture
