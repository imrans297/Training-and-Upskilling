#!/bin/bash

# Setup reliable AMI automation using CloudWatch Events

echo "=== Creating CloudWatch Event Rule for AMI Creation ==="
aws events put-rule \
    --name "gdp-web-ami-automation" \
    --event-pattern '{
        "source": ["aws.ec2"],
        "detail-type": ["EBS Snapshot Notification"],
        "detail": {
            "state": ["completed"]
        }
    }' \
    --description "Trigger Lambda when AMI snapshots complete"

echo "=== Creating Lambda for AMI Detection ==="
cat > ami-detector-lambda.py << 'EOF'
import json
import boto3
import time

def lambda_handler(event, context):
    print(f"Received event: {json.dumps(event)}")
    
    ec2 = boto3.client('ec2')
    
    # Get latest GDP-Web AMI
    response = ec2.describe_images(
        Owners=['self'],
        Filters=[
            {'Name': 'name', 'Values': ['gdp-web-*']},
            {'Name': 'state', 'Values': ['available']}
        ]
    )
    
    if not response['Images']:
        return {'statusCode': 200, 'body': 'No GDP-Web AMIs found'}
    
    # Sort by creation date and get latest
    latest_ami = sorted(response['Images'], key=lambda x: x['CreationDate'])[-1]
    latest_ami_id = latest_ami['ImageId']
    
    print(f"Latest GDP-Web AMI: {latest_ami_id}")
    
    # Trigger AMI update Lambda
    lambda_client = boto3.client('lambda')
    
    payload = {
        "detail": {
            "requestParameters": {
                "instanceId": "i-0b2fa2f35913cac0c",
                "name": latest_ami['Name']
            },
            "responseElements": {
                "imageId": latest_ami_id
            }
        }
    }
    
    lambda_client.invoke(
        FunctionName='gdp-web-ami-update',
        InvocationType='Event',
        Payload=json.dumps(payload)
    )
    
    print(f"Triggered AMI update for: {latest_ami_id}")
    
    return {
        'statusCode': 200,
        'body': f'Triggered update for AMI: {latest_ami_id}'
    }
EOF

echo "=== Alternative: Simple Cron-based Check ==="
echo "Run this every 5 minutes to check for new AMIs:"
echo "*/5 * * * * /home/einfochips/TrainingPlanNew/Tasks/task2-asg-alb-scaling/trigger-ami-update.sh"