# Task 6: AI-Powered AWS Inventory Automation System (Production)

**Created by:** Imran Shaikh  
**Date:** December 2024  
**Architecture:** Fully Automated with Lambda, DynamoDB, EventBridge, and Bedrock

## Production Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    EventBridge Rule                          │
│              (Daily at 2 AM UTC - cron)                      │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│              Lambda: Inventory Collector                     │
│  • Scans EC2, RDS, S3, Lambda, EKS                          │
│  • Collects metadata and metrics                            │
│  • Checks EOL dates                                          │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                  DynamoDB Table                              │
│  • Stores inventory data                                     │
│  • Tracks historical changes                                 │
│  • Enables querying and analysis                             │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│              Lambda: AI Analyzer                             │
│  • Analyzes inventory with Bedrock                           │
│  • Generates recommendations                                 │
│  • Detects anomalies                                         │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                    SNS Topic                                 │
│  • Email notifications                                       │
│  • Critical alerts                                           │
│  • Daily summary reports                                     │
└─────────────────────────────────────────────────────────────┘
```

## Components

### 1. Lambda Functions
- **Collector**: Discovers AWS resources (Python 3.12)
- **Analyzer**: AI-powered analysis with Bedrock (Python 3.12)

### 2. DynamoDB
- **Table**: aws-inventory
- **Keys**: resource_id (HASH), timestamp (RANGE)
- **Billing**: PAY_PER_REQUEST

### 3. EventBridge
- **Schedule**: Daily at 2 AM UTC
- **Target**: Collector Lambda

### 4. SNS
- **Topic**: inventory-alerts
- **Subscribers**: Email notifications

### 5. IAM Roles
- **Collector Role**: Read access to all AWS services
- **Analyzer Role**: DynamoDB + Bedrock access

## Project Structure

```
Task6/
├── lambda/
│   ├── collector/
│   │   ├── lambda_function.py      # Main collector
│   │   └── requirements.txt
│   └── analyzer/
│       ├── lambda_function.py      # AI analyzer
│       └── requirements.txt
├── terraform/
│   ├── main.tf                     # Main infrastructure
│   ├── variables.tf
│   ├── outputs.tf
│   └── lambda.tf                   # Lambda resources
├── docs/
│   ├── ARCHITECTURE.md
│   ├── DEPLOYMENT.md
│   └── API.md
├── screenshots/
├── deploy.sh                       # Deployment script
└── README.md
```

## Quick Deployment

```bash
cd /home/einfochips/TrainingPlanNew/Tasks/TASKS-Dec15/Task6

# Deploy infrastructure
cd terraform
terraform init
terraform apply -auto-approve

# Deploy Lambda functions
cd ..
./deploy.sh
```

## Features

### ✅ Automated Discovery
- EC2 instances with utilization metrics
- RDS databases with engine versions
- S3 buckets with lifecycle policies
- Lambda functions with runtime info
- EKS clusters with K8s versions

### ✅ FinOps Intelligence
- Stopped instance detection
- Underutilized resources
- Missing lifecycle policies
- Cost optimization opportunities

### ✅ EOS/EOL Tracking
- AMI deprecation warnings
- RDS engine EOL dates
- Lambda runtime deprecation
- Kubernetes version EOL

### ✅ AI-Powered Analysis
- Amazon Bedrock (Claude 3 Sonnet)
- Natural language insights
- Predictive recommendations
- Anomaly detection

### ✅ Automated Alerting
- Email notifications via SNS
- Critical issue alerts
- Daily summary reports
- Custom alert rules

## Cost Estimate

| Service | Monthly Cost |
|---------|-------------|
| Lambda (Collector) | $2-5 |
| Lambda (Analyzer) | $1-3 |
| DynamoDB | $5-10 |
| EventBridge | $0 (free tier) |
| SNS | $0-1 |
| **Total** | **$8-19/month** |

## Deployment Steps

### Step 1: Prerequisites
```bash
# Install Terraform
terraform --version

# Configure AWS CLI
aws configure

# Verify permissions
aws sts get-caller-identity
```

### Step 2: Deploy Infrastructure
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### Step 3: Package Lambda Functions
```bash
cd ../lambda/collector
pip install -r requirements.txt -t .
zip -r collector.zip .

cd ../analyzer
pip install -r requirements.txt -t .
zip -r analyzer.zip .
```

### Step 4: Deploy Lambda Code
```bash
aws lambda update-function-code \
  --function-name inventory-collector \
  --zip-file fileb://collector.zip

aws lambda update-function-code \
  --function-name inventory-analyzer \
  --zip-file fileb://analyzer.zip
```

### Step 5: Subscribe to SNS
```bash
aws sns subscribe \
  --topic-arn arn:aws:sns:us-east-1:ACCOUNT:inventory-alerts \
  --protocol email \
  --notification-endpoint your-email@example.com
```

## Testing

### Manual Trigger
```bash
# Trigger collector
aws lambda invoke \
  --function-name inventory-collector \
  --payload '{}' \
  response.json

# Trigger analyzer
aws lambda invoke \
  --function-name inventory-analyzer \
  --payload '{}' \
  response.json
```

### Check DynamoDB
```bash
aws dynamodb scan \
  --table-name aws-inventory \
  --max-items 10
```

### View Logs
```bash
aws logs tail /aws/lambda/inventory-collector --follow
aws logs tail /aws/lambda/inventory-analyzer --follow
```

## Monitoring

- **CloudWatch Logs**: Lambda execution logs
- **CloudWatch Metrics**: Invocation count, duration, errors
- **DynamoDB Metrics**: Read/write capacity, item count
- **SNS Metrics**: Notification delivery status

## Cleanup

```bash
cd terraform
terraform destroy -auto-approve
```

## Next Steps

1. Review deployment in AWS Console
2. Check email for SNS confirmation
3. Wait for first scheduled run (2 AM UTC)
4. Review inventory in DynamoDB
5. Check email for analysis report

---

**Status**: Production-Ready Automated System  
**Maintenance**: Minimal - fully serverless  
**Scalability**: Handles 1000+ resources
