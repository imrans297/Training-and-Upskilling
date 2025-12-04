# Task 2: ASG + ALB with CPU Scaling and AMI Update Automation

## Overview
This task implements an Auto Scaling Group (ASG) with Application Load Balancer (ALB) that automatically scales based on CPU utilization and updates instances when new AMIs are created.

## Architecture Components

### 1. Infrastructure Setup
- **VPC**: `vpc-00af5d50f8f210db9` (GDP-Web-1 VPC)
- **Subnets**: `subnet-0eec597f685e0d199`, `subnet-0782b79778b517554` (Multi-AZ)
- **Key Pair**: `gdp-web-keypair`
- **Security Group**: `gdp-web-asg-sg`
- **Application Load Balancer**: `gdp-web-alb`
- **Target Group**: `gdp-web-tg`
- **Launch Template**: `gdp-web-asg-lt`
- **Auto Scaling Group**: `gdp-web-asg-final`

### 2. Scaling Configuration
- **Min Size**: 1 instance
- **Max Size**: 2 instances
- **Desired Capacity**: 1 instance
- **Scale Up**: When CPU > 75% for 2 evaluation periods (5 minutes each)
- **Scale Down**: When CPU < 25% for 2 evaluation periods (5 minutes each)
- **Cooldown Period**: 300 seconds (5 minutes)

### 3. Automation Flow
1. User creates new AMI from EC2 instance
2. EventBridge detects `CreateImage` API call via CloudTrail
3. Lambda function is triggered automatically
4. Lambda updates Launch Template with latest AMI
5. Lambda triggers Instance Refresh to replace running instances
6. ASG gradually replaces old instances with new AMI

---

## Lambda Function

### Function Name
`gdp-web-ami-update`

### Runtime
Python 3.9

### Function Code
```python
import json
import boto3
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """
    Lambda function to update ASG Launch Template with latest AMI
    Triggers when new GDP-Web AMI is created
    """
    
    print(f"Received event: {json.dumps(event)}")
    
    ec2 = boto3.client('ec2')
    autoscaling = boto3.client('autoscaling')
    
    try:
        # Extract AMI ID from EventBridge event
        detail = event.get('detail', {})
        ami_id = detail.get('responseElements', {}).get('imageId')
        ami_name = detail.get('requestParameters', {}).get('name', '')
        
        print(f"Processing AMI: {ami_id}, Name: {ami_name}")
        
        # Only process GDP-Web AMIs
        if not ami_name.startswith('gdp-web-'):
            print(f"Skipping non-GDP-Web AMI: {ami_name}")
            return {'statusCode': 200, 'body': 'Not a GDP-Web AMI'}
        
        # Get latest GDP-Web AMI (in case multiple AMIs exist)
        response = ec2.describe_images(
            Owners=['self'],
            Filters=[
                {'Name': 'name', 'Values': ['gdp-web-*']},
                {'Name': 'state', 'Values': ['available']}
            ]
        )
        
        if not response['Images']:
            print("No GDP-Web AMIs found")
            return {'statusCode': 404, 'body': 'No GDP-Web AMIs found'}
        
        # Sort by creation date and get latest
        latest_ami = sorted(response['Images'], key=lambda x: x['CreationDate'])[-1]
        latest_ami_id = latest_ami['ImageId']
        
        print(f"Latest GDP-Web AMI: {latest_ami_id}")
        print(f"Latest AMI Name: {latest_ami['Name']}")
        print(f"Latest AMI Creation Date: {latest_ami['CreationDate']}")
        
        # Update Launch Template
        launch_template_name = 'gdp-web-asg-lt'
        
        # Get current launch template
        lt_response = ec2.describe_launch_template_versions(
            LaunchTemplateName=launch_template_name,
            Versions=['$Latest']
        )
        
        current_version = lt_response['LaunchTemplateVersions'][0]
        current_ami = current_version['LaunchTemplateData']['ImageId']
        
        print(f"Current Launch Template AMI: {current_ami}")
        print(f"Current Launch Template Version: {current_version['VersionNumber']}")
        
        if current_ami == latest_ami_id:
            print("Launch Template already uses latest AMI")
            return {'statusCode': 200, 'body': 'Launch Template already up to date'}
        
        # Create new launch template version with latest AMI
        new_version_response = ec2.create_launch_template_version(
            LaunchTemplateName=launch_template_name,
            LaunchTemplateData={
                'ImageId': latest_ami_id,
                'InstanceType': current_version['LaunchTemplateData']['InstanceType'],
                'KeyName': current_version['LaunchTemplateData']['KeyName'],
                'SecurityGroupIds': current_version['LaunchTemplateData']['SecurityGroupIds'],
                'IamInstanceProfile': current_version['LaunchTemplateData'].get('IamInstanceProfile', {}),
                'UserData': current_version['LaunchTemplateData'].get('UserData', '')
            },
            SourceVersion='$Latest'
        )
        
        new_version = new_version_response['LaunchTemplateVersion']['VersionNumber']
        print(f"Created new launch template version: {new_version}")
        print(f"New version uses AMI: {latest_ami_id}")
        
        # Set new version as default
        ec2.modify_launch_template(
            LaunchTemplateName=launch_template_name,
            DefaultVersion=str(new_version)
        )
        
        print(f"Set version {new_version} as default")
        print(f"Launch template {launch_template_name} now uses AMI {latest_ami_id}")
        
        # Update Auto Scaling Group to use new version
        asg_name = "gdp-web-asg-final"
        
        autoscaling.update_auto_scaling_group(
            AutoScalingGroupName=asg_name,
            LaunchTemplate={
                'LaunchTemplateName': launch_template_name,
                'Version': '$Latest'
            }
        )
        
        print(f"Updated ASG {asg_name} to use latest launch template version")
        
        # Trigger instance refresh to replace instances with new AMI
        refresh_response = autoscaling.start_instance_refresh(
            AutoScalingGroupName=asg_name,
            Strategy='Rolling',
            Preferences={
                'InstanceWarmup': 300,
                'MinHealthyPercentage': 50
            }
        )
        
        refresh_id = refresh_response['InstanceRefreshId']
        print(f"Started instance refresh: {refresh_id}")
        
        result = {
            'statusCode': 200,
            'body': {
                'message': 'Launch Template updated successfully',
                'previous_ami': current_ami,
                'new_ami': latest_ami_id,
                'launch_template': launch_template_name,
                'previous_version': current_version['VersionNumber'],
                'new_version': new_version,
                'instance_refresh_id': refresh_id
            }
        }
        
        print(f"=== UPDATE SUMMARY ===")
        print(f"Previous AMI: {current_ami}")
        print(f"New AMI: {latest_ami_id}")
        print(f"Launch Template: {launch_template_name}")
        print(f"New Version: {new_version}")
        print(f"Instance Refresh ID: {refresh_id}")
        print(f"Result: {json.dumps(result)}")
        return result
        
    except Exception as e:
        error_msg = f"Error updating launch template: {str(e)}"
        print(error_msg)
        return {
            'statusCode': 500,
            'body': {'error': error_msg}
        }
```

