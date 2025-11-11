# 🔐 AWS Cross-Account Access Guide

## Overview
Cross-account access allows users from one AWS account to access resources in another AWS account securely. This guide covers different scenarios and implementation methods.

---

## **Scenario 1: Cross-Account IAM Role Access**

### **Account Setup**
- **Account A (Trusted Account)**: Contains user `imran.shaikh`
- **Account B (Trusting Account)**: Contains resources to be accessed

### **Step 1: Create Cross-Account Role in Account B**

#### **Console Steps:**
1. **Go to IAM Console** → **Roles**
2. **Click "Create role"**
3. **Select "AWS account"**
4. **Configure:**
   - **Account ID**: Enter Account A's ID (where imran.shaikh exists)
   - **Options**: 
     - ☑️ Require external ID (optional for extra security)
     - ☑️ Require MFA (recommended)
5. **Attach policies** (e.g., `ReadOnlyAccess`, `EC2FullAccess`)
6. **Role name**: `CrossAccountAccessRole`
7. **Create role**

#### **Trust Policy Example:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::ACCOUNT-A-ID:user/imran.shaikh"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "Bool": {
          "aws:MultiFactorAuthPresent": "true"
        }
      }
    }
  ]
}
```

### **Step 2: Grant AssumeRole Permission in Account A**

#### **Policy for imran.shaikh:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": "arn:aws:iam::ACCOUNT-B-ID:role/CrossAccountAccessRole"
    }
  ]
}
```

### **Step 3: Assume Role (CLI/SDK)**

#### **AWS CLI Command:**
```bash
# Assume the role
aws sts assume-role \
  --role-arn "arn:aws:iam::ACCOUNT-B-ID:role/CrossAccountAccessRole" \
  --role-session-name "imran-cross-account-session"

# Use temporary credentials
export AWS_ACCESS_KEY_ID=<temporary-access-key>
export AWS_SECRET_ACCESS_KEY=<temporary-secret-key>
export AWS_SESSION_TOKEN=<session-token>

# Now access Account B resources
aws ec2 describe-instances
```

---

## **Scenario 2: Cross-Account S3 Bucket Access**

### **Step 1: Create S3 Bucket Policy in Account B**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "CrossAccountAccess",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::ACCOUNT-A-ID:user/imran.shaikh"
      },
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::cross-account-bucket",
        "arn:aws:s3:::cross-account-bucket/*"
      ]
    }
  ]
}
```

### **Step 2: Test Access**
```bash
# List bucket contents
aws s3 ls s3://cross-account-bucket

# Upload file
aws s3 cp file.txt s3://cross-account-bucket/

# Download file
aws s3 cp s3://cross-account-bucket/file.txt ./
```

---

## **Scenario 3: Cross-Account Lambda Function Access**

### **Step 1: Create Lambda Resource Policy**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "CrossAccountInvoke",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::ACCOUNT-A-ID:user/imran.shaikh"
      },
      "Action": "lambda:InvokeFunction",
      "Resource": "arn:aws:lambda:us-east-1:ACCOUNT-B-ID:function:CrossAccountFunction"
    }
  ]
}
```

### **Step 2: Invoke Lambda Function**
```bash
aws lambda invoke \
  --function-name arn:aws:lambda:us-east-1:ACCOUNT-B-ID:function:CrossAccountFunction \
  --payload '{"key": "value"}' \
  response.json
```

---

## **Scenario 4: Cross-Account RDS Access**

### **Step 1: Create DB Subnet Group (if needed)**
```bash
aws rds create-db-subnet-group \
  --db-subnet-group-name cross-account-subnet-group \
  --db-subnet-group-description "Cross account subnet group" \
  --subnet-ids subnet-12345 subnet-67890
```

### **Step 2: Share RDS Snapshot**
```bash
# Share snapshot with Account A
aws rds modify-db-snapshot-attribute \
  --db-snapshot-identifier my-snapshot \
  --attribute-name restore \
  --values-to-add ACCOUNT-A-ID
```

