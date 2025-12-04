# Task 1: Event-Driven AMI Backup Automation for GDP-Web Applications

## Overview
This task implements an event-driven Lambda function that automatically detects when an AMI backup is created for GDP-Web applications (gdp-web-1, gdp-web-2, gdp-web-3) and returns the latest AMI for that specific application.

## Architecture Components

### 1. EC2 Instances
- **gdp-web-1**: Instance ID varies (tagged with Application=gdp-web-1)
- **gdp-web-2**: Instance ID varies (tagged with Application=gdp-web-2)
- **gdp-web-3**: Instance ID varies (tagged with Application=gdp-web-3)

### 2. Lambda Function
- **Function Name**: `gdp-web-event-driven-ami`
- **Runtime**: Python 3.11
- **Trigger**: EventBridge (CloudTrail CreateImage event)
- **Purpose**: Fetch latest AMI for the specific application that triggered the event

### 3. EventBridge Rule
- **Rule Name**: `gdp-web-ami-creation-rule`
- **Event Source**: AWS CloudTrail
- **Event Type**: CreateImage API call
- **Target**: Lambda function

### 4. AMI Naming Convention
- **Pattern**: `{application}-{timestamp}`
- **Examples**:
  - `gdp-web-1-2025-12-03-20-16`
  - `gdp-web-2-2025-12-03-20-17`
  - `gdp-web-3-2025-12-03-20-18`

---

## Lambda Function Code

### Event-Driven Lambda (event-driven-lambda.py)
```python
import boto3
import json
from datetime import datetime

def lambda_handler(event, context):
    """
    Event-driven Lambda: Triggered when AMI backup is created
    Returns latest AMI only for the specific application that triggered the event
    """
    print(f"Lambda triggered with event: {json.dumps(event)}")
    ec2 = boto3.client('ec2')
    
    try:
        # Extract AMI ID from EventBridge event
        ami_id = event['detail']['responseElements']['imageId']
        
        # Get AMI details to identify which application it belongs to
        response = ec2.describe_images(ImageIds=[ami_id])
        
        if not response['Images']:
            return {
                'statusCode': 404,
                'message': 'AMI not found'
            }
        
        ami_info = response['Images'][0]
        ami_name = ami_info['Name']
        
        # Determine which GDP-Web application this AMI belongs to
        app_name = None
        if ami_name.startswith('gdp-web-1-'):
            app_name = 'gdp-web-1'
        elif ami_name.startswith('gdp-web-2-'):
            app_name = 'gdp-web-2'
        elif ami_name.startswith('gdp-web-3-'):
            app_name = 'gdp-web-3'
        
        if not app_name:
            return {
                'statusCode': 400,
                'message': f'AMI {ami_name} does not match GDP-Web naming pattern'
            }
        
        # Get latest AMI for this specific application
        app_response = ec2.describe_images(
            Owners=['self'],
            Filters=[
                {'Name': 'name', 'Values': [f'{app_name}-*']},
                {'Name': 'state', 'Values': ['available']}
            ]
        )
        
        if app_response['Images']:
            # Sort by creation date, get latest
            latest_ami = sorted(
                app_response['Images'],
                key=lambda x: x['CreationDate'],
                reverse=True
            )[0]
            
            result = {
                'statusCode': 200,
                'triggered_by_ami': ami_id,
                'application': app_name,
                'latest_ami': {
                    'ami_id': latest_ami['ImageId'],
                    'ami_name': latest_ami['Name'],
                    'creation_date': latest_ami['CreationDate'],
                    'is_new_backup': latest_ami['ImageId'] == ami_id
                },
                'timestamp': datetime.utcnow().isoformat() + 'Z'
            }
            print(f"Lambda result: {json.dumps(result, default=str)}")
            return result
        else:
            return {
                'statusCode': 404,
                'message': f'No AMIs found for {app_name}'
            }
            
    except KeyError as e:
        return {
            'statusCode': 400,
            'message': f'Invalid event structure: {str(e)}'
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'message': f'Error: {str(e)}'
        }
```

