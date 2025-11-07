# Section 15: Application Integration

## 📋 Overview
This section covers AWS Application Integration services that enable decoupled, scalable architectures including messaging, streaming, and API management services.

## 🔄 Amazon SQS (Simple Queue Service)

### What is SQS?
- **Managed message queuing**: Fully managed service
- **Decoupling**: Separate application components
- **Scalability**: Handle millions of messages
- **Reliability**: Message durability and delivery
- **Cost-effective**: Pay per use model

### SQS Queue Types
- **Standard Queue**: Best-effort ordering, at-least-once delivery
- **FIFO Queue**: First-in-first-out ordering, exactly-once processing
- **Dead Letter Queue**: Handle failed message processing

## 📢 Amazon SNS (Simple Notification Service)

### What is SNS?
- **Pub/Sub messaging**: Publisher-subscriber pattern
- **Multiple subscribers**: Fan-out messaging
- **Multiple protocols**: SMS, email, HTTP, SQS, Lambda
- **Message filtering**: Topic-based filtering
- **Mobile push**: iOS, Android notifications

## 🌊 Amazon Kinesis

### Kinesis Services
- **Kinesis Data Streams**: Real-time data streaming
- **Kinesis Data Firehose**: Data delivery to destinations
- **Kinesis Data Analytics**: Real-time analytics
- **Kinesis Video Streams**: Video streaming and analytics

## 🚪 Amazon API Gateway

### What is API Gateway?
- **API management**: Create, deploy, manage APIs
- **Serverless**: No infrastructure management
- **Security**: Authentication, authorization, throttling
- **Monitoring**: CloudWatch integration
- **Caching**: Response caching for performance

## 🛠️ Hands-On Practice

### Practice 1: SQS Standard and FIFO Queues
**Objective**: Create and test SQS standard and FIFO queues

**Steps**:
1. **Create Standard Queue**:
   ```bash
   # Create standard queue
   aws sqs create-queue \
     --queue-name my-standard-queue \
     --attributes '{
       "VisibilityTimeoutSeconds": "300",
       "MessageRetentionPeriod": "1209600",
       "MaxReceiveCount": "3"
     }'
   
   # Get queue URL
   STANDARD_QUEUE_URL=$(aws sqs get-queue-url \
     --queue-name my-standard-queue \
     --query 'QueueUrl' --output text)
   
   # Send messages to standard queue
   for i in {1..10}; do
     aws sqs send-message \
       --queue-url $STANDARD_QUEUE_URL \
       --message-body "Standard message $i" \
       --message-attributes '{
         "MessageType": {
           "StringValue": "Standard",
           "DataType": "String"
         },
         "Priority": {
           "StringValue": "'$i'",
           "DataType": "Number"
         }
       }'
   done
   ```

2. **Create FIFO Queue**:
   ```bash
   # Create FIFO queue
   aws sqs create-queue \
     --queue-name my-fifo-queue.fifo \
     --attributes '{
       "FifoQueue": "true",
       "ContentBasedDeduplication": "true",
       "VisibilityTimeoutSeconds": "300"
     }'
   
   # Get FIFO queue URL
   FIFO_QUEUE_URL=$(aws sqs get-queue-url \
     --queue-name my-fifo-queue.fifo \
     --query 'QueueUrl' --output text)
   
   # Send messages to FIFO queue
   for i in {1..5}; do
     aws sqs send-message \
       --queue-url $FIFO_QUEUE_URL \
       --message-body "FIFO message $i" \
       --message-group-id "group1" \
       --message-deduplication-id "msg-$i-$(date +%s)"
   done
   ```