### **Step 3: Restore from Shared Snapshot in Account A**
```bash
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier restored-db \
  --db-snapshot-identifier arn:aws:rds:us-east-1:ACCOUNT-B-ID:snapshot:my-snapshot
```

---

## **Scenario 5: Cross-Account VPC Peering**

### **Step 1: Create VPC Peering Connection**

#### **In Account B (Accepter):**
```bash
# Create peering connection
aws ec2 create-vpc-peering-connection \
  --vpc-id vpc-12345678 \
  --peer-vpc-id vpc-87654321 \
  --peer-owner-id ACCOUNT-A-ID \
  --peer-region us-east-1
```

#### **In Account A (Requester):**
```bash
# Accept peering connection
aws ec2 accept-vpc-peering-connection \
  --vpc-peering-connection-id pcx-1234567890abcdef0
```

### **Step 2: Update Route Tables**
```bash
# Add route in Account A
aws ec2 create-route \
  --route-table-id rtb-12345678 \
  --destination-cidr-block 10.1.0.0/16 \
  --vpc-peering-connection-id pcx-1234567890abcdef0

# Add route in Account B
aws ec2 create-route \
  --route-table-id rtb-87654321 \
  --destination-cidr-block 10.0.0.0/16 \
  --vpc-peering-connection-id pcx-1234567890abcdef0
```

---

## **Scenario 6: Cross-Account ECR Access**

### **Step 1: Set ECR Repository Policy**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "CrossAccountPull",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::ACCOUNT-A-ID:user/imran.shaikh"
      },
      "Action": [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability"
      ]
    }
  ]
}
```

### **Step 2: Login and Pull Image**
```bash
# Get login token
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ACCOUNT-B-ID.dkr.ecr.us-east-1.amazonaws.com

# Pull image
docker pull ACCOUNT-B-ID.dkr.ecr.us-east-1.amazonaws.com/my-repo:latest
```

---

## **Security Best Practices**

### **1. Principle of Least Privilege**
- Grant minimum required permissions
- Use specific resource ARNs instead of wildcards
- Regularly review and audit permissions

### **2. Enable MFA**
```json
{
  "Condition": {
    "Bool": {
      "aws:MultiFactorAuthPresent": "true"
    }
  }
}
```

### **3. Use External ID for Enhanced Security**
```json
{
  "Condition": {
    "StringEquals": {
      "sts:ExternalId": "unique-external-id-12345"
    }
  }
}
```

### **4. Time-Based Access**
```json
{
  "Condition": {
    "DateGreaterThan": {
      "aws:CurrentTime": "2024-01-01T00:00:00Z"
    },
    "DateLessThan": {
      "aws:CurrentTime": "2024-12-31T23:59:59Z"
    }
  }
}
```

### **5. IP Address Restrictions**
```json
{
  "Condition": {
    "IpAddress": {
      "aws:SourceIp": ["203.0.113.0/24", "198.51.100.0/24"]
    }
  }
}
```

---

## **Monitoring and Auditing**

### **1. CloudTrail Logging**
```bash
# Enable CloudTrail for cross-account activities
aws cloudtrail create-trail \
  --name cross-account-trail \
  --s3-bucket-name cloudtrail-logs-bucket \
  --include-global-service-events \
  --is-multi-region-trail
```

### **2. CloudWatch Metrics**
- Monitor `AssumeRole` API calls
- Set up alarms for unusual cross-account activity
- Track failed authentication attempts

### **3. AWS Config Rules**
```json
{
  "ConfigRuleName": "cross-account-role-compliance",
  "Source": {
    "Owner": "AWS",
    "SourceIdentifier": "IAM_ROLE_MANAGED_POLICY_CHECK"
  }
}
```

---

## **Troubleshooting Common Issues**

### **1. Access Denied Errors**
```bash
# Check if role can be assumed
aws sts get-caller-identity

