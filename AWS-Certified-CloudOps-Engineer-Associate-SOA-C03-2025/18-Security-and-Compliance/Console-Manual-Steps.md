# 🖥️ Security and Compliance - Manual Console Steps

## **Lab 1: Enable CloudTrail**

### **Step 1: Create S3 Bucket for Logs**
1. **Go to S3 Console**
2. **Create bucket**
3. **Configure:**
   - **Name**: `cloudops-cloudtrail-logs-unique`
   - **Region**: us-east-1
4. **Create bucket**

### **Step 2: Create CloudTrail**
1. **Go to CloudTrail Console**
2. **Trails** → **Create trail**
3. **Configure:**
   - **Trail name**: `cloudops-trail`
   - **Storage location**: Use existing S3 bucket
   - **S3 bucket**: Select created bucket
   - **Log file SSE-KMS encryption**: Enable (optional)
   - **Log file validation**: ☑️ Enable
   - **SNS notification**: Optional
   - **CloudWatch Logs**: Optional
4. **Choose log events:**
   - **Management events**: ☑️ Read and Write
   - **Data events**: Add S3 buckets if needed
   - **Insights events**: ☑️ API call rate
5. **Create trail**

### **Step 3: Verify Logging**
1. **Event history** tab
2. **View recent events**
3. **Filter by event name, user, resource**

---

## **Lab 2: Enable GuardDuty**

### **Step 1: Enable GuardDuty**
1. **Go to GuardDuty Console**
2. **Get Started** → **Enable GuardDuty**
3. **Configure:**
   - **Finding export frequency**: 15 minutes
   - **S3 Protection**: ☑️ Enable
   - **EKS Protection**: ☑️ Enable (if using EKS)
   - **Malware Protection**: ☑️ Enable
4. **Enable GuardDuty**

### **Step 2: Configure Trusted IPs (Optional)**
1. **Lists** → **IP sets**
2. **Add IP set**
3. **Configure:**
   - **Name**: `trusted-ips`
   - **Location**: Upload file or S3 URL
   - **Format**: TXT or CSV
   - **Status**: Active
4. **Add IP set**

### **Step 3: View Findings**
1. **Findings** tab
2. **Filter by severity, type, resource**
3. **Click finding** for details
4. **Archive or suppress** as needed

---

## **Lab 3: Enable Security Hub**

### **Step 1: Enable Security Hub**
1. **Go to Security Hub Console**
2. **Go to Security Hub** → **Enable Security Hub**
3. **Security standards:**
   - ☑️ AWS Foundational Security Best Practices
   - ☑️ CIS AWS Foundations Benchmark v1.2.0
   - ☑️ PCI DSS (if applicable)
4. **Enable Security Hub**

### **Step 2: Review Findings**
1. **Findings** tab
2. **Filter by:**
   - Severity: Critical, High, Medium, Low
   - Compliance status: Passed, Failed
   - Resource type
3. **Click finding** for remediation steps

### **Step 3: Create Custom Insights**
1. **Insights** → **Create insight**
2. **Configure filters:**
   - Resource type: AwsEc2Instance
   - Compliance status: FAILED
3. **Group by**: ResourceId
4. **Name**: `Non-compliant EC2 instances`
5. **Create insight**

### **Step 4: Configure Actions**
1. **Settings** → **Custom actions**
2. **Create custom action**
3. **Configure:**
   - **Name**: `Isolate-Instance`
   - **Description**: Isolate compromised instance
   - **Action ID**: Custom identifier
4. **Create action**

---

## **Lab 4: Enable AWS Inspector**

### **Step 1: Enable Inspector**
1. **Go to Inspector Console**
2. **Get started** → **Enable Inspector**
3. **Select scan types:**
   - ☑️ Amazon EC2 scanning
   - ☑️ Amazon ECR scanning
4. **Enable Inspector**

### **Step 2: View Findings**
1. **Findings** tab
2. **Filter by severity**
3. **Review CVE details**
4. **Export findings** if needed

---

## **Lab 5: Create KMS Key**

### **Step 1: Create KMS Key**
1. **Go to KMS Console**
2. **Customer managed keys** → **Create key**
3. **Configure:**
   - **Key type**: Symmetric
   - **Key usage**: Encrypt and decrypt
   - **Regionality**: Single-Region key
4. **Next**

### **Step 2: Add Labels**
1. **Alias**: `cloudops-key`
2. **Description**: `CloudOps encryption key`
3. **Tags**: Add as needed
4. **Next**

### **Step 3: Define Key Permissions**
1. **Key administrators**: Select IAM users/roles
2. **Key deletion**: Allow administrators to delete
3. **Next**

### **Step 4: Define Key Usage**
1. **Key users**: Select IAM users/roles
2. **Other AWS accounts**: Add if needed
3. **Next** → **Finish**

