#!/bin/bash

# Test ASG Scaling and AMI Update

ASG_NAME="gdp-web-asg"
ALB_NAME="gdp-web-alb"

echo "=== Current ASG Status ==="
aws autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names $ASG_NAME \
    --query 'AutoScalingGroups[0].{Name:AutoScalingGroupName,Min:MinSize,Max:MaxSize,Desired:DesiredCapacity,Instances:length(Instances)}' \
    --output table

echo "=== Current Launch Template Version ==="
aws ec2 describe-launch-template-versions \
    --launch-template-name gdp-web-lt \
    --versions '$Latest' \
    --query 'LaunchTemplateVersions[0].{Version:VersionNumber,AMI:LaunchTemplateData.ImageId}' \
    --output table

echo "=== ALB Target Health ==="
TG_ARN=$(aws elbv2 describe-target-groups --names gdp-web-tg --query 'TargetGroups[0].TargetGroupArn' --output text)
aws elbv2 describe-target-health \
    --target-group-arn $TG_ARN \
    --query 'TargetHealthDescriptions[*].{Target:Target.Id,Health:TargetHealth.State}' \
    --output table

echo "=== ALB DNS Name ==="
ALB_DNS=$(aws elbv2 describe-load-balancers --names $ALB_NAME --query 'LoadBalancers[0].DNSName' --output text)
echo "Access your application at: http://$ALB_DNS"

echo ""
echo "=== Testing Instructions ==="
echo "1. Access the application: http://$ALB_DNS"
echo "2. Click 'Start CPU Load' button to trigger scaling"
echo "3. Monitor scaling with: watch -n 30 'aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $ASG_NAME --query \"AutoScalingGroups[0].Instances[*].{ID:InstanceId,Health:HealthStatus,State:LifecycleState}\" --output table'"
echo "4. Create AMI backup to test automatic launch template update"
echo "5. Check CloudWatch alarms: aws cloudwatch describe-alarms --alarm-names gdp-web-cpu-high gdp-web-cpu-low"

echo ""
echo "=== Create Test AMI Backup ==="
echo "To test AMI update automation, run:"
INSTANCE_ID=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $ASG_NAME --query 'AutoScalingGroups[0].Instances[0].InstanceId' --output text)
if [ "$INSTANCE_ID" != "None" ] && [ "$INSTANCE_ID" != "" ]; then
    echo "aws ec2 create-image --instance-id $INSTANCE_ID --name \"gdp-web-asg-\$(date +%Y-%m-%d-%H-%M)\" --description \"GDP-Web ASG AMI backup\" --no-reboot"
fi