3. **Test Message Processing**:
   ```bash
   # Create message processor script
   cat > process_messages.py << 'EOF'
   import boto3
   import json
   import time
   
   sqs = boto3.client('sqs')
   
   def process_standard_queue(queue_url):
       print("Processing Standard Queue...")
       while True:
           response = sqs.receive_message(
               QueueUrl=queue_url,
               MaxNumberOfMessages=10,
               WaitTimeSeconds=5,
               MessageAttributeNames=['All']
           )
           
           messages = response.get('Messages', [])
           if not messages:
               break
               
           for message in messages:
               print(f"Standard: {message['Body']}")
               # Delete message after processing
               sqs.delete_message(
                   QueueUrl=queue_url,
                   ReceiptHandle=message['ReceiptHandle']
               )
           time.sleep(1)
   
   def process_fifo_queue(queue_url):
       print("Processing FIFO Queue...")
       while True:
           response = sqs.receive_message(
               QueueUrl=queue_url,
               MaxNumberOfMessages=10,
               WaitTimeSeconds=5
           )
           
           messages = response.get('Messages', [])
           if not messages:
               break
               
           for message in messages:
               print(f"FIFO: {message['Body']}")
               # Delete message after processing
               sqs.delete_message(
                   QueueUrl=queue_url,
                   ReceiptHandle=message['ReceiptHandle']
               )
           time.sleep(1)
   
   if __name__ == "__main__":
       standard_url = "STANDARD_QUEUE_URL_HERE"
       fifo_url = "FIFO_QUEUE_URL_HERE"
       
       process_standard_queue(standard_url)
       process_fifo_queue(fifo_url)
   EOF
   
   # Run processor
   python3 process_messages.py
   ```

**Screenshot Placeholder**:
![SQS Queues Setup](screenshots/15-sqs-queues-setup.png)
*Caption: SQS Standard and FIFO queues configuration*

### Practice 2: SNS Topic with Multiple Subscribers
**Objective**: Create SNS topic with SQS, Lambda, and email subscribers

**Steps**:
1. **Create SNS Topic**:
   ```bash
   # Create SNS topic
   aws sns create-topic --name my-notification-topic
   
   # Get topic ARN
   TOPIC_ARN=$(aws sns list-topics \
     --query 'Topics[?contains(TopicArn, `my-notification-topic`)].TopicArn' \
     --output text)
   
   echo "Topic ARN: $TOPIC_ARN"
   ```

2. **Create Subscribers**:
   ```bash
   # Create SQS queue for SNS messages
   aws sqs create-queue --queue-name sns-subscriber-queue
   
   SUBSCRIBER_QUEUE_URL=$(aws sqs get-queue-url \
     --queue-name sns-subscriber-queue \
     --query 'QueueUrl' --output text)
   
   # Get queue ARN
   QUEUE_ARN=$(aws sqs get-queue-attributes \
     --queue-url $SUBSCRIBER_QUEUE_URL \
     --attribute-names QueueArn \
     --query 'Attributes.QueueArn' --output text)
   
   # Subscribe SQS to SNS
   aws sns subscribe \
     --topic-arn $TOPIC_ARN \
     --protocol sqs \
     --notification-endpoint $QUEUE_ARN
   
   # Subscribe email to SNS
   aws sns subscribe \
     --topic-arn $TOPIC_ARN \
     --protocol email \
     --notification-endpoint your-email@example.com
   
   # Set SQS policy to allow SNS
   cat > sqs-policy.json << EOF
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Principal": {
           "Service": "sns.amazonaws.com"
         },
         "Action": "sqs:SendMessage",
         "Resource": "$QUEUE_ARN",
         "Condition": {
           "ArnEquals": {
             "aws:SourceArn": "$TOPIC_ARN"
           }
         }
       }
     ]
   }
   EOF
   
   aws sqs set-queue-attributes \
     --queue-url $SUBSCRIBER_QUEUE_URL \
     --attributes file://sqs-policy.json
   ```

3. **Test SNS Publishing**:
   ```bash
   # Publish test messages
   aws sns publish \
     --topic-arn $TOPIC_ARN \
     --message "Test notification message" \
     --subject "Test Subject"
   
   # Publish with message attributes
   aws sns publish \
     --topic-arn $TOPIC_ARN \
     --message "Priority alert message" \
     --subject "Priority Alert" \
     --message-attributes '{
       "priority": {
         "DataType": "String",
         "StringValue": "high"
       },
       "source": {
         "DataType": "String", 
         "StringValue": "monitoring"
       }
     }'
   
   # Check SQS queue for messages
   aws sqs receive-message \
     --queue-url $SUBSCRIBER_QUEUE_URL \
     --max-number-of-messages 10
   ```

