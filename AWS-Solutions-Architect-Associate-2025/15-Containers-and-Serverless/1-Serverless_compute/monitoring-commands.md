# Service Monitoring Commands

## 🔍 What to Check for Working Services

### Lambda Function Checks
```bash
# 1. Function Status
aws lambda get-function --function-name multi-trigger-lambda --query 'Configuration.State'

# 2. Test Function
aws lambda invoke --function-name multi-trigger-lambda --payload '{"test":"data"}' response.json

# 3. Check Logs
aws logs describe-log-groups --log-group-name-prefix "/aws/lambda/multi-trigger-lambda"

# 4. Recent Log Events
aws logs filter-log-events --log-group-name "/aws/lambda/multi-trigger-lambda" --start-time $(date -d '5 minutes ago' +%s)000
```

### ECS Service Checks
```bash
# 1. Cluster Status
aws ecs describe-clusters --clusters my-fargate-cluster

# 2. Service Status
aws ecs describe-services --cluster my-fargate-cluster --services my-ecs-service

# 3. Task Status
aws ecs list-tasks --cluster my-fargate-cluster
aws ecs describe-tasks --cluster my-fargate-cluster --tasks TASK_ARN

# 4. Service Logs
aws logs filter-log-events --log-group-name "/ecs/my-ecs-app" --start-time $(date -d '5 minutes ago' +%s)000
```

### Application Health Checks
```bash
# 1. Get Task Public IP
TASK_ARN=$(aws ecs list-tasks --cluster my-fargate-cluster --query 'taskArns[0]' --output text)
ENI_ID=$(aws ecs describe-tasks --cluster my-fargate-cluster --tasks $TASK_ARN --query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value' --output text)
PUBLIC_IP=$(aws ec2 describe-network-interfaces --network-interface-ids $ENI_ID --query 'NetworkInterfaces[0].Association.PublicIp' --output text)

# 2. Test HTTP Endpoints
curl http://$PUBLIC_IP:5000/
curl http://$PUBLIC_IP:5000/health

# 3. Load Test
for i in {1..10}; do curl -s http://$PUBLIC_IP:5000/ | jq .hostname; done
```

## ✅ Success Indicators

### Lambda Function Working:
- State: "Active"
- Invocation returns 200 status
- CloudWatch logs show execution
- No error messages in logs

### ECS Service Working:
- Service status: "ACTIVE"
- Running count = Desired count
- Task status: "RUNNING"
- Health status: "HEALTHY"
- HTTP endpoints respond with 200

### Application Working:
- HTTP GET / returns JSON response
- HTTP GET /health returns {"status": "healthy"}
- Different hostnames on multiple requests (load balancing)
- Response time < 2 seconds

## 🚨 Troubleshooting

### Common Issues:
1. **Lambda timeout**: Check function timeout settings
2. **ECS task failing**: Check CloudWatch logs for errors
3. **No public IP**: Ensure assignPublicIp=ENABLED in service
4. **Connection refused**: Check security group allows port 5000
5. **Task not starting**: Check task execution role permissions

### Debug Commands:
```bash
# Check security groups
aws ec2 describe-security-groups --group-ids sg-xxxxx

# Check task definition
aws ecs describe-task-definition --task-definition my-ecs-app

# Check service events
aws ecs describe-services --cluster my-fargate-cluster --services my-ecs-service --query 'services[0].events'
```