# Lab 1: AWS CloudTrail

## What is CloudTrail?
AWS CloudTrail is a service that enables governance, compliance, operational auditing, and risk auditing of your AWS account. It logs all API calls made in your AWS account.

## Why Use CloudTrail?
- **Security Analysis**: Track who did what and when
- **Compliance**: Meet regulatory requirements
- **Troubleshooting**: Debug operational issues
- **Change Tracking**: Monitor resource changes

## Where is it Used?
- Security monitoring and incident response
- Compliance auditing
- Operational troubleshooting
- Resource change tracking

## Resources Created
- S3 bucket for CloudTrail logs
- CloudTrail with multi-region logging
- Log file validation enabled
- API call rate insights enabled

## Deployment

```bash
terraform init
terraform plan
terraform apply -auto-approve
```

## What to Observe After Deployment

### 1. CloudTrail Status
```bash
# Check trail status
aws cloudtrail get-trail-status --name cloudops-trail

# Expected output: IsLogging: true
```

### 2. View Recent Events
```bash
# List recent events
aws cloudtrail lookup-events --max-items 10

# Filter by event name
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=CreateBucket
```

### 3. Check S3 Bucket
```bash
# List CloudTrail logs in S3
aws s3 ls s3://$(terraform output -raw s3_bucket_name)/ --recursive

# Download a log file
aws s3 cp s3://$(terraform output -raw s3_bucket_name)/AWSLogs/ . --recursive
```

### 4. Verify Log File Validation
```bash
# Validate log files
aws cloudtrail validate-logs \
  --trail-arn $(terraform output -raw cloudtrail_arn) \
  --start-time 2024-01-01T00:00:00Z
```

## Testing

### Test 1: Generate Events
```bash
# Create an S3 bucket (generates CloudTrail event)
aws s3 mb s3://test-bucket-$(date +%s)

# Wait 5-10 minutes for logs to appear
sleep 300

# Check for the event
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=CreateBucket \
  --max-items 5
```

### Test 2: Monitor API Calls
```bash
# Make several API calls
aws ec2 describe-instances
aws s3 ls
aws iam list-users

# Query CloudTrail
aws cloudtrail lookup-events --max-items 20
```

### Test 3: Check Insights
```bash
# View CloudTrail insights (unusual API activity)
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=RunInstances
```

## Key Observations

1. **Log Delivery Time**: 5-15 minutes after API call
2. **Log Format**: JSON files in S3
3. **Log Organization**: By region, account, date
4. **Event Types**: Management events, data events, insights

## Troubleshooting

### Issue: No logs appearing
```bash
# Check trail status
aws cloudtrail get-trail-status --name cloudops-trail

# Verify S3 bucket policy
aws s3api get-bucket-policy --bucket $(terraform output -raw s3_bucket_name)
```

### Issue: Access denied
```bash
# Check IAM permissions
aws iam get-user
aws sts get-caller-identity
```

## Cleanup
```bash
terraform destroy -auto-approve
```

## Cost Considerations
- First trail: Free
- Additional trails: $2.00 per 100,000 events
- S3 storage: Standard S3 pricing
- Data events: $0.10 per 100,000 events