**Screenshot Placeholder**:
![SNS Topic Subscribers](screenshots/15-sns-topic-subscribers.png)
*Caption: SNS topic with multiple subscriber types*

### Practice 3: Kinesis Data Stream
**Objective**: Create Kinesis data stream for real-time data processing

**Steps**:
1. **Create Kinesis Stream**:
   ```bash
   # Create Kinesis stream
   aws kinesis create-stream \
     --stream-name my-data-stream \
     --shard-count 2
   
   # Wait for stream to be active
   aws kinesis wait stream-exists \
     --stream-name my-data-stream
   
   # Describe stream
   aws kinesis describe-stream \
     --stream-name my-data-stream
   ```

2. **Create Data Producer**:
   ```bash
   # Create producer script
   cat > kinesis_producer.py << 'EOF'
   import boto3
   import json
   import time
   import random
   from datetime import datetime
   
   kinesis = boto3.client('kinesis')
   
   def generate_sample_data():
       return {
           'timestamp': datetime.now().isoformat(),
           'user_id': random.randint(1000, 9999),
           'event_type': random.choice(['login', 'purchase', 'view', 'logout']),
           'amount': round(random.uniform(10.0, 500.0), 2),
           'location': random.choice(['US', 'EU', 'ASIA'])
       }
   
   def put_record(stream_name, data):
       response = kinesis.put_record(
           StreamName=stream_name,
           Data=json.dumps(data),
           PartitionKey=str(data['user_id'])
       )
       return response
   
   if __name__ == "__main__":
       stream_name = 'my-data-stream'
       
       print("Starting data producer...")
       for i in range(100):
           data = generate_sample_data()
           response = put_record(stream_name, data)
           print(f"Record {i+1}: {data['event_type']} - {response['ShardId']}")
           time.sleep(0.1)
   EOF
   
   # Run producer
   python3 kinesis_producer.py
   ```

3. **Create Data Consumer**:
   ```bash
   # Create consumer script
   cat > kinesis_consumer.py << 'EOF'
   import boto3
   import json
   import time
   
   kinesis = boto3.client('kinesis')
   
   def get_shard_iterator(stream_name, shard_id):
       response = kinesis.get_shard_iterator(
           StreamName=stream_name,
           ShardId=shard_id,
           ShardIteratorType='LATEST'
       )
       return response['ShardIterator']
   
   def consume_records(stream_name):
       # Get stream description
       response = kinesis.describe_stream(StreamName=stream_name)
       shards = response['StreamDescription']['Shards']
       
       # Get shard iterators
       shard_iterators = {}
       for shard in shards:
           shard_id = shard['ShardId']
           shard_iterators[shard_id] = get_shard_iterator(stream_name, shard_id)
       
       print("Starting data consumer...")
       while True:
           for shard_id, iterator in shard_iterators.items():
               if iterator:
                   response = kinesis.get_records(ShardIterator=iterator)
                   records = response['Records']
                   
                   for record in records:
                       data = json.loads(record['Data'])
                       print(f"Shard {shard_id}: {data}")
                   
                   # Update iterator
                   shard_iterators[shard_id] = response.get('NextShardIterator')
           
           time.sleep(1)
   
   if __name__ == "__main__":
       consume_records('my-data-stream')
   EOF
   
   # Run consumer
   python3 kinesis_consumer.py
   ```

**Screenshot Placeholder**:
![Kinesis Data Stream](screenshots/15-kinesis-data-stream.png)
*Caption: Kinesis data stream with producer and consumer*

### Practice 4: API Gateway with Lambda Integration
**Objective**: Create REST API with Lambda backend

