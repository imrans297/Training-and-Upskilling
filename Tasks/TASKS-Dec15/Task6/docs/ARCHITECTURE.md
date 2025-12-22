# Task 6: Architecture Documentation

## System Overview

The AI-Powered AWS Inventory Automation System is a fully serverless solution that automatically discovers, tracks, and analyzes AWS infrastructure resources with intelligent recommendations.

---

## Architecture Diagram

```
                    ┌─────────────────────────────┐
                    │   EventBridge Scheduler     │
                    │   (cron: 0 2 * * ? *)      │
                    └──────────────┬──────────────┘
                                   │
                                   │ Trigger Daily
                                   ▼
                    ┌─────────────────────────────┐
                    │  Lambda: Collector          │
                    │  Runtime: Python 3.12       │
                    │  Memory: 512 MB             │
                    │  Timeout: 5 min             │
                    └──────────────┬──────────────┘
                                   │
                    ┌──────────────┼──────────────┐
                    │              │              │
                    ▼              ▼              ▼
            ┌───────────┐  ┌───────────┐  ┌───────────┐
            │    EC2    │  │    RDS    │  │    S3     │
            │  Lambda   │  │    EKS    │  │  Others   │
            └───────────┘  └───────────┘  └───────────┘
                    │              │              │
                    └──────────────┼──────────────┘
                                   │
                                   │ Store Data
                                   ▼
                    ┌─────────────────────────────┐
                    │   DynamoDB: aws-inventory   │
                    │   Mode: PAY_PER_REQUEST     │
                    │   Keys: resource_id + time  │
                    └──────────────┬──────────────┘
                                   │
                                   │ Query Data
                                   ▼
                    ┌─────────────────────────────┐
                    │  Lambda: Analyzer           │
                    │  Runtime: Python 3.12       │
                    │  Memory: 256 MB             │
                    │  Timeout: 1 min             │
                    └──────────────┬──────────────┘
                                   │
                    ┌──────────────┼──────────────┐
                    │              │              │
                    ▼              ▼              ▼
            ┌───────────┐  ┌───────────┐  ┌───────────┐
            │  Bedrock  │  │ Analysis  │  │   SNS     │
            │  Claude   │  │  Logic    │  │  Alerts   │
            └───────────┘  └───────────┘  └─────┬─────┘
                                                 │
                                                 │ Email
                                                 ▼
                                          ┌─────────────┐
                                          │    User     │
                                          └─────────────┘
```

---

## Component Details

### 1. EventBridge Scheduler

**Purpose**: Trigger automated scans on schedule

**Configuration:**
- Schedule: `cron(0 2 * * ? *)` (Daily at 2 AM UTC)
- Target: inventory-collector Lambda
- Retry: 2 attempts on failure

**Why EventBridge?**
- Serverless scheduling
- No infrastructure to manage
- Built-in retry logic
- Free tier covers usage

---

### 2. Lambda: Inventory Collector

**Purpose**: Discover and collect AWS resource metadata

**Specifications:**
- Runtime: Python 3.12
- Memory: 512 MB
- Timeout: 300 seconds (5 minutes)
- Concurrent Executions: 1 (sequential scans)

**Resources Scanned:**
1. **EC2 Instances**
   - Instance type, state, AMI
   - Launch date, tags
   - VPC, AZ placement

2. **RDS Databases**
   - Engine, version
   - Instance class, storage
   - Multi-AZ, backup retention

3. **S3 Buckets**
   - Versioning status
   - Lifecycle policies
   - Creation date

4. **Lambda Functions**
   - Runtime version
   - Memory, timeout
   - Last modified date

5. **EKS Clusters**
   - Kubernetes version
   - Status, endpoint
   - Creation date

**Data Flow:**
```
AWS APIs → boto3 → Collector Logic → DynamoDB
```

**Error Handling:**
- Try-catch per service
- Logs errors to CloudWatch
- Continues on partial failures

---

### 3. DynamoDB Table

**Purpose**: Persistent storage for inventory data

**Schema:**
```
Primary Key:
  - HASH: resource_id (String)
  - RANGE: timestamp (String)

Global Secondary Index:
  - HASH: scan_date (String)
  - Projection: ALL

Attributes:
  - resource_type (String)
  - name (String)
  - state (String)
  - recommendations (List)
  - tags (Map)
  - ... (dynamic attributes)
```

**Billing Mode:** PAY_PER_REQUEST
- No capacity planning needed
- Scales automatically
- Pay only for actual usage

**Data Retention:**
- No automatic expiration
- Manual cleanup recommended
- Consider TTL for old data

---

### 4. Lambda: AI Analyzer

**Purpose**: Analyze inventory with AI and generate insights

**Specifications:**
- Runtime: Python 3.12
- Memory: 256 MB
- Timeout: 60 seconds
- Trigger: After collector completes

**Analysis Features:**

1. **AI-Powered Insights (Bedrock)**
   - Model: Claude 3 Sonnet
   - Max Tokens: 1000
   - Prompt: FinOps expert analysis

2. **Rule-Based Analysis (Fallback)**
   - Stopped instance detection
   - EOL date checking
   - Missing configuration alerts

3. **Summary Generation**
   - Resource counts by type
   - Critical issue identification
   - Cost optimization opportunities

**Data Flow:**
```
DynamoDB → Analyzer Logic → Bedrock API → SNS
```

---

### 5. Amazon Bedrock Integration

**Purpose**: AI-powered analysis and recommendations

**Model:** anthropic.claude-3-sonnet-20240229-v1:0

**Prompt Template:**
```
You are an AWS FinOps expert. Analyze this infrastructure inventory and provide:

1. Top 3 cost optimization opportunities
2. Critical EOS/EOL warnings
3. Compliance issues
4. Actionable recommendations

Inventory Summary:
{json_data}

Be concise and prioritize by impact.
```

