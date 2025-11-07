# Section 16: Containers and Serverless

## 📋 Overview
This section covers AWS container services (ECS, Fargate, EKS) and serverless computing (Lambda, Step Functions) for modern application architectures.

## 🐳 Amazon ECS (Elastic Container Service)

### What is ECS?
- **Container orchestration**: Managed Docker container service
- **Launch types**: EC2 and Fargate
- **Task definitions**: Container specifications
- **Services**: Maintain desired task count
- **Clusters**: Logical grouping of resources

### ECS Components
- **Task Definition**: Blueprint for containers
- **Task**: Running instance of task definition
- **Service**: Ensures desired number of tasks
- **Cluster**: Compute resources for tasks

## ⚡ AWS Fargate

### What is Fargate?
- **Serverless containers**: No EC2 management
- **Pay per use**: Only pay for resources used
- **Automatic scaling**: Scale based on demand
- **Security**: Isolated compute environment
- **Integration**: Works with ECS and EKS

## ☸️ Amazon EKS (Elastic Kubernetes Service)

### What is EKS?
- **Managed Kubernetes**: AWS-managed control plane
- **Kubernetes compatibility**: Standard Kubernetes APIs
- **Node groups**: Managed EC2 instances
- **Fargate support**: Serverless Kubernetes pods
- **Add-ons**: AWS integrations for Kubernetes

## 🔧 AWS Lambda

### What is Lambda?
- **Serverless compute**: Run code without servers
- **Event-driven**: Triggered by AWS services
- **Auto-scaling**: Automatic capacity management
- **Pay per request**: Only pay for execution time
- **Multiple runtimes**: Support for various languages

### Lambda Features
- **Triggers**: 200+ AWS service integrations
- **Layers**: Share code across functions
- **Environment variables**: Configuration management
- **Dead letter queues**: Error handling
- **Provisioned concurrency**: Predictable performance

## 🔄 AWS Step Functions

### What is Step Functions?
- **Workflow orchestration**: Coordinate distributed applications
- **State machines**: Define workflow logic
- **Visual workflows**: Graphical representation
- **Error handling**: Built-in retry and error handling
- **Integration**: Native AWS service integration

## 🛠️ Hands-On Practice

### Practice 1: ECS with Fargate
**Objective**: Deploy containerized application using ECS Fargate

**Steps**:
1. **Create Docker Application**:
   ```bash
   # Create simple web application
   mkdir ecs-app && cd ecs-app
   
   cat > app.py << 'EOF'
   from flask import Flask, jsonify
   import os
   import socket
   from datetime import datetime
   
   app = Flask(__name__)
   
   @app.route('/')
   def home():
       return jsonify({
           'message': 'Hello from ECS Fargate!',
           'hostname': socket.gethostname(),
           'timestamp': datetime.now().isoformat(),
           'version': os.environ.get('APP_VERSION', '1.0')
       })
   
   @app.route('/health')
   def health():
       return jsonify({'status': 'healthy'})
   
   if __name__ == '__main__':
       app.run(host='0.0.0.0', port=5000)
   EOF
   
   cat > requirements.txt << 'EOF'
   Flask==2.3.3
   EOF
   
   cat > Dockerfile << 'EOF'
   FROM python:3.9-slim
   
   WORKDIR /app
   
   COPY requirements.txt .
   RUN pip install -r requirements.txt
   
   COPY app.py .
   
   EXPOSE 5000
   
   CMD ["python", "app.py"]
   EOF
   ```

2. **Build and Push to ECR**:
   ```bash
   # Create ECR repository
   aws ecr create-repository --repository-name my-ecs-app
   
   # Get login token
   aws ecr get-login-password --region us-east-1 | \
     docker login --username AWS --password-stdin \
     ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
   
   # Build and tag image
   docker build -t my-ecs-app .
   docker tag my-ecs-app:latest \
     ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/my-ecs-app:latest
   
   # Push image
   docker push ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/my-ecs-app:latest
   ```

3. **Create ECS Cluster and Task Definition**:
   ```bash
   # Create ECS cluster
   aws ecs create-cluster --cluster-name my-fargate-cluster
   
   # Create task execution role
   cat > task-execution-role.json << 'EOF'
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Principal": {
           "Service": "ecs-tasks.amazonaws.com"
         },
         "Action": "sts:AssumeRole"
       }
     ]
   }
   EOF
   
   aws iam create-role \
     --role-name ecsTaskExecutionRole \
     --assume-role-policy-document file://task-execution-role.json
   
   aws iam attach-role-policy \
     --role-name ecsTaskExecutionRole \
     --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
   
   # Create task definition
   cat > task-definition.json << 'EOF'
   {
     "family": "my-ecs-app",
     "networkMode": "awsvpc",
     "requiresCompatibilities": ["FARGATE"],
     "cpu": "256",
     "memory": "512",
     "executionRoleArn": "arn:aws:iam::ACCOUNT_ID:role/ecsTaskExecutionRole",
     "containerDefinitions": [
       {
         "name": "my-ecs-app",
         "image": "ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/my-ecs-app:latest",
         "portMappings": [
           {
             "containerPort": 5000,
             "protocol": "tcp"
           }
         ],
         "environment": [
           {
             "name": "APP_VERSION",
             "value": "1.0"
           }
         ],
         "logConfiguration": {
           "logDriver": "awslogs",
           "options": {
             "awslogs-group": "/ecs/my-ecs-app",
             "awslogs-region": "us-east-1",
             "awslogs-stream-prefix": "ecs"
           }
         }
       }
     ]
   }
   EOF
   
   # Create CloudWatch log group
   aws logs create-log-group --log-group-name /ecs/my-ecs-app
   
   # Register task definition
   aws ecs register-task-definition \
     --cli-input-json file://task-definition.json
   ```