---

## IAM Policies

### 1. Lambda Execution Role: `gdp-web-ami-update-role`

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

#### EC2 Permissions Policy
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeImages",
                "ec2:DescribeLaunchTemplateVersions",
                "ec2:CreateLaunchTemplateVersion",
                "ec2:ModifyLaunchTemplate"
            ],
            "Resource": "*"
        }
    ]
}
```

#### Auto Scaling Group Update Policy (CRITICAL)
**Policy Name**: `LambdaASGUpdatePolicy`

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "autoscaling:UpdateAutoScalingGroup",
                "autoscaling:StartInstanceRefresh",
                "autoscaling:DescribeAutoScalingGroups",
                "ec2:RunInstances"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "iam:PassRole"
            ],
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "iam:PassedToService": "ec2.amazonaws.com"
                }
            }
        }
    ]
}
```

**Important Notes:**
- `ec2:RunInstances` is required for Lambda to authorize ASG to use the launch template
- `iam:PassRole` is required to pass IAM instance profile to EC2 instances
- Without these permissions, you'll get: `AccessDenied: You are not authorized to use launch template`

### 2. EC2 Instance Profile: `EC2-CloudWatch-Role`
Required for instances to send metrics to CloudWatch.

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "cloudwatch:PutMetricData",
                "ec2:DescribeVolumes",
                "ec2:DescribeTags",
                "logs:PutLogEvents",
                "logs:DescribeLogStreams",
                "logs:DescribeLogGroups",
                "logs:CreateLogStream",
                "logs:CreateLogGroup"
            ],
            "Resource": "*"
        }
    ]
}
```

---

## EventBridge Rule

### Rule Name
`gdp-web-ami-creation-rule`

### Event Pattern
```json
{
    "source": ["aws.ec2"],
    "detail-type": ["AWS API Call via CloudTrail"],
    "detail": {
        "eventName": ["CreateImage"],
        "requestParameters": {
            "name": [{
                "prefix": "gdp-web-"
            }]
        }
    }
}
```

### Target
- **Target Type**: Lambda function
- **Function**: `gdp-web-ami-update`

---

## Deployment Commands

### 1. Deploy Infrastructure
```bash
cd /home/einfochips/TrainingPlanNew/Tasks/task2-asg-alb-scaling
bash task2-asg-alb-setup.sh
```

### 2. Deploy Lambda Function
```bash
bash task2-deploy-lambda.sh
```

### 3. Add Required IAM Permissions (CRITICAL STEP)
```bash
# First, get the Lambda role name
aws lambda get-function \
    --function-name gdp-web-ami-update \
    --query 'Configuration.Role' \
    --output text