# Verify trust relationship
aws iam get-role --role-name CrossAccountAccessRole
```

### **2. MFA Requirements**
```bash
# Get MFA device
aws iam list-mfa-devices --user-name imran.shaikh

# Assume role with MFA
aws sts assume-role \
  --role-arn "arn:aws:iam::ACCOUNT-B-ID:role/CrossAccountAccessRole" \
  --role-session-name "mfa-session" \
  --serial-number "arn:aws:iam::ACCOUNT-A-ID:mfa/imran.shaikh" \
  --token-code 123456
```

### **3. Session Duration**
```bash
# Extend session duration (max 12 hours)
aws sts assume-role \
  --role-arn "arn:aws:iam::ACCOUNT-B-ID:role/CrossAccountAccessRole" \
  --role-session-name "extended-session" \
  --duration-seconds 43200
```

---

## **Automation Scripts**

### **1. Assume Role Script**
```bash
#!/bin/bash
# assume-role.sh

ROLE_ARN="arn:aws:iam::ACCOUNT-B-ID:role/CrossAccountAccessRole"
SESSION_NAME="imran-session-$(date +%s)"

# Assume role and extract credentials
CREDENTIALS=$(aws sts assume-role \
  --role-arn "$ROLE_ARN" \
  --role-session-name "$SESSION_NAME" \
  --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
  --output text)

# Export credentials
export AWS_ACCESS_KEY_ID=$(echo $CREDENTIALS | cut -d' ' -f1)
export AWS_SECRET_ACCESS_KEY=$(echo $CREDENTIALS | cut -d' ' -f2)
export AWS_SESSION_TOKEN=$(echo $CREDENTIALS | cut -d' ' -f3)

echo "Cross-account role assumed successfully!"
echo "Session expires in 1 hour"
```

### **2. Python SDK Example**
```python
import boto3
from botocore.exceptions import ClientError

def assume_cross_account_role():
    sts_client = boto3.client('sts')
    
    try:
        response = sts_client.assume_role(
            RoleArn='arn:aws:iam::ACCOUNT-B-ID:role/CrossAccountAccessRole',
            RoleSessionName='imran-python-session'
        )
        
        credentials = response['Credentials']
        
        # Create new session with assumed role credentials
        session = boto3.Session(
            aws_access_key_id=credentials['AccessKeyId'],
            aws_secret_access_key=credentials['SecretAccessKey'],
            aws_session_token=credentials['SessionToken']
        )
        
        # Use the session to access Account B resources
        ec2 = session.client('ec2')
        instances = ec2.describe_instances()
        
        return instances
        
    except ClientError as e:
        print(f"Error assuming role: {e}")
        return None
```

---

## **Testing Checklist**

### **✅ Pre-Implementation**
- [ ] Verify account IDs are correct
- [ ] Confirm user `imran.shaikh` exists in Account A
- [ ] Check required permissions in both accounts

### **✅ Post-Implementation**
- [ ] Test role assumption from CLI
- [ ] Verify resource access works
- [ ] Check CloudTrail logs for activities
- [ ] Test MFA requirements (if enabled)
- [ ] Validate session expiration

### **✅ Security Validation**
- [ ] Confirm least privilege access
- [ ] Test with invalid credentials
- [ ] Verify IP restrictions (if configured)
- [ ] Check external ID validation

---

## **Quick Reference Commands**

```bash
# List assumable roles
aws iam list-roles --query 'Roles[?contains(AssumeRolePolicyDocument, `imran.shaikh`)].RoleName'

# Check current identity
aws sts get-caller-identity

# List MFA devices
aws iam list-mfa-devices --user-name imran.shaikh

# Decode authorization message
aws sts decode-authorization-message --encoded-message <encoded-message>
```

---

This guide provides comprehensive coverage of AWS cross-account access scenarios specifically configured for user `imran.shaikh`. Each scenario includes practical examples, security considerations, and troubleshooting steps.