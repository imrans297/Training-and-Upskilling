# Lab 1: AWS CloudTrail - Console Manual Steps

## Step 1: Create S3 Bucket

1. **Go to S3 Console**
2. **Create bucket**
3. **Configure:**
   - **Name**: `cloudops-cloudtrail-logs-unique`
   - **Region**: us-east-1
   - **Block all public access**: ☑️ Enabled
4. **Create bucket**

## Step 2: Create CloudTrail

1. **Go to CloudTrail Console**
2. **Trails** → **Create trail**
3. **Trail attributes:**
   - **Trail name**: `cloudops-trail`
   - **Storage location**: Use existing S3 bucket
   - **S3 bucket**: Select `cloudops-cloudtrail-logs-unique`
4. **Log file SSE-KMS encryption**: Optional
5. **Log file validation**: ☑️ **Enabled**
6. **SNS notification delivery**: Optional
7. **CloudWatch Logs**: Optional

## Step 3: Choose Log Events

1. **Management events:**
   - ☑️ **Read**
   - ☑️ **Write**
2. **Data events**: Skip for now
3. **Insights events:**
   - ☑️ **API call rate**
4. **Next**

## Step 4: Review and Create

1. **Review configuration**
2. **Create trail**

## Step 5: Verify Trail is Logging

1. **Select trail** → **cloudops-trail**
2. **General details** → **Logging**: Should show **ON**
3. **Event history** tab → View recent events

## Testing After Creation

### Test 1: View Event History

1. **CloudTrail Console** → **Event history**
2. **Filter events:**
   - **Event name**: CreateBucket
   - **Time range**: Last hour
3. **Click event** to see details

### Test 2: Generate Test Events

1. **Create an S3 bucket** (any name)
2. **Wait 5-10 minutes**
3. **Go to CloudTrail** → **Event history**
4. **Search for CreateBucket event**
5. **Verify event details:**
   - User identity
   - Source IP
   - Request parameters
   - Response elements

### Test 3: Check S3 Logs

1. **Go to S3 Console**
2. **Open bucket**: `cloudops-cloudtrail-logs-unique`
3. **Navigate**: AWSLogs → [Account-ID] → CloudTrail → [Region] → [Year] → [Month] → [Day]
4. **Download log file** (JSON format)
5. **Open and inspect** log entries

### Test 4: Query Events

1. **CloudTrail Console** → **Event history**
2. **Lookup attributes:**
   - **Select**: Event name
   - **Enter**: RunInstances
3. **Apply filter**
4. **View matching events**

## What to Observe

### 1. Trail Configuration
- **Status**: Logging enabled
- **Multi-region**: Yes
- **Log file validation**: Enabled
- **S3 bucket**: Configured correctly

### 2. Event Details
Each event shows:
- **Event time**: When it occurred
- **User name**: Who made the call
- **Event name**: API action
- **Resource type**: Affected resource
- **Event source**: AWS service

### 3. Log Files in S3
- **Path structure**: Organized by date
- **File format**: Gzipped JSON
- **Delivery time**: 5-15 minutes
- **File naming**: Includes timestamp and digest

### 4. Insights
- **Unusual API activity**: Detected automatically
- **API call rate changes**: Highlighted
- **Baseline comparison**: Against normal activity

## Common Observations

1. **High-volume events**: S3 GetObject, EC2 DescribeInstances
2. **Console logins**: ConsoleLogin events
3. **IAM changes**: CreateUser, AttachUserPolicy
4. **Resource creation**: RunInstances, CreateBucket

## Troubleshooting

### Issue: Trail not logging
**Check:**
1. Trail status is ON
2. S3 bucket policy allows CloudTrail
3. IAM permissions are correct

### Issue: No events visible
**Check:**
1. Wait 15 minutes for log delivery
2. Correct region selected
3. Time range filter

### Issue: Cannot access logs
**Check:**
1. S3 bucket permissions
2. IAM user has S3 read access
3. Bucket policy allows your account

## Cleanup

1. **CloudTrail Console** → **Trails**
2. **Select cloudops-trail**
3. **Delete trail**
4. **Confirm deletion**
5. **Go to S3** → Delete bucket
6. **Empty bucket first**, then delete

## Key Takeaways

- CloudTrail logs ALL API calls
- Logs delivered to S3 within 15 minutes
- Multi-region trail captures all regions
- Log file validation ensures integrity
- First trail is free
- Essential for security and compliance