**Response Format:**
- Natural language insights
- Prioritized recommendations
- Estimated cost savings
- Risk assessments

**Fallback Strategy:**
- If Bedrock unavailable: Use rule-based analysis
- If quota exceeded: Queue for retry
- If model error: Log and continue

---

### 6. SNS Topic & Alerts

**Purpose**: Notify users of critical findings

**Topic:** inventory-alerts

**Subscription Types:**
- Email (primary)
- SMS (optional)
- Lambda (optional - for automation)

**Alert Triggers:**
- Stopped EC2 instances found
- EOL warnings detected
- Critical compliance issues
- Daily summary report

**Message Format:**
```
Subject: AWS Inventory Alert - X Resources Scanned

Body:
AWS Infrastructure Analysis Report
Generated: YYYY-MM-DD HH:MM UTC

SUMMARY:
- Total Resources: X
- Resource Types: ...

CRITICAL FINDINGS:
- Stopped EC2: X
- EOL Warnings: X

TOP RECOMMENDATIONS:
1. ...
2. ...
3. ...
```

---

## Data Flow

### Collection Flow
```
1. EventBridge triggers Collector Lambda
2. Collector calls AWS APIs (EC2, RDS, S3, etc.)
3. Collector processes and enriches data
4. Collector stores in DynamoDB
5. Collector returns success/failure
```

### Analysis Flow
```
1. Collector completion triggers Analyzer
2. Analyzer queries DynamoDB for today's scan
3. Analyzer generates summary statistics
4. Analyzer calls Bedrock for AI insights
5. Analyzer publishes to SNS topic
6. SNS delivers email to subscribers
```

---

## Security Architecture

### IAM Roles

**Collector Role Permissions:**
- `ec2:Describe*` - Read EC2 metadata
- `rds:Describe*` - Read RDS metadata
- `s3:List*`, `s3:GetBucket*` - Read S3 metadata
- `lambda:List*` - Read Lambda metadata
- `eks:List*`, `eks:Describe*` - Read EKS metadata
- `dynamodb:PutItem` - Write to inventory table
- `logs:*` - CloudWatch logging

**Analyzer Role Permissions:**
- `dynamodb:Scan`, `dynamodb:Query` - Read inventory
- `bedrock:InvokeModel` - AI analysis
- `sns:Publish` - Send alerts
- `logs:*` - CloudWatch logging

### Network Security
- All Lambda functions in AWS VPC (optional)
- No public endpoints
- AWS PrivateLink for service access
- Encryption in transit (TLS)

### Data Security
- DynamoDB encryption at rest (default)
- CloudWatch Logs encryption
- SNS message encryption
- No sensitive data in logs

---

## Scalability

### Current Limits
- **Resources**: Handles 1000+ per scan
- **Scan Duration**: 5 minutes max
- **Concurrent Scans**: 1 (sequential)
- **Data Storage**: Unlimited (DynamoDB)

### Scaling Strategies

**Horizontal Scaling:**
- Multi-region deployment
- Parallel Lambda invocations
- Sharded DynamoDB tables

**Vertical Scaling:**
- Increase Lambda memory
- Extend timeout limits
- Optimize boto3 calls

**Cost Optimization:**
- Reserved capacity for DynamoDB
- Lambda provisioned concurrency
- S3 lifecycle for old data

---

## Monitoring & Observability

### CloudWatch Metrics

**Lambda Metrics:**
- Invocations
- Duration
- Errors
- Throttles
- Concurrent Executions

**DynamoDB Metrics:**
- Read/Write Capacity
- Item Count
- Throttled Requests
- Latency

**Custom Metrics:**
- Resources scanned per run
- EOL warnings detected
- Cost savings identified

### CloudWatch Logs

**Log Groups:**
- `/aws/lambda/inventory-collector`
- `/aws/lambda/inventory-analyzer`

**Log Retention:** 7 days (configurable)

### Alarms

**Critical Alarms:**
- Lambda errors > 5%
- Lambda duration > 4 minutes
- DynamoDB throttling
- SNS delivery failures

---

## Cost Optimization

### Current Costs (Monthly)
- Lambda: $3-5
- DynamoDB: $5-10
- CloudWatch: $1
- SNS: $0 (free tier)
- **Total: $9-16/month**

### Optimization Tips
1. Use DynamoDB on-demand pricing
2. Set CloudWatch log retention to 7 days
3. Limit S3 bucket scanning (top 10)
4. Use Bedrock only for critical analysis
5. Batch DynamoDB writes

---

## Disaster Recovery

### Backup Strategy
- DynamoDB: Point-in-time recovery enabled
- Lambda: Code in version control
- Terraform: State in S3 backend

### Recovery Procedures
1. Restore DynamoDB from backup
2. Redeploy Lambda from code
3. Recreate infrastructure with Terraform

### RTO/RPO
- **RTO**: 30 minutes (redeploy time)
- **RPO**: 24 hours (daily scans)

---

## Future Enhancements

1. **Multi-Region Support**
   - Scan all AWS regions
   - Aggregate data centrally

2. **Multi-Account Support**
   - Cross-account role assumption
   - Consolidated inventory

3. **Web Dashboard**
   - React frontend
   - Real-time visualization
   - Historical trends

4. **Advanced AI**
   - Predictive cost analysis
   - Anomaly detection
   - Auto-remediation

5. **Integration**
   - ServiceNow CMDB sync
   - Jira ticket creation
   - Slack notifications

---

**Architecture Status**: Production-Ready  
**Last Updated**: December 2024  
**Version**: 1.0