**Steps**:
1. **Create Lambda Function**:
   ```bash
   # Create Lambda function code
   cat > lambda_function.py << 'EOF'
   import json
   import boto3
   from datetime import datetime
   
   def lambda_handler(event, context):
       # Get HTTP method and path
       http_method = event['httpMethod']
       path = event['path']
       
       # Get query parameters
       query_params = event.get('queryStringParameters') or {}
       
       # Get request body
       body = event.get('body')
       if body:
           try:
               body = json.loads(body)
           except:
               body = {}
       
       # Process request based on method
       if http_method == 'GET' and path == '/users':
           return {
               'statusCode': 200,
               'headers': {
                   'Content-Type': 'application/json',
                   'Access-Control-Allow-Origin': '*'
               },
               'body': json.dumps({
                   'users': [
                       {'id': 1, 'name': 'John Doe', 'email': 'john@example.com'},
                       {'id': 2, 'name': 'Jane Smith', 'email': 'jane@example.com'}
                   ],
                   'timestamp': datetime.now().isoformat()
               })
           }
       
       elif http_method == 'POST' and path == '/users':
           return {
               'statusCode': 201,
               'headers': {
                   'Content-Type': 'application/json',
                   'Access-Control-Allow-Origin': '*'
               },
               'body': json.dumps({
                   'message': 'User created successfully',
                   'user': body,
                   'timestamp': datetime.now().isoformat()
               })
           }
       
       else:
           return {
               'statusCode': 404,
               'headers': {
                   'Content-Type': 'application/json',
                   'Access-Control-Allow-Origin': '*'
               },
               'body': json.dumps({
                   'error': 'Not Found',
                   'message': f'Path {path} not found'
               })
           }
   EOF
   
   # Create deployment package
   zip lambda_function.zip lambda_function.py
   
   # Create Lambda function
   aws lambda create-function \
     --function-name api-gateway-backend \
     --runtime python3.9 \
     --role arn:aws:iam::ACCOUNT_ID:role/lambda-execution-role \
     --handler lambda_function.lambda_handler \
     --zip-file fileb://lambda_function.zip
   ```

2. **Create API Gateway**:
   ```bash
   # Create REST API
   API_ID=$(aws apigateway create-rest-api \
     --name 'my-user-api' \
     --description 'User management API' \
     --query 'id' --output text)
   
   # Get root resource ID
   ROOT_RESOURCE_ID=$(aws apigateway get-resources \
     --rest-api-id $API_ID \
     --query 'items[0].id' --output text)
   
   # Create /users resource
   USERS_RESOURCE_ID=$(aws apigateway create-resource \
     --rest-api-id $API_ID \
     --parent-id $ROOT_RESOURCE_ID \
     --path-part users \
     --query 'id' --output text)
   
   # Create GET method
   aws apigateway put-method \
     --rest-api-id $API_ID \
     --resource-id $USERS_RESOURCE_ID \
     --http-method GET \
     --authorization-type NONE
   
   # Create POST method
   aws apigateway put-method \
     --rest-api-id $API_ID \
     --resource-id $USERS_RESOURCE_ID \
     --http-method POST \
     --authorization-type NONE
   ```

3. **Configure Lambda Integration**:
   ```bash
   # Get Lambda function ARN
   LAMBDA_ARN=$(aws lambda get-function \
     --function-name api-gateway-backend \
     --query 'Configuration.FunctionArn' --output text)
   
   # Create Lambda integration for GET
   aws apigateway put-integration \
     --rest-api-id $API_ID \
     --resource-id $USERS_RESOURCE_ID \
     --http-method GET \
     --type AWS_PROXY \
     --integration-http-method POST \
     --uri "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/$LAMBDA_ARN/invocations"
   
   # Create Lambda integration for POST
   aws apigateway put-integration \
     --rest-api-id $API_ID \
     --resource-id $USERS_RESOURCE_ID \
     --http-method POST \
     --type AWS_PROXY \
     --integration-http-method POST \
     --uri "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/$LAMBDA_ARN/invocations"
   
   # Grant API Gateway permission to invoke Lambda
   aws lambda add-permission \
     --function-name api-gateway-backend \
     --statement-id api-gateway-invoke \
     --action lambda:InvokeFunction \
     --principal apigateway.amazonaws.com \
     --source-arn "arn:aws:execute-api:us-east-1:ACCOUNT_ID:$API_ID/*/*"
   
   # Deploy API
   aws apigateway create-deployment \
     --rest-api-id $API_ID \
     --stage-name prod
   
   # Test API
   API_URL="https://$API_ID.execute-api.us-east-1.amazonaws.com/prod"
   curl -X GET "$API_URL/users"
   curl -X POST "$API_URL/users" \
     -H "Content-Type: application/json" \
     -d '{"name": "New User", "email": "newuser@example.com"}'
   ```

