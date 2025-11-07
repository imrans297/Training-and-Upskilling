#!/bin/bash

echo "=== Testing ECS and Lambda Services ==="

# Test Lambda Function
echo "1. Testing Lambda Function..."
aws lambda invoke \
  --function-name multi-trigger-lambda \
  --payload '{"test": "direct invoke"}' \
  response.json

echo "Lambda Response:"
cat response.json
echo ""

# Check Lambda logs
echo "2. Checking Lambda CloudWatch Logs..."
LOG_GROUP="/aws/lambda/multi-trigger-lambda"
aws logs describe-log-streams \
  --log-group-name $LOG_GROUP \
  --order-by LastEventTime \
  --descending \
  --max-items 1 \
  --query 'logStreams[0].logStreamName' \
  --output text > latest_stream.txt

if [ -s latest_stream.txt ]; then
  STREAM_NAME=$(cat latest_stream.txt)
  echo "Latest log events:"
  aws logs get-log-events \
    --log-group-name $LOG_GROUP \
    --log-stream-name $STREAM_NAME \
    --limit 5 \
    --query 'events[*].message' \
    --output text
fi

# Test ECS Service (if running)
echo "3. Checking ECS Service Status..."
aws ecs describe-services \
  --cluster my-fargate-cluster \
  --services my-ecs-service \
  --query 'services[0].[serviceName,status,runningCount,desiredCount]' \
  --output table 2>/dev/null || echo "ECS service not found or not created yet"

# Check ECS tasks
echo "4. Checking ECS Tasks..."
aws ecs list-tasks \
  --cluster my-fargate-cluster \
  --query 'taskArns' \
  --output text > tasks.txt

if [ -s tasks.txt ]; then
  TASK_ARN=$(head -1 tasks.txt)
  echo "Task details:"
  aws ecs describe-tasks \
    --cluster my-fargate-cluster \
    --tasks $TASK_ARN \
    --query 'tasks[0].[taskArn,lastStatus,healthStatus]' \
    --output table
    
  # Get task public IP
  echo "5. Getting Task Public IP..."
  ENI_ID=$(aws ecs describe-tasks \
    --cluster my-fargate-cluster \
    --tasks $TASK_ARN \
    --query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value' \
    --output text)
    
  if [ ! -z "$ENI_ID" ]; then
    PUBLIC_IP=$(aws ec2 describe-network-interfaces \
      --network-interface-ids $ENI_ID \
      --query 'NetworkInterfaces[0].Association.PublicIp' \
      --output text)
    
    if [ "$PUBLIC_IP" != "None" ] && [ ! -z "$PUBLIC_IP" ]; then
      echo "Task Public IP: $PUBLIC_IP"
      echo "Testing HTTP endpoint..."
      curl -s http://$PUBLIC_IP:5000/ | jq . 2>/dev/null || echo "Service not responding or jq not installed"
      curl -s http://$PUBLIC_IP:5000/health | jq . 2>/dev/null || echo "Health check not responding"
    else
      echo "No public IP assigned to task"
    fi
  fi
else
  echo "No ECS tasks running"
fi

# Cleanup temp files
rm -f response.json latest_stream.txt tasks.txt