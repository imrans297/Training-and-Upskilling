#!/bin/bash

echo "=== Service Health Checks ==="

# Lambda Health Check
echo "🔍 Lambda Function Health:"
LAMBDA_STATUS=$(aws lambda get-function \
  --function-name multi-trigger-lambda \
  --query 'Configuration.State' \
  --output text 2>/dev/null)

if [ "$LAMBDA_STATUS" = "Active" ]; then
  echo "✅ Lambda: HEALTHY (Active)"
else
  echo "❌ Lambda: UNHEALTHY ($LAMBDA_STATUS)"
fi

# ECS Service Health Check
echo "🔍 ECS Service Health:"
ECS_HEALTH=$(aws ecs describe-services \
  --cluster my-fargate-cluster \
  --services my-ecs-service \
  --query 'services[0].[runningCount,desiredCount]' \
  --output text 2>/dev/null)

if [ ! -z "$ECS_HEALTH" ]; then
  RUNNING=$(echo $ECS_HEALTH | cut -d' ' -f1)
  DESIRED=$(echo $ECS_HEALTH | cut -d' ' -f2)
  
  if [ "$RUNNING" = "$DESIRED" ] && [ "$RUNNING" != "0" ]; then
    echo "✅ ECS: HEALTHY ($RUNNING/$DESIRED tasks running)"
  else
    echo "⚠️  ECS: SCALING ($RUNNING/$DESIRED tasks running)"
  fi
else
  echo "❌ ECS: NOT FOUND"
fi

# Check ECS Task Health
echo "🔍 ECS Task Health:"
TASK_ARN=$(aws ecs list-tasks \
  --cluster my-fargate-cluster \
  --query 'taskArns[0]' \
  --output text 2>/dev/null)

if [ "$TASK_ARN" != "None" ] && [ ! -z "$TASK_ARN" ]; then
  TASK_STATUS=$(aws ecs describe-tasks \
    --cluster my-fargate-cluster \
    --tasks $TASK_ARN \
    --query 'tasks[0].lastStatus' \
    --output text)
  
  if [ "$TASK_STATUS" = "RUNNING" ]; then
    echo "✅ Task: HEALTHY (Running)"
  else
    echo "⚠️  Task: $TASK_STATUS"
  fi
else
  echo "❌ Task: NO TASKS FOUND"
fi

# Application Endpoint Test
echo "🔍 Application Endpoint:"
if [ "$TASK_ARN" != "None" ] && [ ! -z "$TASK_ARN" ]; then
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
      HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$PUBLIC_IP:5000/ --connect-timeout 5)
      
      if [ "$HTTP_STATUS" = "200" ]; then
        echo "✅ HTTP: HEALTHY (200 OK) - http://$PUBLIC_IP:5000/"
      else
        echo "❌ HTTP: UNHEALTHY ($HTTP_STATUS) - http://$PUBLIC_IP:5000/"
      fi
    else
      echo "❌ HTTP: NO PUBLIC IP"
    fi
  fi
fi