### **Step 5: Create Alias**
1. **Select key**
2. **Aliases** tab → **Create alias**
3. **Alias name**: `alias/cloudops-encryption`

---

## **Lab 6: Create Secret in Secrets Manager**

### **Step 1: Store New Secret**
1. **Go to Secrets Manager Console**
2. **Store a new secret**
3. **Secret type:**
   - **Credentials for RDS database**
   - Or **Other type of secret**
4. **Configure:**
   - **Username**: `admin`
   - **Password**: Generate or enter
   - **Encryption key**: Select KMS key
   - **Database**: Select RDS instance (if applicable)
5. **Next**

### **Step 2: Configure Secret**
1. **Secret name**: `cloudops/database/credentials`
2. **Description**: Database credentials
3. **Tags**: Add as needed
4. **Next**

### **Step 3: Configure Rotation (Optional)**
1. **Automatic rotation**: ☑️ Enable
2. **Rotation schedule**: 30 days
3. **Lambda function**: Select or create
4. **Next** → **Store**

### **Step 4: Retrieve Secret**
1. **Select secret**
2. **Retrieve secret value**
3. **Copy credentials**

---

## **Lab 7: Configure SNS for Security Alerts**

### **Step 1: Create SNS Topic**
1. **Go to SNS Console**
2. **Topics** → **Create topic**
3. **Configure:**
   - **Type**: Standard
   - **Name**: `cloudops-security-alerts`
   - **Encryption**: Enable with KMS key
4. **Create topic**

### **Step 2: Create Subscription**
1. **Subscriptions** → **Create subscription**
2. **Configure:**
   - **Topic ARN**: Select created topic
   - **Protocol**: Email
   - **Endpoint**: your-email@example.com
3. **Create subscription**
4. **Confirm subscription** via email

### **Step 3: Create EventBridge Rule**
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
5. **Target**: SNS topic
6. **Select topic**: `cloudops-security-alerts`
7. **Create rule**

---

## **Lab 8: Configure CloudWatch Alarms**

### **Step 1: Create Alarm for Failed Logins**
1. **Go to CloudWatch Console**
2. **Alarms** → **Create alarm**
3. **Select metric:**
   - **Logs** → **Log group metrics**
   - **Metric**: UnauthorizedAPICalls
4. **Configure:**
   - **Threshold**: Greater than 5
   - **Period**: 5 minutes
5. **Configure actions:**
   - **SNS topic**: `cloudops-security-alerts`
6. **Create alarm**

### **Step 2: Create Alarm for Root Account Usage**
1. **Create alarm**
2. **Metric filter:**
   - Log group: CloudTrail logs
   - Filter pattern: `{ $.userIdentity.type = "Root" }`
3. **Threshold**: Greater than 0
4. **SNS notification**
5. **Create alarm**

---

## **Lab 9: AWS Config Rules**

### **Step 1: Enable AWS Config**
1. **Go to AWS Config Console**
2. **Get started** → **1-click setup**
3. **Configure:**
   - **Resource types**: All resources
   - **S3 bucket**: Create new or use existing
   - **SNS topic**: Optional
   - **IAM role**: Create new
4. **Confirm**

### **Step 2: Add Managed Rules**
1. **Rules** → **Add rule**
2. **Select managed rules:**
   - `encrypted-volumes`
   - `s3-bucket-public-read-prohibited`
   - `iam-password-policy`
   - `rds-storage-encrypted`
3. **Configure each rule**
4. **Save**

### **Step 3: View Compliance**
1. **Dashboard** → **Compliance status**
2. **Filter by compliant/non-compliant**
3. **Remediate non-compliant resources**

---

## **Verification Checklist**

### **CloudTrail:**
- ☑️ Trail enabled and logging
- ☑️ Log file validation enabled
- ☑️ Multi-region trail
- ☑️ Events appearing in S3

### **GuardDuty:**
- ☑️ Detector enabled
- ☑️ S3 protection enabled
- ☑️ Findings visible
- ☑️ Alerts configured

### **Security Hub:**
- ☑️ Security Hub enabled
- ☑️ Standards enabled
- ☑️ Findings aggregated
- ☑️ Insights created

### **KMS & Secrets:**
- ☑️ KMS key created
- ☑️ Secrets stored
- ☑️ Encryption working
- ☑️ Rotation configured

---

## **Cleanup**

### **Step 1: Disable Services**
1. **Security Hub** → Settings → Disable
2. **GuardDuty** → Settings → Disable
3. **Inspector** → Disable

### **Step 2: Delete Resources**
1. **CloudTrail** → Delete trail
2. **Secrets Manager** → Delete secrets
3. **KMS** → Schedule key deletion
4. **SNS** → Delete topics
5. **S3** → Empty and delete buckets

### **Step 3: Remove Config Rules**
1. **AWS Config** → Rules → Delete
2. **Disable AWS Config**