4. **Create ECS Service**:
   ```bash
   # Create security group for ECS tasks
   VPC_ID=$(aws ec2 describe-vpcs \
     --filters "Name=is-default,Values=true" \
     --query 'Vpcs[0].VpcId' --output text)
   
   SG_ID=$(aws ec2 create-security-group \
     --group-name ecs-fargate-sg \
     --description "Security group for ECS Fargate tasks" \
     --vpc-id $VPC_ID \
     --query 'GroupId' --output text)
   
   aws ec2 authorize-security-group-ingress \
     --group-id $SG_ID \
     --protocol tcp \
     --port 5000 \
     --cidr 0.0.0.0/0
   
   # Get subnet IDs
   SUBNET_IDS=$(aws ec2 describe-subnets \
     --filters "Name=vpc-id,Values=$VPC_ID" \
     --query 'Subnets[0:2].SubnetId' --output text | tr '\t' ',')
   
   # Create ECS service
   aws ecs create-service \
     --cluster my-fargate-cluster \
     --service-name my-ecs-service \
     --task-definition my-ecs-app:1 \
     --desired-count 2 \
     --launch-type FARGATE \
     --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_IDS],securityGroups=[$SG_ID],assignPublicIp=ENABLED}"
   
   # Wait for service to be stable
   aws ecs wait services-stable \
     --cluster my-fargate-cluster \
     --services my-ecs-service
   ```

**Screenshot Placeholder**:
![ECS Fargate Service](screenshots/16-ecs-fargate-service.png)
*Caption: ECS Fargate service with containerized application*

### Practice 2: Lambda Function with API Gateway
**Objective**: Create Lambda function with multiple triggers

**Steps**:
1. **Create Lambda Function**:
   ```bash
   # Create Lambda function code
   cat > lambda_function.py << 'EOF'
   import json
   import boto3
   import os
   from datetime import datetime
   
   dynamodb = boto3.resource('dynamodb')
   
   def lambda_handler(event, context):
       # Determine event source
       event_source = 'unknown'
       
       if 'httpMethod' in event:
           event_source = 'api-gateway'
           return handle_api_request(event, context)
       elif 'Records' in event:
           if event['Records'][0].get('eventSource') == 'aws:s3':
               event_source = 's3'
               return handle_s3_event(event, context)
           elif event['Records'][0].get('eventSource') == 'aws:sqs':
               event_source = 'sqs'
               return handle_sqs_event(event, context)
       elif 'source' in event and event['source'] == 'aws.events':
           event_source = 'cloudwatch-events'
           return handle_scheduled_event(event, context)
       
       return {
           'statusCode': 200,
           'body': json.dumps({
               'message': f'Event processed from {event_source}',
               'timestamp': datetime.now().isoformat()
           })
       }
   
   def handle_api_request(event, context):
       method = event['httpMethod']
       path = event['path']
       
       return {
           'statusCode': 200,
           'headers': {
               'Content-Type': 'application/json',
               'Access-Control-Allow-Origin': '*'
           },
           'body': json.dumps({
               'message': f'{method} request to {path}',
               'requestId': context.aws_request_id,
               'timestamp': datetime.now().isoformat()
           })
       }
   
   def handle_s3_event(event, context):
       for record in event['Records']:
           bucket = record['s3']['bucket']['name']
           key = record['s3']['object']['key']
           
       return {
           'statusCode': 200,
           'body': json.dumps({
               'message': f'Processed S3 object {key} from bucket {bucket}'
           })
       }
   
   def handle_sqs_event(event, context):
       processed_messages = []
       for record in event['Records']:
           message_body = record['body']
           processed_messages.append(message_body)
           
       return {
           'statusCode': 200,
           'body': json.dumps({
               'message': f'Processed {len(processed_messages)} SQS messages'
           })
       }
   
   def handle_scheduled_event(event, context):
       return {
           'statusCode': 200,
           'body': json.dumps({
               'message': 'Scheduled event processed',
               'rule': event.get('detail-type', 'Unknown')
           })
       }
   EOF
   
   # Create deployment package
   zip lambda-function.zip lambda_function.py
   
   # Create IAM role for Lambda
   cat > lambda-role.json << 'EOF'
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Principal": {
           "Service": "lambda.amazonaws.com"
         },
         "Action": "sts:AssumeRole"
       }
     ]
   }
   EOF
   
   aws iam create-role \
     --role-name lambda-execution-role \
     --assume-role-policy-document file://lambda-role.json
   
   aws iam attach-role-policy \
     --role-name lambda-execution-role \
     --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
   
   # Create Lambda function
   aws lambda create-function \
     --function-name multi-trigger-lambda \
     --runtime python3.9 \
     --role arn:aws:iam::ACCOUNT_ID:role/lambda-execution-role \
     --handler lambda_function.lambda_handler \
     --zip-file fileb://lambda-function.zip
   ```

