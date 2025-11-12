# Lab 3: Lambda with SNS Integration

## Overview
This lab integrates SNS (Simple Notification Service) with Lambda to create an automated incident response system. When CloudWatch alarms trigger, Lambda automatically takes corrective actions and sends notifications.


## What We're Building
- **SNS-Triggered Lambda**: Responds to CloudWatch alarms
- **Email Notifications**: Alerts via SNS email subscriptions
- **Automated Remediation**: Auto-stop instances on high CPU
- **Dual Invocation**: Direct calls and SNS triggers
- **Error Notifications**: Alert on Lambda failures

## Key Features
✅ **Incident Response**: Automated actions on alarms  
✅ **Multi-Channel Alerts**: Email and Lambda notifications  
✅ **Error Handling**: Comprehensive exception management  
✅ **Flexible Triggers**: SNS and direct invocation support  
✅ **Audit Trail**: Detailed logging and notifications  

## Terraform Resources

### 1. SNS Topic & Subscriptions
- **Topic**: `cloudops-alerts`
- **Email Subscription**: Admin notifications
- **Lambda Subscription**: Automated processing

### 2. Lambda Function
- **Name**: `cloudops-sns-automation`
- **Triggers**: SNS messages and direct invocation
- **Permissions**: EC2, SNS, CloudWatch Logs

### 3. CloudWatch Alarm
- **Metric**: EC2 CPU Utilization > 80%
- **Action**: Publishes to SNS topic
- **Evaluation**: 2 periods of 5 minutes

## Deployment

### Step 1: Update Email Address
```bash
# Edit terraform.tfvars
notification_email = "your-email@domain.com"
```

### Step 2: Deploy Infrastructure
```bash
cd labs/lab3
terraform init
terraform plan
terraform apply
```
![Terraform Apply](screenshots/terraform-apply.png)

### Step 3: Confirm Email Subscription
Check your email and confirm the SNS subscription.
![Email Confirmation](screenshots/email-confirmation.png)

## Testing

### Test 1: Direct Lambda Invocation
```bash
# Test list instances
aws lambda invoke --function-name cloudops-sns-automation --payload '{"action":"list_instances","tag":"Environment=Dev"}' response.json

# Test with notification
aws lambda invoke --function-name cloudops-sns-automation --payload '{"action":"stop_instances","tag":"Environment=Dev","notify":true}' response.json
```
![Direct Invocation](screenshots/direct-invocation.png)

### Test 2: SNS Message Publishing
```bash
# Send test SNS message
aws sns publish --topic-arn arn:aws:sns:us-east-1:123456789012:cloudops-alerts --message "Test CloudOps Alert" --subject "Test Notification"
```
![SNS Publish](screenshots/sns-publish.png)

### Test 3: CloudWatch Alarm Simulation
```bash
# Trigger alarm manually
aws cloudwatch set-alarm-state --alarm-name cloudops-high-cpu --state-value ALARM --state-reason "Testing automated response"
```
![Alarm Test](screenshots/alarm-test.png)

## SNS Integration Flow

### 1. CloudWatch Alarm → SNS
```json
{
  "AlarmName": "cloudops-high-cpu",
  "NewStateValue": "ALARM",
  "NewStateReason": "Threshold Crossed: 2 out of 2 datapoints",
  "Trigger": {
    "Dimensions": [
      {
        "name": "InstanceId",
        "value": "i-1234567890abcdef0"
      }
    ]
  }
}
```

### 2. SNS → Lambda Processing
```python
def handle_cloudwatch_alarm(alarm_message, ec2, sns, sns_topic_arn):
    if new_state == 'ALARM' and 'high-cpu' in alarm_name.lower():
        ec2.stop_instances(InstanceIds=[instance_id])
        send_notification(sns, sns_topic_arn, "Instance Stopped", message)
```

### 3. Notification Sent
![Email Notification](screenshots/email-notification.png)

## Monitoring & Logging

### CloudWatch Logs
![CloudWatch Logs](screenshots/cloudwatch-logs.png)

### SNS Metrics
![SNS Metrics](screenshots/sns-metrics.png)

### Lambda Metrics
![Lambda Metrics](screenshots/lambda-metrics.png)

## Use Cases

### 1. High CPU Response
- **Trigger**: CPU > 80% for 10 minutes
- **Action**: Stop problematic instance
- **Notification**: Email alert with details

### 2. Cost Optimization
- **Trigger**: Manual or scheduled
- **Action**: Stop dev instances
- **Notification**: Summary of stopped instances

### 3. Error Handling
- **Trigger**: Lambda execution error
- **Action**: Log error details
- **Notification**: Error alert to admin

## Advanced Features

### Error Notifications
```python
try:
    # Lambda processing
    result = process_event(event)
except Exception as e:
    send_notification(sns, sns_topic_arn, "CloudOps Error", str(e))
```

### Conditional Notifications
```python
# Only notify on specific actions
if action == 'stop_instances' and notify:
    send_notification(sns, sns_topic_arn, "Instances Stopped", result)
```

### Alarm-Specific Actions
```python
if 'high-cpu' in alarm_name.lower():
    # Stop instance
elif 'high-memory' in alarm_name.lower():
    # Restart instance
elif 'disk-full' in alarm_name.lower():
    # Clean up disk space
```

## Security Best Practices
✅ **SNS Topic Encryption**: Enable encryption at rest  
✅ **Email Validation**: Confirm subscription ownership  
✅ **IAM Permissions**: Least privilege access  
✅ **Message Filtering**: Process only relevant alarms  

## Troubleshooting

### Common Issues
1. **Email not received**: Check spam folder, confirm subscription
2. **Lambda not triggered**: Verify SNS subscription and permissions
3. **Alarm not firing**: Check metric thresholds and instance ID

### Debug Commands
```bash
# Check SNS subscriptions
aws sns list-subscriptions-by-topic --topic-arn arn:aws:sns:us-east-1:123456789012:cloudops-alerts

# View alarm history
aws cloudwatch describe-alarm-history --alarm-name cloudops-high-cpu

# Test SNS delivery
aws sns publish --topic-arn arn:aws:sns:us-east-1:123456789012:cloudops-alerts --message "Debug test"
```

## Cost Considerations
- **SNS**: $0.50 per 1M requests
- **Lambda**: $0.20 per 1M requests
- **CloudWatch**: $0.30 per alarm per month
- **Typical monthly cost**: < $5 for moderate usage

## Next Steps
- **Lab 4**: Lambda Layers for Code Reuse
- **Lab 5**: Error Handling and Monitoring
- **Advanced**: Multi-region SNS topics

## Cleanup
```bash
terraform destroy
```
![Terraform Destroy](screenshots/terraform-destroy.png)