# Output: arn:aws:iam::375039967967:role/gdp-web-ami-update-role

# Apply the ASG update policy
aws iam put-role-policy \
    --role-name gdp-web-ami-update-role \
    --policy-name LambdaASGUpdatePolicy \
    --policy-document file://lambda-asg-policy.json

# Verify policy was attached
aws iam get-role-policy \
    --role-name gdp-web-ami-update-role \
    --policy-name LambdaASGUpdatePolicy
```

**Note**: This step is mandatory. Without these permissions, Lambda will fail with `AccessDenied` error when trying to update the Auto Scaling Group.

---

## Testing

### 1. Test CPU Scaling
```bash
bash task2-test-scaling.sh
```

### 2. Test AMI Update Automation
```bash
# Create new AMI (EventBridge will auto-trigger Lambda)
AMI_NAME="gdp-web-1-final-test-$(date +%Y-%m-%d-%H-%M)"
AMI_ID=$(aws ec2 create-image \
    --instance-id i-0b2fa2f35913cac0c \
    --name "$AMI_NAME" \
    --description "Automation test" \
    --no-reboot \
    --query 'ImageId' \
    --output text)

echo "Created AMI: $AMI_ID"
echo "AMI Name: $AMI_NAME"

# Add tags to AMI
aws ec2 create-tags \
    --resources $AMI_ID \
    --tags Key=Name,Value="$AMI_NAME"

# Check AMI status
aws ec2 describe-images \
    --image-ids $AMI_ID \
    --query 'Images[0].[ImageId,State,CreationDate]' \
    --output table

# Wait 2-3 minutes for AMI to become available and Lambda to process
sleep 180

# Check Lambda logs (last 5 minutes)
aws logs tail /aws/lambda/gdp-web-ami-update --since 5m --format short

# Or follow logs in real-time
aws logs tail /aws/lambda/gdp-web-ami-update --follow
```

### 3. Verify Instance Refresh
```bash
# Check instance refresh status
aws autoscaling describe-instance-refreshes \
    --auto-scaling-group-name gdp-web-asg-final \
    --query 'InstanceRefreshes[0].[Status,PercentageComplete,StartTime]' \
    --output table
```

### 4. Verify Launch Template Update
```bash
# Check latest launch template version
aws ec2 describe-launch-template-versions \
    --launch-template-name gdp-web-asg-lt \
    --versions '$Latest' \
    --query 'LaunchTemplateVersions[0].[VersionNumber,LaunchTemplateData.ImageId]' \
    --output table

# List all launch template versions
aws ec2 describe-launch-template-versions \
    --launch-template-name gdp-web-asg-lt \
    --query 'LaunchTemplateVersions[*].[VersionNumber,LaunchTemplateData.ImageId,DefaultVersion]' \
    --output table
```

### 5. List All GDP-Web AMIs
```bash
# List all GDP-Web AMIs sorted by creation date
aws ec2 describe-images \
    --owners self \
    --filters "Name=name,Values=gdp-web-*" \
    --query 'Images | sort_by(@, &CreationDate)[*].[ImageId,Name,CreationDate,State]' \
    --output table
```

### 6. Manual Lambda Invocation (for testing)
```bash
# Manually invoke Lambda with test event
aws lambda invoke \
    --function-name gdp-web-ami-update \
    --payload '{"detail":{"requestParameters":{"instanceId":"i-0b2fa2f35913cac0c","name":"gdp-web-1-final-test-2025-12-03-20-16"},"responseElements":{"imageId":"ami-081f167ed7c626683"}}}' \
    response.json