### Manual Fetch Lambda (task1-lambda-latest-ami.py)
```python
import boto3
import json
from datetime import datetime

def lambda_handler(event, context):
    """
    Task 1: Lambda function to get latest AMI for each GDP-Web application
    Returns the most recent AMI backup for gdp-web-1, gdp-web-2, gdp-web-3
    """
    ec2 = boto3.client('ec2')
    
    apps = ['gdp-web-1', 'gdp-web-2', 'gdp-web-3']
    result = {}
    
    for app in apps:
        try:
            # Get AMIs for this application
            response = ec2.describe_images(
                Owners=['self'],
                Filters=[
                    {'Name': 'name', 'Values': [f'{app}-*']},
                    {'Name': 'state', 'Values': ['available']}
                ]
            )
            
            if response['Images']:
                # Sort by creation date, get latest
                latest_ami = sorted(
                    response['Images'], 
                    key=lambda x: x['CreationDate'], 
                    reverse=True
                )[0]
                
                result[app] = {
                    'ami_id': latest_ami['ImageId'],
                    'name': latest_ami['Name'],
                    'creation_date': latest_ami['CreationDate'],
                    'status': 'found'
                }
            else:
                result[app] = {
                    'status': 'no_ami_found',
                    'message': f'No available AMI found for {app}'
                }
                
        except Exception as e:
            result[app] = {
                'status': 'error',
                'message': str(e)
            }
    
    return {
        'statusCode': 200,
        'body': result,
        'timestamp': datetime.utcnow().isoformat() + 'Z'
    }
```

---

## IAM Policies

### Lambda Execution Role: `gdp-web-event-lambda-role`

#### Basic Lambda Execution Policy (AWS Managed)
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:*:*:*"
        }
    ]
}
```

#### EC2 Image Access Policy
**Policy Name**: `EC2ImageAccess`

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeImages"
            ],
            "Resource": "*"
        }
    ]
}
```

---

## EventBridge Rule Configuration

### Event Pattern
```json
{
    "source": ["aws.ec2"],
    "detail-type": ["AWS API Call via CloudTrail"],
    "detail": {
        "eventSource": ["ec2.amazonaws.com"],
        "eventName": ["CreateImage"],
        "responseElements": {
            "imageId": [{"exists": true}]
        }
    }
}
```

### Target Configuration
- **Target Type**: Lambda function
- **Function ARN**: `arn:aws:lambda:{region}:{account-id}:function:gdp-web-event-driven-ami`
- **Target ID**: 1

---

## Deployment Commands

### 1. Deploy Event-Driven Lambda
```bash
cd /home/einfochips/TrainingPlanNew/Tasks/gdp-web-ami-asg-scaling
bash deploy-event-lambda.sh
```

This script will:
- Create IAM role `gdp-web-event-lambda-role`
- Attach necessary policies
- Deploy Lambda function `gdp-web-event-driven-ami`
- Create EventBridge rule `gdp-web-ami-creation-rule`
- Configure Lambda trigger

### 2. Create AMI Backups for All GDP-Web Instances
```bash
bash task1-create-ami-backups.sh
```

This will:
- Find all running GDP-Web instances (gdp-web-1, gdp-web-2, gdp-web-3)
- Create AMI backups with naming convention: `{app-name}-{timestamp}`
- Tag AMIs appropriately
- Automatically trigger Lambda via EventBridge

---

## Testing

### 1. Create Manual AMI Backup (Triggers Lambda Automatically)
```bash
# For gdp-web-1
INSTANCE_ID="i-xxxxxxxxx"  # Replace with actual instance ID
AMI_NAME="gdp-web-1-$(date +%Y-%m-%d-%H-%M)"
AMI_ID=$(aws ec2 create-image \
    --instance-id $INSTANCE_ID \
    --name "$AMI_NAME" \
    --description "AMI backup for gdp-web-1" \
    --no-reboot \
    --query 'ImageId' \
    --output text)

echo "Created AMI: $AMI_ID"
echo "AMI Name: $AMI_NAME"

# Tag the AMI
aws ec2 create-tags \
    --resources $AMI_ID \
    --tags Key=Name,Value="$AMI_NAME" Key=Application,Value="gdp-web-1"

# Wait for Lambda to process (2-3 minutes)
sleep 180

# Check Lambda logs
aws logs tail /aws/lambda/gdp-web-event-driven-ami --since 5m --format short
```