**Screenshot Placeholder**:
![API Gateway Lambda Integration](screenshots/15-api-gateway-lambda.png)
*Caption: API Gateway with Lambda backend integration*

### Practice 5: SQS Dead Letter Queue
**Objective**: Implement dead letter queue for failed message processing

**Steps**:
1. **Create Dead Letter Queue**:
   ```bash
   # Create dead letter queue
   aws sqs create-queue --queue-name my-dlq
   
   DLQ_URL=$(aws sqs get-queue-url \
     --queue-name my-dlq \
     --query 'QueueUrl' --output text)
   
   DLQ_ARN=$(aws sqs get-queue-attributes \
     --queue-url $DLQ_URL \
     --attribute-names QueueArn \
     --query 'Attributes.QueueArn' --output text)
   ```

2. **Create Main Queue with DLQ**:
   ```bash
   # Create main queue with DLQ configuration
   aws sqs create-queue \
     --queue-name my-main-queue \
     --attributes '{
       "VisibilityTimeoutSeconds": "30",
       "RedrivePolicy": "{\"deadLetterTargetArn\":\"'$DLQ_ARN'\",\"maxReceiveCount\":3}"
     }'
   
   MAIN_QUEUE_URL=$(aws sqs get-queue-url \
     --queue-name my-main-queue \
     --query 'QueueUrl' --output text)
   ```

3. **Test DLQ Functionality**:
   ```bash
   # Send test message
   aws sqs send-message \
     --queue-url $MAIN_QUEUE_URL \
     --message-body "Test message for DLQ"
   
   # Create failing processor
   cat > failing_processor.py << 'EOF'
   import boto3
   import time
   
   sqs = boto3.client('sqs')
   
   def process_with_failure(queue_url):
       while True:
           response = sqs.receive_message(
               QueueUrl=queue_url,
               MaxNumberOfMessages=1,
               WaitTimeSeconds=5
           )
           
           messages = response.get('Messages', [])
           if not messages:
               break
               
           for message in messages:
               print(f"Processing: {message['Body']}")
               # Simulate processing failure - don't delete message
               print("Processing failed - message will be retried")
               time.sleep(2)
   
   if __name__ == "__main__":
       main_queue_url = "MAIN_QUEUE_URL_HERE"
       process_with_failure(main_queue_url)
   EOF
   
   # Run failing processor multiple times to trigger DLQ
   python3 failing_processor.py
   
   # Check DLQ for failed messages
   aws sqs receive-message \
     --queue-url $DLQ_URL \
     --max-number-of-messages 10
   ```

**Screenshot Placeholder**:
![SQS Dead Letter Queue](screenshots/15-sqs-dead-letter-queue.png)
*Caption: SQS dead letter queue configuration and testing*

### Practice 6: Kinesis Data Firehose
**Objective**: Set up Kinesis Data Firehose for data delivery to S3

**Steps**:
1. **Create S3 Bucket for Firehose**:
   ```bash
   # Create S3 bucket
   aws s3 mb s3://my-firehose-data-bucket-12345
   
   # Create IAM role for Firehose
   cat > firehose-role-policy.json << 'EOF'
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Principal": {
           "Service": "firehose.amazonaws.com"
         },
         "Action": "sts:AssumeRole"
       }
     ]
   }
   EOF
   
   aws iam create-role \
     --role-name firehose-delivery-role \
     --assume-role-policy-document file://firehose-role-policy.json
   
   # Attach S3 permissions
   cat > firehose-s3-policy.json << 'EOF'
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "s3:AbortMultipartUpload",
           "s3:GetBucketLocation",
           "s3:GetObject",
           "s3:ListBucket",
           "s3:ListBucketMultipartUploads",
           "s3:PutObject"
         ],
         "Resource": [
           "arn:aws:s3:::my-firehose-data-bucket-12345",
           "arn:aws:s3:::my-firehose-data-bucket-12345/*"
         ]
       }
     ]
   }
   EOF
   
   aws iam put-role-policy \
     --role-name firehose-delivery-role \
     --policy-name S3DeliveryPolicy \
     --policy-document file://firehose-s3-policy.json
   ```