# View response
cat response.json
```

---

## Troubleshooting

### Issue 1: AccessDenied when updating ASG
**Error**: `You are not authorized to use launch template`

**Solution**: Add `ec2:RunInstances` and `iam:PassRole` permissions to Lambda role

### Issue 2: Lambda not triggered
**Cause**: EventBridge rule not configured or CloudTrail not enabled

**Solution**: 
- Verify EventBridge rule exists
- Ensure CloudTrail is logging management events
- Check Lambda has resource-based policy allowing EventBridge

### Issue 3: Instance Refresh fails
**Cause**: MinHealthyPercentage too high or InstanceWarmup too short

**Solution**: Adjust refresh preferences:
```python
Preferences={
    'InstanceWarmup': 300,  # Increase if instances need more time
    'MinHealthyPercentage': 50  # Lower if you have only 1-2 instances
}
```

### Issue 4: Wrong AMI selected as "latest"
**Cause**: Timing issue - Lambda checks before AMI is fully available

**Solution**: Wait 2-3 minutes after AMI creation before expecting automation

---

## Monitoring

### CloudWatch Metrics
- **ASG Metrics**: `AWS/AutoScaling` namespace
  - `GroupDesiredCapacity`
  - `GroupInServiceInstances`
  - `GroupMinSize`, `GroupMaxSize`

- **EC2 Metrics**: `AWS/EC2` namespace
  - `CPUUtilization`

- **ALB Metrics**: `AWS/ApplicationELB` namespace
  - `TargetResponseTime`
  - `HealthyHostCount`
  - `UnHealthyHostCount`

### Lambda Logs
```bash
# Tail logs in real-time
aws logs tail /aws/lambda/gdp-web-ami-update --follow

# Get logs from last 10 minutes
aws logs tail /aws/lambda/gdp-web-ami-update --since 10m
```

### CloudWatch Alarms
- `gdp-web-cpu-high`: Triggers scale-up when CPU > 75%
- `gdp-web-cpu-low`: Triggers scale-down when CPU < 25%

---

## Cleanup
```bash
# Delete Auto Scaling Group
aws autoscaling delete-auto-scaling-group \
    --auto-scaling-group-name gdp-web-asg-final \
    --force-delete

# Wait for instances to terminate
sleep 45

# Delete Launch Template
aws ec2 delete-launch-template \
    --launch-template-name gdp-web-asg-lt

# Delete Load Balancer
ALB_ARN=$(aws elbv2 describe-load-balancers \
    --names gdp-web-alb \
    --query 'LoadBalancers[0].LoadBalancerArn' \
    --output text)
aws elbv2 delete-load-balancer --load-balancer-arn $ALB_ARN

# Wait for ALB deletion
sleep 30

# Delete Target Group
TG_ARN=$(aws elbv2 describe-target-groups \
    --names gdp-web-tg \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text)
aws elbv2 delete-target-group --target-group-arn $TG_ARN

# Delete Lambda Function
aws lambda delete-function --function-name gdp-web-ami-update

# Delete EventBridge Rule
aws events remove-targets --rule gdp-web-ami-creation-rule --ids "1"
aws events delete-rule --name gdp-web-ami-creation-rule

# Delete CloudWatch Alarms
aws cloudwatch delete-alarms \
    --alarm-names gdp-web-cpu-high gdp-web-cpu-low

# Delete CloudWatch Log Group
aws logs delete-log-group \
    --log-group-name /aws/lambda/gdp-web-ami-update

# Delete Security Group (wait for dependencies to clear)
sleep 10
SG_ID=$(aws ec2 describe-security-groups \
    --filters "Name=group-name,Values=gdp-web-asg-sg" \
    --query 'SecurityGroups[0].GroupId' \
    --output text)
aws ec2 delete-security-group --group-id $SG_ID

# Delete IAM Role Policy
aws iam delete-role-policy \
    --role-name gdp-web-ami-update-role \
    --policy-name LambdaASGUpdatePolicy
```

---

## Key Learnings

1. **IAM Permissions are Critical**: Lambda needs comprehensive permissions including `ec2:RunInstances` and `iam:PassRole` to update ASG with launch templates

2. **EventBridge + CloudTrail**: Powerful combination for event-driven automation

3. **Instance Refresh**: Graceful way to replace instances without downtime

4. **Timing Matters**: AMI availability and Lambda execution timing can cause race conditions

5. **Launch Template Versioning**: Always use `$Latest` version in ASG for automatic updates

---

## References

- [AWS Auto Scaling Documentation](https://docs.aws.amazon.com/autoscaling/)
- [AWS Lambda with EventBridge](https://docs.aws.amazon.com/lambda/latest/dg/with-eventbridge.html)
- [EC2 Launch Templates](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-launch-templates.html)
- [Instance Refresh](https://docs.aws.amazon.com/autoscaling/ec2/userguide/asg-instance-refresh.html)