2. **Create API Gateway Integration**:
   ```bash
   # Create API Gateway
   API_ID=$(aws apigateway create-rest-api \
     --name lambda-api \
     --query 'id' --output text)
   
   # Get root resource ID
   ROOT_ID=$(aws apigateway get-resources \
     --rest-api-id $API_ID \
     --query 'items[0].id' --output text)
   
   # Create resource
   RESOURCE_ID=$(aws apigateway create-resource \
     --rest-api-id $API_ID \
     --parent-id $ROOT_ID \
     --path-part hello \
     --query 'id' --output text)
   
   # Create GET method
   aws apigateway put-method \
     --rest-api-id $API_ID \
     --resource-id $RESOURCE_ID \
     --http-method GET \
     --authorization-type NONE
   
   # Create Lambda integration
   aws apigateway put-integration \
     --rest-api-id $API_ID \
     --resource-id $RESOURCE_ID \
     --http-method GET \
     --type AWS_PROXY \
     --integration-http-method POST \
     --uri arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:ACCOUNT_ID:function:multi-trigger-lambda/invocations
   
   # Add Lambda permission for API Gateway
   aws lambda add-permission \
     --function-name multi-trigger-lambda \
     --statement-id api-gateway-invoke \
     --action lambda:InvokeFunction \
     --principal apigateway.amazonaws.com \
     --source-arn "arn:aws:execute-api:us-east-1:ACCOUNT_ID:$API_ID/*/*"
   
   # Deploy API
   aws apigateway create-deployment \
     --rest-api-id $API_ID \
     --stage-name prod
   ```

**Screenshot Placeholder**:
![Lambda Multi-Trigger Function](screenshots/16-lambda-multi-trigger.png)
*Caption: Lambda function with multiple event sources*

### Practice 3: Step Functions Workflow
**Objective**: Create workflow to orchestrate Lambda functions

**Steps**:
1. **Create Step Functions State Machine**:
   ```bash
   # Create state machine definition
   cat > state-machine.json << 'EOF'
   {
     "Comment": "A simple workflow to process data",
     "StartAt": "ValidateInput",
     "States": {
       "ValidateInput": {
         "Type": "Task",
         "Resource": "arn:aws:lambda:us-east-1:ACCOUNT_ID:function:validate-input",
         "Next": "ProcessData",
         "Catch": [
           {
             "ErrorEquals": ["States.TaskFailed"],
             "Next": "HandleError"
           }
         ]
       },
       "ProcessData": {
         "Type": "Parallel",
         "Branches": [
           {
             "StartAt": "ProcessA",
             "States": {
               "ProcessA": {
                 "Type": "Task",
                 "Resource": "arn:aws:lambda:us-east-1:ACCOUNT_ID:function:process-a",
                 "End": true
               }
             }
           },
           {
             "StartAt": "ProcessB",
             "States": {
               "ProcessB": {
                 "Type": "Task",
                 "Resource": "arn:aws:lambda:us-east-1:ACCOUNT_ID:function:process-b",
                 "End": true
               }
             }
           }
         ],
         "Next": "CombineResults"
       },
       "CombineResults": {
         "Type": "Task",
         "Resource": "arn:aws:lambda:us-east-1:ACCOUNT_ID:function:combine-results",
         "End": true
       },
       "HandleError": {
         "Type": "Task",
         "Resource": "arn:aws:lambda:us-east-1:ACCOUNT_ID:function:handle-error",
         "End": true
       }
     }
   }
   EOF
   
   # Create Step Functions execution role
   cat > stepfunctions-role.json << 'EOF'
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Principal": {
           "Service": "states.amazonaws.com"
         },
         "Action": "sts:AssumeRole"
       }
     ]
   }
   EOF
   
   aws iam create-role \
     --role-name stepfunctions-execution-role \
     --assume-role-policy-document file://stepfunctions-role.json
   
   aws iam attach-role-policy \
     --role-name stepfunctions-execution-role \
     --policy-arn arn:aws:iam::aws:policy/service-role/AWSStepFunctionsFullAccess
   
   # Create state machine
   aws stepfunctions create-state-machine \
     --name data-processing-workflow \
     --definition file://state-machine.json \
     --role-arn arn:aws:iam::ACCOUNT_ID:role/stepfunctions-execution-role
   ```

**Screenshot Placeholder**:
![Step Functions Workflow](screenshots/16-step-functions-workflow.png)
*Caption: Step Functions state machine with parallel processing*

## 📊 Comparison: Containers vs Serverless

| Aspect | ECS/EKS | Fargate | Lambda |
|--------|---------|---------|--------|
| **Management** | Manage EC2 instances | Serverless containers | Fully serverless |
| **Scaling** | Manual/Auto Scaling | Automatic | Automatic |
| **Pricing** | EC2 + ECS (free) | Pay for resources | Pay per request |
| **Cold Start** | No | Minimal | Yes |
| **Runtime** | Any containerized app | Any containerized app | 15 minutes max |
| **Use Case** | Long-running services | Microservices | Event processing |

## 🏗️ Architecture Patterns

### Microservices with ECS Fargate
```
[ALB] → [ECS Service A] → [RDS]
      → [ECS Service B] → [ElastiCache]
      → [ECS Service C] → [S3]
```

### Event-Driven with Lambda
```
[S3] → [Lambda] → [DynamoDB]
[SQS] → [Lambda] → [SNS]
[API Gateway] → [Lambda] → [RDS]
```

