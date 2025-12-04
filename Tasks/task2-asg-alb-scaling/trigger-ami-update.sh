#!/bin/bash

# Manual trigger for AMI update automation

echo "=== Getting Latest GDP-Web AMI ==="
LATEST_AMI=$(aws ec2 describe-images --owners self --filters "Name=name,Values=gdp-web-*" --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' --output text)
echo "Latest AMI: $LATEST_AMI"

echo "=== Updating Launch Template ==="
NEW_VERSION=$(aws ec2 create-launch-template-version --launch-template-name gdp-web-asg-lt --launch-template-data "{\"ImageId\":\"$LATEST_AMI\"}" --source-version '$Latest' --query 'LaunchTemplateVersion.VersionNumber' --output text)

aws ec2 modify-launch-template --launch-template-name gdp-web-asg-lt --default-version $NEW_VERSION

echo "=== Triggering Instance Refresh ==="
REFRESH_ID=$(aws autoscaling start-instance-refresh --auto-scaling-group-name gdp-web-asg-final --strategy Rolling --preferences InstanceWarmup=300,MinHealthyPercentage=50 --query 'InstanceRefreshId' --output text)

echo "=== Update Complete ==="
echo "Launch Template Version: $NEW_VERSION"
echo "AMI: $LATEST_AMI" 
echo "Instance Refresh ID: $REFRESH_ID"
echo "ASG will replace instances with latest AMI"