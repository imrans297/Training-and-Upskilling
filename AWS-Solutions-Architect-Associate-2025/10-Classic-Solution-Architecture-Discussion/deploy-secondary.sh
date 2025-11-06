#!/bin/bash
# deploy-secondary.sh - Scale up secondary region infrastructure

echo "Scaling up secondary region infrastructure..."

# Scale up Auto Scaling Group
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name webapp-dr-secondary-asg \
  --desired-capacity 2 \
  --region us-west-2

echo "Waiting for instances to become healthy..."
sleep 60

# Check instance health
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names webapp-dr-secondary-asg \
  --query 'AutoScalingGroups[0].Instances[*].[InstanceId,HealthStatus]' \
  --output table \
  --region us-west-2

# Get ALB DNS name
ALB_DNS=$(aws elbv2 describe-load-balancers \
  --names webapp-dr-secondary-alb \
  --query 'LoadBalancers[0].DNSName' \
  --output text \
  --region us-west-2)

echo "Secondary region deployment completed!"
echo "ALB DNS: $ALB_DNS"
echo "Test URL: http://$ALB_DNS"


# Manual Steps:
# # Scale down secondary (save costs)
# aws autoscaling update-auto-scaling-group --auto-scaling-group-name webapp-dr-secondary-asg --desired-capacity 0 --region us-west-2

# # Scale up secondary (disaster recovery)  
# aws autoscaling update-auto-scaling-group --auto-scaling-group-name webapp-dr-secondary-asg --desired-capacity 2 --region us-west-2

# # Deploy secondary region
# bash deploy-secondary.sh

# # Verify sync status
# bash verify-sync.sh