### 2. Manual Lambda Invocation (Testing)
```bash
# Test with specific AMI ID
aws lambda invoke \
    --function-name gdp-web-event-driven-ami \
    --payload '{"detail":{"responseElements":{"imageId":"ami-035acc1319ac2b971"}}}' \
    result.json

# View result
cat result.json
```

### 3. Check Lambda Logs
```bash
# View recent logs
bash check-lambda-logs.sh

# Or manually
aws logs tail /aws/lambda/gdp-web-event-driven-ami --since 10m --format short

# Follow logs in real-time
aws logs tail /aws/lambda/gdp-web-event-driven-ami --follow
```

### 4. List All GDP-Web AMIs
```bash
# List all AMIs for all applications
aws ec2 describe-images \
    --owners self \
    --filters "Name=name,Values=gdp-web-*" \
    --query 'Images | sort_by(@, &CreationDate)[*].[Name,ImageId,CreationDate,State]' \
    --output table

# List AMIs for specific application
aws ec2 describe-images \
    --owners self \
    --filters "Name=name,Values=gdp-web-1-*" \
    --query 'Images | sort_by(@, &CreationDate)[*].[Name,ImageId,CreationDate,State]' \
    --output table
```

### 5. Verify EventBridge Rule
```bash
# Check rule status
aws events describe-rule --name gdp-web-ami-creation-rule

# List targets
aws events list-targets-by-rule --rule gdp-web-ami-creation-rule
```

---

## Expected Lambda Output

### Successful Execution
```json
{
    "statusCode": 200,
    "triggered_by_ami": "ami-081f167ed7c626683",
    "application": "gdp-web-1",
    "latest_ami": {
        "ami_id": "ami-081f167ed7c626683",
        "ami_name": "gdp-web-1-2025-12-03-20-16",
        "creation_date": "2025-12-03T14:47:00.000Z",
        "is_new_backup": true
    },
    "timestamp": "2025-12-03T14:47:05Z"
}
```

### AMI Not Found
```json
{
    "statusCode": 404,
    "message": "AMI not found"
}
```

### Invalid Naming Pattern
```json
{
    "statusCode": 400,
    "message": "AMI my-custom-ami does not match GDP-Web naming pattern"
}
```

---

## Workflow

1. **User creates AMI backup** for any GDP-Web instance (gdp-web-1, gdp-web-2, or gdp-web-3)
2. **CloudTrail logs** the CreateImage API call
3. **EventBridge detects** the event and triggers Lambda
4. **Lambda extracts** the AMI ID from the event
5. **Lambda identifies** which application (gdp-web-1/2/3) the AMI belongs to
6. **Lambda fetches** all AMIs for that specific application
7. **Lambda returns** the latest AMI for that application
8. **Result includes**:
   - Triggered AMI ID
   - Application name
   - Latest AMI details
   - Whether the triggered AMI is the latest

---

## Instance Setup (GDP-Web Applications)

### GDP-Web-1 Instance
```bash
# User data script
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd

echo "<h1>GDP-Web-1 Application</h1>" > /var/www/html/index.html
echo "<p>Instance ID: $(ec2-metadata --instance-id | cut -d' ' -f2)</p>" >> /var/www/html/index.html
```

### GDP-Web-2 Instance
```bash
# User data script
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd

echo "<h1>GDP-Web-2 Application</h1>" > /var/www/html/index.html
echo "<p>Instance ID: $(ec2-metadata --instance-id | cut -d' ' -f2)</p>" >> /var/www/html/index.html
```

### GDP-Web-3 Instance
```bash
# User data script
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd

echo "<h1>GDP-Web-3 Application</h1>" > /var/www/html/index.html
echo "<p>Instance ID: $(ec2-metadata --instance-id | cut -d' ' -f2)</p>" >> /var/www/html/index.html
```