2. **Create Firehose Delivery Stream**:
   ```bash
   # Get role ARN
   FIREHOSE_ROLE_ARN=$(aws iam get-role \
     --role-name firehose-delivery-role \
     --query 'Role.Arn' --output text)
   
   # Create delivery stream
   aws firehose create-delivery-stream \
     --delivery-stream-name my-s3-delivery-stream \
     --delivery-stream-type DirectPut \
     --s3-destination-configuration '{
       "RoleARN": "'$FIREHOSE_ROLE_ARN'",
       "BucketARN": "arn:aws:s3:::my-firehose-data-bucket-12345",
       "Prefix": "year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/",
       "ErrorOutputPrefix": "errors/",
       "BufferingHints": {
         "SizeInMBs": 5,
         "IntervalInSeconds": 300
       },
       "CompressionFormat": "GZIP"
     }'
   ```

3. **Send Data to Firehose**:
   ```bash
   # Create data sender script
   cat > firehose_sender.py << 'EOF'
   import boto3
   import json
   import time
   import random
   from datetime import datetime
   
   firehose = boto3.client('firehose')
   
   def generate_log_data():
       return {
           'timestamp': datetime.now().isoformat(),
           'level': random.choice(['INFO', 'WARN', 'ERROR']),
           'service': random.choice(['web-server', 'api-server', 'database']),
           'message': f'Sample log message {random.randint(1000, 9999)}',
           'user_id': random.randint(1, 1000),
           'request_id': f'req-{random.randint(100000, 999999)}'
       }
   
   def send_to_firehose(stream_name, data):
       response = firehose.put_record(
           DeliveryStreamName=stream_name,
           Record={'Data': json.dumps(data) + '\n'}
       )
       return response
   
   if __name__ == "__main__":
       stream_name = 'my-s3-delivery-stream'
       
       print("Sending data to Firehose...")
       for i in range(50):
           data = generate_log_data()
           response = send_to_firehose(stream_name, data)
           print(f"Record {i+1}: {data['level']} - {response['RecordId']}")
           time.sleep(0.5)
   EOF
   
   # Send data
   python3 firehose_sender.py
   
   # Check S3 bucket for delivered data (after 5 minutes)
   aws s3 ls s3://my-firehose-data-bucket-12345/ --recursive
   ```

**Screenshot Placeholder**:
![Kinesis Data Firehose](screenshots/15-kinesis-firehose.png)
*Caption: Kinesis Data Firehose delivery to S3*

## ✅ Section Completion Checklist

- [ ] Created and tested SQS standard and FIFO queues
- [ ] Implemented SNS topic with multiple subscribers
- [ ] Set up Kinesis Data Stream with producer/consumer
- [ ] Created API Gateway with Lambda integration
- [ ] Configured SQS Dead Letter Queue
- [ ] Implemented Kinesis Data Firehose to S3
- [ ] Tested message ordering and delivery guarantees
- [ ] Verified API Gateway throttling and caching
- [ ] Monitored application integration metrics

## 🎯 Key Takeaways

- **Decoupling**: Use SQS/SNS for loose coupling between components
- **Ordering**: Choose FIFO queues when message order matters
- **Fan-out**: Use SNS for broadcasting messages to multiple subscribers
- **Real-time**: Use Kinesis for streaming data processing
- **API Management**: API Gateway provides comprehensive API lifecycle management
- **Error Handling**: Implement dead letter queues for failed message processing
- **Data Delivery**: Use Firehose for reliable data delivery to storage services

## 📚 Additional Resources

- [AWS Application Integration Services](https://aws.amazon.com/products/application-integration/)
- [Amazon SQS Developer Guide](https://docs.aws.amazon.com/sqs/)
- [Amazon SNS Developer Guide](https://docs.aws.amazon.com/sns/)
- [Amazon Kinesis Developer Guide](https://docs.aws.amazon.com/kinesis/)
- [API Gateway Developer Guide](https://docs.aws.amazon.com/apigateway/)
- [Application Integration Best Practices](https://aws.amazon.com/architecture/well-architected/)