### Hybrid Architecture
```
[CloudFront] → [API Gateway] → [Lambda] → [ECS Fargate] → [RDS]
                            → [Step Functions] → [Lambda]
```

## ✅ Best Practices

### Container Best Practices
- **Image optimization**: Use multi-stage builds
- **Security**: Scan images for vulnerabilities
- **Logging**: Use structured logging
- **Health checks**: Implement proper health endpoints
- **Resource limits**: Set CPU and memory limits

### Lambda Best Practices
- **Function size**: Keep functions small and focused
- **Cold starts**: Use provisioned concurrency for critical functions
- **Environment variables**: Use for configuration
- **Error handling**: Implement proper error handling and retries
- **Monitoring**: Use CloudWatch and X-Ray for observability

### Step Functions Best Practices
- **State design**: Keep states simple and focused
- **Error handling**: Use Catch and Retry mechanisms
- **Parallel processing**: Use Parallel states for independent tasks
- **Input/Output**: Use InputPath and OutputPath for data transformation
- **Monitoring**: Monitor execution metrics and errors

## 🔗 Additional Resources

- [ECS Best Practices Guide](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/)
- [Lambda Best Practices](https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html)
- [Step Functions Developer Guide](https://docs.aws.amazon.com/step-functions/latest/dg/)
- [Container Security Best Practices](https://aws.amazon.com/blogs/containers/)

---

## 🚀 Complete Deployment Guide

**See**: [Complete-Deployment-Guide.md](Complete-Deployment-Guide.md) for detailed step-by-step instructions

### Quick Start Commands
```bash
# 1. Deploy Lambda function
./deploy-lambda.sh

# 2. Setup ECS infrastructure
./deploy-ecs.sh

# 3. Build and push Docker image
./build-push-image.sh

# 4. Create ECS service
./create-ecs-service.sh

# 5. Test everything
./health-checks.sh
```

### Verification Commands
```bash
# Lambda test
aws lambda invoke --function-name multi-trigger-lambda response.json

# ECS endpoint test
curl http://PUBLIC_IP:5000/
curl http://PUBLIC_IP:5000/health

# Service status
aws ecs describe-services --cluster my-fargate-cluster --services my-ecs-service
```

## 📸 Screenshots Checklist
- [x] ECS Fargate service deployment
- [x] Lambda function with multiple triggers
- [ ] Step Functions visual workflow
- [x] Container logs in CloudWatch
- [ ] API Gateway integration testing

## ✅ Section Completion
- [x] Understand ECS vs Fargate vs Lambda
- [x] Deploy containerized application with Fargate
- [x] Create multi-trigger Lambda function
- [ ] Build Step Functions workflow
- [x] Compare container and serverless architectures
- [x] Implement monitoring and logging
- [x] Apply security best practicesstId': context.aws_request_id,
               'timestamp': datetime.now().isoformat()
           })
       }
   
   def handle_s3_event(event, context):
       processed_objects = []
       
       for record in event['Records']:
           bucket = record['s3']['bucket']['name']
           key = record['s3']['object']['key']
           event_name = record['eventName']
           
           processed_objects.append({
               'bucket': bucket,
               'key': key,
               'event': event_name
           })
       
       return {
           'statusCode': 200,
           'body': json.dumps({
               'message': 'S3 events processed',
               'objects': processed_objects,
               'timestamp': datetime.now().isoformat()
           })
       }
   
   def handle_sqs_event(event, context):
       processed_messages = []
       
       for record in event['Records']:
           message_body = record['body']
           processed_messages.append({
               'messageId': record['messageId'],
               'body': message_body
           })
       
       return {
           'statusCode': 200,
           'body': json.dumps({
               'message': 'SQS messages processed',
               'messages': processed_messages,
               'timestamp': datetime.now().isoformat()
           })
       }
   
   def handle_scheduled_event(event, context):
       return {
           'statusCode': 200,
           'body': json.dumps({
               'message': 'Scheduled event processed',
               'rule': event.get('detail-type', 'Unknown'),
               'timestamp': datetime.now().isoformat()
           })
       }
   EOF
   
   # Create deployment package
   zip lambda_function.zip lambda_function.py
   
   # Create Lambda function
   aws lambda create-function \
     --function-name multi-trigger-lambda \
     --runtime python3.9 \
     --role arn:aws:iam::ACCOUNT_ID:role/lambda-execution-role \
     --handler lambda_function.lambda_handler \
     --zip-file fileb://lambda_function.zip \
     --timeout 30 \
     --memory-size 256
   ```

2. **Create Multiple Triggers**:
   ```bash
   # Create API Gateway trigger
   API_ID=$(aws apigateway create-rest-api \
     --name 'lambda-multi-trigger-api' \
     --query 'id' --output text)
   
   ROOT_RESOURCE_ID=$(aws apigateway get-resources \
     --rest-api-id $API_ID \
     --query 'items[0].id' --output text)
   
   # Create ANY method
   aws apigateway put-method \
     --rest-api-id $API_ID \
     --resource-id $ROOT_RESOURCE_ID \
     --http-method ANY \
     --authorization-type NONE
   
   # Create Lambda integration
   LAMBDA_ARN=$(aws lambda get-function \
     --function-name multi-trigger-lambda \
     --query 'Configuration.FunctionArn' --output text)
   
   aws apigateway put-integration \
     --rest-api-id $API_ID \
     --resource-id $ROOT_RESOURCE_ID \
     --http-method ANY \
     --type AWS_PROXY \
     --integration-http-method POST \
     --uri "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/$LAMBDA_ARN/invocations"
   
   # Grant API Gateway permission
   aws lambda add-permission \
     --function-name multi-trigger-lambda \
     --statement-id api-gateway-any \
     --action lambda:InvokeFunction \
     --principal apigateway.amazonaws.com \
     --source-arn "arn:aws:execute-api:us-east-1:ACCOUNT_ID:$API_ID/*/*"
   
   # Deploy API
   aws apigateway create-deployment \
     --rest-api-id $API_ID \
     --stage-name prod
   
   # Create S3 trigger
   aws s3 mb s3://lambda-trigger-bucket-12345
   
   aws lambda add-permission \
     --function-name multi-trigger-lambda \
     --statement-id s3-trigger \
     --action lambda:InvokeFunction \
     --principal s3.amazonaws.com \
     --source-arn arn:aws:s3:::lambda-trigger-bucket-12345
   
   # Add S3 event notification
   cat > s3-notification.json << 'EOF'
   {
     "LambdaConfigurations": [
       {
         "Id": "lambda-trigger",
         "LambdaFunctionArn": "LAMBDA_ARN_HERE",
         "Events": ["s3:ObjectCreated:*"]
       }
     ]
   }
   EOF
   
   aws s3api put-bucket-notification-configuration \
     --bucket lambda-trigger-bucket-12345 \
     --notification-configuration file://s3-notification.json
   
   # Create CloudWatch Events trigger
   aws events put-rule \
     --name lambda-scheduled-rule \
     --schedule-expression "rate(5 minutes)"
   
   aws lambda add-permission \
     --function-name multi-trigger-lambda \
     --statement-id cloudwatch-events \
     --action lambda:InvokeFunction \
     --principal events.amazonaws.com \
     --source-arn arn:aws:events:us-east-1:ACCOUNT_ID:rule/lambda-scheduled-rule
   
   aws events put-targets \
     --rule lambda-scheduled-rule \
     --targets "Id"="1","Arn"="$LAMBDA_ARN"
   ```

3. **Test Lambda Triggers**:
   ```bash
   # Test API Gateway trigger
   API_URL="https://$API_ID.execute-api.us-east-1.amazonaws.com/prod"
   curl -X GET "$API_URL/"
   
   # Test S3 trigger
   echo "Test file content" > test-file.txt
   aws s3 cp test-file.txt s3://lambda-trigger-bucket-12345/
   
   # Check CloudWatch Logs
   aws logs describe-log-groups \
     --log-group-name-prefix /aws/lambda/multi-trigger-lambda
   
   aws logs get-log-events \
     --log-group-name /aws/lambda/multi-trigger-lambda \
     --log-stream-name "$(aws logs describe-log-streams \
       --log-group-name /aws/lambda/multi-trigger-lambda \
       --order-by LastEventTime --descending \
       --max-items 1 --query 'logStreams[0].logStreamName' --output text)"
   ```

**Screenshot Placeholder**:
![Lambda Multiple Triggers](screenshots/16-lambda-multiple-triggers.png)
*Caption: Lambda function with API Gateway, S3, and CloudWatch Events triggers*

### Practice 3: Step Functions Workflow
**Objective**: Create Step Functions state machine for order processing

**Steps**:
1. **Create Lambda Functions for Workflow**:
   ```bash
   # Create validate order function
   cat > validate_order.py << 'EOF'
   import json
   import random
   
   def lambda_handler(event, context):
       order = event['order']
       
       # Simulate validation logic
       is_valid = random.choice([True, True, True, False])  # 75% success rate
       
       if is_valid:
           return {
               'statusCode': 200,
               'order': order,
               'validation': {
                   'status': 'valid',
                   'message': 'Order validation successful'
               }
           }
       else:
           raise Exception('Order validation failed: Invalid product or quantity')
   EOF
   
   # Create process payment function
   cat > process_payment.py << 'EOF'
   import json
   import random
   import time
   
   def lambda_handler(event, context):
       order = event['order']
       
       # Simulate payment processing
       time.sleep(2)  # Simulate processing time
       
       payment_success = random.choice([True, True, False])  # 67% success rate
       
       if payment_success:
           return {
               'statusCode': 200,
               'order': order,
               'payment': {
                   'status': 'completed',
                   'transaction_id': f'txn_{random.randint(100000, 999999)}',
                   'amount': order.get('amount', 0)
               }
           }
       else:
           raise Exception('Payment processing failed: Insufficient funds')
   EOF
   
   # Create fulfill order function
   cat > fulfill_order.py << 'EOF'
   import json
   import random
   
   def lambda_handler(event, context):
       order = event['order']
       payment = event['payment']
       
       # Simulate order fulfillment
       tracking_number = f'TRK{random.randint(1000000, 9999999)}'
       
       return {
           'statusCode': 200,
           'order': order,
           'payment': payment,
           'fulfillment': {
               'status': 'shipped',
               'tracking_number': tracking_number,
               'estimated_delivery': '3-5 business days'
           }
       }
   EOF
   
   # Create and deploy functions
   for func in validate_order process_payment fulfill_order; do
     zip ${func}.zip ${func}.py
     aws lambda create-function \
       --function-name ${func} \
       --runtime python3.9 \
       --role arn:aws:iam::ACCOUNT_ID:role/lambda-execution-role \
       --handler ${func}.lambda_handler \
       --zip-file fileb://${func}.zip
   done
   ```

2. **Create Step Functions State Machine**:
   ```bash
   # Create IAM role for Step Functions
   cat > stepfunctions-role.json << 'EOF'
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Principal": {
           "Service": "states.amazonaws.com"
         },
         "Action": "sts:AssumeRole"
       }
     ]
   }
   EOF
   
   aws iam create-role \
     --role-name StepFunctionsExecutionRole \
     --assume-role-policy-document file://stepfunctions-role.json
   
   # Attach Lambda invoke policy
   cat > stepfunctions-policy.json << 'EOF'
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "lambda:InvokeFunction"
         ],
         "Resource": "*"
       }
     ]
   }
   EOF
   
   aws iam put-role-policy \
     --role-name StepFunctionsExecutionRole \
     --policy-name LambdaInvokePolicy \
     --policy-document file://stepfunctions-policy.json
   
   # Create state machine definition
   cat > order-processing-workflow.json << 'EOF'
   {
     "Comment": "Order processing workflow",
     "StartAt": "ValidateOrder",
     "States": {
       "ValidateOrder": {
         "Type": "Task",
         "Resource": "arn:aws:lambda:us-east-1:ACCOUNT_ID:function:validate_order",
         "Retry": [
           {
             "ErrorEquals": ["States.TaskFailed"],
             "IntervalSeconds": 2,
             "MaxAttempts": 2,
             "BackoffRate": 2.0
           }
         ],
         "Catch": [
           {
             "ErrorEquals": ["States.ALL"],
             "Next": "OrderValidationFailed"
           }
         ],
         "Next": "ProcessPayment"
       },
       "ProcessPayment": {
         "Type": "Task",
         "Resource": "arn:aws:lambda:us-east-1:ACCOUNT_ID:function:process_payment",
         "Retry": [
           {
             "ErrorEquals": ["States.TaskFailed"],
             "IntervalSeconds": 5,
             "MaxAttempts": 3,
             "BackoffRate": 2.0
           }
         ],
         "Catch": [
           {
             "ErrorEquals": ["States.ALL"],
             "Next": "PaymentFailed"
           }
         ],
         "Next": "FulfillOrder"
       },
       "FulfillOrder": {
         "Type": "Task",
         "Resource": "arn:aws:lambda:us-east-1:ACCOUNT_ID:function:fulfill_order",
         "End": true
       },
       "OrderValidationFailed": {
         "Type": "Fail",
         "Cause": "Order validation failed"
       },
       "PaymentFailed": {
         "Type": "Fail",
         "Cause": "Payment processing failed"
       }
     }
   }
   EOF
   
   # Create state machine
   ROLE_ARN=$(aws iam get-role \
     --role-name StepFunctionsExecutionRole \
     --query 'Role.Arn' --output text)
   
   aws stepfunctions create-state-machine \
     --name order-processing-workflow \
     --definition file://order-processing-workflow.json \
     --role-arn $ROLE_ARN
   ```

3. **Execute Step Functions Workflow**:
   ```bash
   # Get state machine ARN
   STATE_MACHINE_ARN=$(aws stepfunctions list-state-machines \
     --query 'stateMachines[?name==`order-processing-workflow`].stateMachineArn' \
     --output text)
   
   # Create test input
   cat > test-order.json << 'EOF'
   {
     "order": {
       "orderId": "ORD-12345",
       "customerId": "CUST-67890",
       "items": [
         {
           "productId": "PROD-001",
           "quantity": 2,
           "price": 29.99
         }
       ],
       "amount": 59.98,
       "currency": "USD"
     }
   }
   EOF
   
   # Start execution
   EXECUTION_ARN=$(aws stepfunctions start-execution \
     --state-machine-arn $STATE_MACHINE_ARN \
     --name "test-execution-$(date +%s)" \
     --input file://test-order.json \
     --query 'executionArn' --output text)
   
   # Monitor execution
   aws stepfunctions describe-execution \
     --execution-arn $EXECUTION_ARN
   
   # Get execution history
   aws stepfunctions get-execution-history \
     --execution-arn $EXECUTION_ARN
   ```

**Screenshot Placeholder**:
![Step Functions Workflow](screenshots/16-step-functions-workflow.png)
*Caption: Step Functions state machine for order processing workflow*

### Practice 4: EKS Cluster Setup
**Objective**: Create EKS cluster and deploy application

**Steps**:
1. **Create EKS Cluster**:
   ```bash
   # Install eksctl (if not already installed)
   curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
   sudo mv /tmp/eksctl /usr/local/bin
   
   # Create EKS cluster
   eksctl create cluster \
     --name my-eks-cluster \
     --version 1.28 \
     --region us-east-1 \
     --nodegroup-name standard-workers \
     --node-type t3.medium \
     --nodes 2 \
     --nodes-min 1 \
     --nodes-max 4 \
     --managed
   
   # Update kubeconfig
   aws eks update-kubeconfig \
     --region us-east-1 \
     --name my-eks-cluster
   
   # Verify cluster
   kubectl get nodes
   ```

2. **Deploy Application to EKS**:
   ```bash
   # Create Kubernetes deployment
   cat > k8s-deployment.yaml << 'EOF'
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: web-app
     labels:
       app: web-app
   spec:
     replicas: 3
     selector:
       matchLabels:
         app: web-app
     template:
       metadata:
         labels:
           app: web-app
       spec:
         containers:
         - name: web-app
           image: nginx:1.21
           ports:
           - containerPort: 80
           env:
           - name: ENVIRONMENT
             value: "production"
           resources:
             requests:
               memory: "64Mi"
               cpu: "250m"
             limits:
               memory: "128Mi"
               cpu: "500m"
   ---
   apiVersion: v1
   kind: Service
   metadata:
     name: web-app-service
   spec:
     selector:
       app: web-app
     ports:
     - protocol: TCP
       port: 80
       targetPort: 80
     type: LoadBalancer
   EOF
   
   # Deploy application
   kubectl apply -f k8s-deployment.yaml
   
   # Wait for deployment
   kubectl rollout status deployment/web-app
   
   # Get service details
   kubectl get services web-app-service
   
   # Test application
   LOAD_BALANCER_URL=$(kubectl get service web-app-service \
     -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
   
   curl http://$LOAD_BALANCER_URL
   ```

3. **Configure Auto Scaling**:
   ```bash
   # Create HPA (Horizontal Pod Autoscaler)
   cat > hpa.yaml << 'EOF'
   apiVersion: autoscaling/v2
   kind: HorizontalPodAutoscaler
   metadata:
     name: web-app-hpa
   spec:
     scaleTargetRef:
       apiVersion: apps/v1
       kind: Deployment
       name: web-app
     minReplicas: 2
     maxReplicas: 10
     metrics:
     - type: Resource
       resource:
         name: cpu
         target:
           type: Utilization
           averageUtilization: 70
     - type: Resource
       resource:
         name: memory
         target:
           type: Utilization
           averageUtilization: 80
   EOF
   
   kubectl apply -f hpa.yaml
   
   # Check HPA status
   kubectl get hpa
   ```

**Screenshot Placeholder**:
![EKS Cluster Deployment](screenshots/16-eks-cluster-deployment.png)
*Caption: EKS cluster with deployed application and auto-scaling*

### Practice 5: Lambda Layers and Environment Variables
**Objective**: Create Lambda function with layers and configuration

**Steps**:
1. **Create Lambda Layer**:
   ```bash
   # Create layer directory structure
   mkdir -p lambda-layer/python/lib/python3.9/site-packages
   cd lambda-layer
   
   # Install dependencies
   pip install requests pandas -t python/lib/python3.9/site-packages/
   
   # Create layer package
   zip -r my-lambda-layer.zip python/
   
   # Create layer
   aws lambda publish-layer-version \
     --layer-name my-python-layer \
     --description "Common Python libraries" \
     --zip-file fileb://my-lambda-layer.zip \
     --compatible-runtimes python3.9
   
   cd ..
   ```

2. **Create Lambda Function with Layer**:
   ```bash
   # Create function code
   cat > layer_function.py << 'EOF'
   import json
   import requests
   import pandas as pd
   import os
   from datetime import datetime
   
   def lambda_handler(event, context):
       # Get environment variables
       api_key = os.environ.get('API_KEY', 'default-key')
       environment = os.environ.get('ENVIRONMENT', 'dev')
       debug_mode = os.environ.get('DEBUG', 'false').lower() == 'true'
       
       # Sample data processing with pandas
       data = {
           'timestamp': [datetime.now().isoformat()],
           'environment': [environment],
           'request_id': [context.aws_request_id]
       }
       
       df = pd.DataFrame(data)
       
       # Make HTTP request (using requests from layer)
       try:
           response = requests.get('https://httpbin.org/json')
           external_data = response.json()
       except Exception as e:
           external_data = {'error': str(e)}
       
       result = {
           'statusCode': 200,
           'body': json.dumps({
               'message': 'Function executed successfully',
               'environment': environment,
               'debug_mode': debug_mode,
               'dataframe_info': df.to_dict('records'),
               'external_data': external_data,
               'function_version': context.function_version
           })
       }
       
       if debug_mode:
           result['body'] = json.dumps({
               **json.loads(result['body']),
               'debug_info': {
                   'memory_limit': context.memory_limit_in_mb,
                   'remaining_time': context.get_remaining_time_in_millis(),
                   'log_group': context.log_group_name
               }
           })
       
       return result
   EOF
   
   # Create deployment package
   zip layer_function.zip layer_function.py
   
   # Get layer ARN
   LAYER_ARN=$(aws lambda list-layer-versions \
     --layer-name my-python-layer \
     --query 'LayerVersions[0].LayerVersionArn' --output text)
   
   # Create function with layer and environment variables
   aws lambda create-function \
     --function-name layer-demo-function \
     --runtime python3.9 \
     --role arn:aws:iam::ACCOUNT_ID:role/lambda-execution-role \
     --handler layer_function.lambda_handler \
     --zip-file fileb://layer_function.zip \
     --layers $LAYER_ARN \
     --environment Variables='{
       "API_KEY": "prod-api-key-12345",
       "ENVIRONMENT": "production",
       "DEBUG": "true"
     }' \
     --timeout 30 \
     --memory-size 512
   ```

3. **Test and Monitor Function**:
   ```bash
   # Test function
   aws lambda invoke \
     --function-name layer-demo-function \
     --payload '{"test": "data"}' \
     response.json
   
   cat response.json
   
   # Update environment variables
   aws lambda update-function-configuration \
     --function-name layer-demo-function \
     --environment Variables='{
       "API_KEY": "updated-api-key-67890",
       "ENVIRONMENT": "production",
       "DEBUG": "false"
     }'
   
   # Create alias for version management
   aws lambda publish-version \
     --function-name layer-demo-function \
     --description "Production version with updated config"
   
   aws lambda create-alias \
     --function-name layer-demo-function \
     --name PROD \
     --function-version 1
   
   # Test alias
   aws lambda invoke \
     --function-name layer-demo-function:PROD \
     --payload '{"test": "production"}' \
     prod-response.json
   ```

**Screenshot Placeholder**:
![Lambda Layers Configuration](screenshots/16-lambda-layers-config.png)
*Caption: Lambda function with layers and environment variables*

### Practice 6: Container Insights and Monitoring
**Objective**: Enable monitoring for containerized applications

**Steps**:
1. **Enable Container Insights for ECS**:
   ```bash
   # Enable Container Insights for ECS cluster
   aws ecs put-account-setting \
     --name containerInsights \
     --value enabled
   
   # Update cluster to enable Container Insights
   aws ecs modify-cluster \
     --cluster my-fargate-cluster \
     --settings name=containerInsights,value=enabled
   
   # Create CloudWatch dashboard
   cat > ecs-dashboard.json << 'EOF'
   {
     "widgets": [
       {
         "type": "metric",
         "properties": {
           "metrics": [
             ["AWS/ECS", "CPUUtilization", "ServiceName", "my-ecs-service", "ClusterName", "my-fargate-cluster"],
             [".", "MemoryUtilization", ".", ".", ".", "."]
           ],
           "period": 300,
           "stat": "Average",
           "region": "us-east-1",
           "title": "ECS Service Metrics"
         }
       },
       {
         "type": "log",
         "properties": {
           "query": "SOURCE '/ecs/my-ecs-app'\n| fields @timestamp, @message\n| sort @timestamp desc\n| limit 100",
           "region": "us-east-1",
           "title": "ECS Application Logs"
         }
       }
     ]
   }
   EOF
   
   aws cloudwatch put-dashboard \
     --dashboard-name ECS-Monitoring \
     --dashboard-body file://ecs-dashboard.json
   ```

2. **Set Up Lambda Monitoring**:
   ```bash
   # Create CloudWatch alarms for Lambda
   aws cloudwatch put-metric-alarm \
     --alarm-name lambda-error-rate \
     --alarm-description "Lambda function error rate" \
     --metric-name Errors \
     --namespace AWS/Lambda \
     --statistic Sum \
     --period 300 \
     --threshold 5 \
     --comparison-operator GreaterThanThreshold \
     --dimensions Name=FunctionName,Value=multi-trigger-lambda \
     --evaluation-periods 2
   
   aws cloudwatch put-metric-alarm \
     --alarm-name lambda-duration \
     --alarm-description "Lambda function duration" \
     --metric-name Duration \
     --namespace AWS/Lambda \
     --statistic Average \
     --period 300 \
     --threshold 10000 \
     --comparison-operator GreaterThanThreshold \
     --dimensions Name=FunctionName,Value=multi-trigger-lambda \
     --evaluation-periods 2
   
   # Enable X-Ray tracing
   aws lambda update-function-configuration \
     --function-name multi-trigger-lambda \
     --tracing-config Mode=Active
   ```

**Screenshot Placeholder**:
![Container Monitoring Dashboard](screenshots/16-container-monitoring.png)
*Caption: CloudWatch Container Insights dashboard for ECS and Lambda*

## ✅ Section Completion Checklist

- [ ] Deployed containerized application using ECS Fargate
- [ ] Created Lambda function with multiple triggers
- [ ] Built Step Functions workflow for order processing
- [ ] Set up EKS cluster and deployed Kubernetes application
- [ ] Implemented Lambda layers and environment variables
- [ ] Configured Container Insights and monitoring
- [ ] Tested auto-scaling for both containers and serverless
- [ ] Verified cost optimization strategies
- [ ] Monitored performance metrics and logs

## 🎯 Key Takeaways

- **Serverless vs Containers**: Choose based on workload characteristics
- **ECS Fargate**: Serverless containers without EC2 management
- **Lambda**: Event-driven, pay-per-request serverless compute
- **Step Functions**: Orchestrate complex workflows with error handling
- **EKS**: Managed Kubernetes for container orchestration
- **Monitoring**: Use Container Insights and CloudWatch for observability
- **Cost Optimization**: Right-size resources and use appropriate pricing models

## 📚 Additional Resources

- [AWS Container Services](https://aws.amazon.com/containers/)
- [Amazon ECS Developer Guide](https://docs.aws.amazon.com/ecs/)
- [AWS Lambda Developer Guide](https://docs.aws.amazon.com/lambda/)
- [AWS Step Functions Developer Guide](https://docs.aws.amazon.com/step-functions/)
- [Amazon EKS User Guide](https://docs.aws.amazon.com/eks/)
- [Container and Serverless Best Practices](https://aws.amazon.com/architecture/well-architected/)