### Instance Tags (Required)
```bash
# Tag instances for identification
aws ec2 create-tags \
    --resources i-xxxxxxxxx \
    --tags Key=Name,Value="gdp-web-1" Key=Application,Value="gdp-web-1"

aws ec2 create-tags \
    --resources i-yyyyyyyyy \
    --tags Key=Name,Value="gdp-web-2" Key=Application,Value="gdp-web-2"

aws ec2 create-tags \
    --resources i-zzzzzzzzz \
    --tags Key=Name,Value="gdp-web-3" Key=Application,Value="gdp-web-3"
```

---

## Troubleshooting

### Issue 1: Lambda Not Triggered
**Cause**: CloudTrail not enabled or EventBridge rule misconfigured

**Solution**:
```bash
# Verify CloudTrail is enabled
aws cloudtrail describe-trails

# Check EventBridge rule
aws events describe-rule --name gdp-web-ami-creation-rule

# Verify Lambda has EventBridge permission
aws lambda get-policy --function-name gdp-web-event-driven-ami
```

### Issue 2: Lambda Returns 404
**Cause**: AMI naming doesn't match pattern or AMI not yet available

**Solution**:
- Ensure AMI name starts with `gdp-web-1-`, `gdp-web-2-`, or `gdp-web-3-`
- Wait 2-3 minutes for AMI to become available
- Check AMI state: `aws ec2 describe-images --image-ids ami-xxxxx`

### Issue 3: Wrong Application Detected
**Cause**: AMI naming convention not followed

**Solution**:
- Use strict naming: `gdp-web-{1|2|3}-{timestamp}`
- Example: `gdp-web-1-2025-12-03-20-16`

---

## Cleanup

```bash
# Delete Lambda function
aws lambda delete-function --function-name gdp-web-event-driven-ami

# Delete EventBridge rule
aws events remove-targets --rule gdp-web-ami-creation-rule --ids "1"
aws events delete-rule --name gdp-web-ami-creation-rule

# Delete CloudWatch Log Group
aws logs delete-log-group --log-group-name /aws/lambda/gdp-web-event-driven-ami

# Delete IAM role policies
aws iam delete-role-policy \
    --role-name gdp-web-event-lambda-role \
    --policy-name EC2ImageAccess

aws iam detach-role-policy \
    --role-name gdp-web-event-lambda-role \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

# Delete IAM role
aws iam delete-role --role-name gdp-web-event-lambda-role

# Delete AMIs (optional - be careful!)
# List AMIs first
aws ec2 describe-images \
    --owners self \
    --filters "Name=name,Values=gdp-web-*" \
    --query 'Images[*].[ImageId,Name]' \
    --output table

# Delete specific AMI
# aws ec2 deregister-image --image-id ami-xxxxx
```

---

## Key Learnings

1. **Event-Driven Architecture**: EventBridge + Lambda provides real-time automation without polling

2. **Application-Specific Logic**: Lambda intelligently identifies which application triggered the event

3. **AMI Naming Convention**: Consistent naming is critical for automation

4. **CloudTrail Integration**: Required for EventBridge to detect API calls

5. **Minimal Permissions**: Lambda only needs `ec2:DescribeImages` permission

---

## Files in This Directory

### Essential Files
- `event-driven-lambda.py` - Event-driven Lambda function
- `task1-lambda-latest-ami.py` - Manual fetch Lambda function
- `deploy-event-lambda.sh` - Deployment script
- `task1-create-ami-backups.sh` - AMI backup creation script
- `check-lambda-logs.sh` - Log viewing script
- `TASK1-DOCUMENTATION.md` - This documentation

### Optional/Reference Files
- `task1-terraform/` - Terraform infrastructure (if using IaC)
- `test-event-lambda.sh` - Testing script

---

## References

- [AWS Lambda Documentation](https://docs.aws.amazon.com/lambda/)
- [Amazon EventBridge Documentation](https://docs.aws.amazon.com/eventbridge/)
- [AWS CloudTrail Documentation](https://docs.aws.amazon.com/cloudtrail/)
- [EC2 AMI Documentation](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html)
