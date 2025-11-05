# Section 10: Classic Solution Architecture Discussion

## 📋 Overview
This section discusses classic solution architectures commonly used in AWS. You'll learn about architectural patterns, best practices, and how to design scalable, reliable, and cost-effective solutions using AWS services.

## 🏗️ Architectural Principles

### AWS Well-Architected Framework
1. **Operational Excellence**: Run and monitor systems effectively
2. **Security**: Protect information and systems
3. **Reliability**: Recover from failures and meet demand
4. **Performance Efficiency**: Use resources efficiently
5. **Cost Optimization**: Avoid unnecessary costs
6. **Sustainability**: Minimize environmental impact

### Design Principles
- **Design for failure**: Assume components will fail
- **Decouple components**: Reduce dependencies
- **Implement elasticity**: Scale up and down automatically
- **Think parallel**: Distribute workload across resources
- **Leverage managed services**: Reduce operational overhead

## 🌐 Classic Architecture Patterns

### 1. Three-Tier Web Application
**Components**:
- **Presentation Tier**: Web servers (EC2 + ALB)
- **Application Tier**: Application servers (EC2 + Auto Scaling)
- **Data Tier**: Database (RDS Multi-AZ)

**Architecture**:
```
Internet → CloudFront → ALB → EC2 (Web) → ALB → EC2 (App) → RDS
                                ↓
                           ElastiCache
```

### 2. Serverless Web Application
**Components**:
- **Frontend**: S3 + CloudFront
- **API**: API Gateway + Lambda
- **Database**: DynamoDB
- **Authentication**: Cognito

**Architecture**:
```
S3/CloudFront → API Gateway → Lambda → DynamoDB
                    ↓
                 Cognito
```

### 3. Microservices Architecture
**Components**:
- **Container Orchestration**: ECS/EKS
- **Service Discovery**: Service Mesh
- **API Gateway**: Centralized API management
- **Databases**: Per-service databases

**Architecture**:
```
API Gateway → ALB → ECS/EKS Services → Individual Databases
                         ↓
                    Service Mesh
```

## 🛠️ Hands-On Practice

### Practice 1: Three-Tier Web Application
**Objective**: Build a classic three-tier architecture

**Steps**:
1. **Set Up Database Tier**:
   ```bash
   # Create DB subnet group first (use subnets from same VPC, different AZs)
   aws rds create-db-subnet-group \
     --db-subnet-group-name webapp-db-subnet-group \
     --db-subnet-group-description "Subnet group for webapp database" \
     --subnet-ids subnet-054f50111f554ae40 subnet-03c66f5952eb34f44
   
   # Create RDS MySQL instance
   aws rds create-db-instance \
     --db-instance-identifier webapp-db \
     --db-instance-class db.t3.micro \
     --engine mysql \
     --master-username admin \
     --master-user-password YourPassword123 \
     --allocated-storage 20 \
     --vpc-security-group-ids sg-xxxxxxxxx \
     --db-subnet-group-name webapp-db-subnet-group \
     --multi-az \
     --storage-encrypted
   ```

2. **Create Application Tier (Ubuntu)**:
   ```bash
   # Launch template for app servers
   cat > app-server-ubuntu.sh << 'EOF'
   #!/bin/bash
   apt update -y
   apt install -y python3 python3-pip mysql-client
   
   # Install Flask application
   pip3 install flask mysql-connector-python
   
   # Create simple Flask app
   cat > /home/ubuntu/app.py << 'PYEOF'
   from flask import Flask, jsonify
   import mysql.connector
   import os
   
   app = Flask(__name__)
   
   @app.route('/')
   def home():
       return jsonify({
           'message': 'Application Tier - Ubuntu',
           'server': os.uname().nodename,
           'status': 'healthy'
       })
   
   @app.route('/health')
   def health():
       return jsonify({'status': 'healthy'})
   
   @app.route('/data')
   def get_data():
       try:
           return jsonify({'message': 'Database connection test', 'status': 'ok'})
       except Exception as e:
           return jsonify({'error': str(e)})
   
   if __name__ == '__main__':
       app.run(host='0.0.0.0', port=5000)
   PYEOF
   
   # Start the application
   cd /home/ubuntu
   nohup python3 app.py > app.log 2>&1 &
   EOF
   
   # Create launch template
   aws ec2 create-launch-template \
     --launch-template-name webapp-app-template \
     --launch-template-data '{
       "ImageId": "ami-0c398cb65a93047f2",
       "InstanceType": "t3.micro",
       "KeyName": "demouserNvirginia",
       "SecurityGroupIds": ["sg-0b3eac0d1434f78a4"],
       "UserData": "'$(base64 -w 0 app-server-ubuntu.sh)'"
     }'
   ```

3. **Create Presentation Tier (Ubuntu)**:
   ```bash
   # Web server user data
   cat > web-server-ubuntu.sh << 'EOF'
   #!/bin/bash
   apt update -y
   apt install -y apache2
   systemctl start apache2
   systemctl enable apache2
   
   # Enable proxy modules
   a2enmod proxy
   a2enmod proxy_http
   
   # Create simple web interface
   cat > /var/www/html/index.html << 'HTMLEOF'
   <!DOCTYPE html>
   <html>
   <head>
       <title>Three-Tier Web App - Ubuntu</title>
       <style>
           body { font-family: Arial, sans-serif; margin: 40px; }
           .tier { background: #f0f0f0; padding: 20px; margin: 10px 0; border-radius: 5px; }
           button { padding: 10px 20px; margin: 5px; cursor: pointer; }
           .success { color: green; }
           .error { color: red; }
       </style>
   </head>
   <body>
       <h1>Three-Tier Web Application - Ubuntu</h1>
       
       <div class="tier">
           <h2>Presentation Tier</h2>
           <p>This is the web server tier serving static content on Ubuntu.</p>
       </div>
       
       <div class="tier">
           <h2>Application Tier</h2>
           <button onclick="callAppTier()">Call Application Tier</button>
           <div id="app-response"></div>
       </div>
       
       <div class="tier">
           <h2>Database Tier</h2>
           <button onclick="callDatabase()">Get Database Info</button>
           <div id="db-response"></div>
       </div>
       
       <script>
           async function callAppTier() {
               try {
                   const response = await fetch('/api/');
                   const data = await response.json();
                   document.getElementById('app-response').innerHTML = 
                       '<pre class="success">' + JSON.stringify(data, null, 2) + '</pre>';
               } catch (error) {
                   document.getElementById('app-response').innerHTML = 
                       '<div class="error">Error: ' + error + '</div>';
               }
           }
           
           async function callDatabase() {
               try {
                   const response = await fetch('/api/data');
                   const data = await response.json();
                   document.getElementById('db-response').innerHTML = 
                       '<pre class="success">' + JSON.stringify(data, null, 2) + '</pre>';
               } catch (error) {
                   document.getElementById('db-response').innerHTML = 
                       '<div class="error">Error: ' + error + '</div>';
               }
           }
       </script>
   </body>
   </html>
   HTMLEOF
   
   # Configure reverse proxy to app tier
   cat > /etc/apache2/sites-available/proxy.conf << 'PROXYEOF'
   <VirtualHost *:80>
       ProxyPreserveHost On
       ProxyPass /api/ http://internal-webapp-app-alb-691614125.us-east-1.elb.amazonaws.com/
       ProxyPassReverse /api/ http://internal-webapp-app-alb-691614125.us-east-1.elb.amazonaws.com/
   </VirtualHost>
   PROXYEOF
   
   a2ensite proxy
   systemctl restart apache2
   EOF
   
   # Create launch template
   aws ec2 create-launch-template \
     --launch-template-name webapp-web-template \
     --launch-template-data '{
       "ImageId": "ami-0c398cb65a93047f2",
       "InstanceType": "t3.micro",
       "KeyName": "demouserNvirginia",
       "SecurityGroupIds": ["sg-08cbf47e233407f64"],
       "UserData": "'$(base64 -w 0 web-server-ubuntu.sh)'"
     }'
   ```

4. **Set Up Load Balancers and Auto Scaling**:
   ```bash
   # Create Application Load Balancer for Web Tier
   aws elbv2 create-load-balancer \
     --name webapp-web-alb \
     --subnets subnet-12345678 subnet-87654321 \
     --security-groups sg-web-alb \
     --scheme internet-facing \
     --type application \
     --ip-address-type ipv4
   
   # Create target group for web tier
   aws elbv2 create-target-group \
     --name webapp-web-tg \
     --protocol HTTP \
     --port 80 \
     --vpc-id vpc-12345678 \
     --health-check-path / \
     --health-check-interval-seconds 30 \
     --health-check-timeout-seconds 5 \
     --healthy-threshold-count 2 \
     --unhealthy-threshold-count 3
   
   # Create listener for web ALB
   aws elbv2 create-listener \
     --load-balancer-arn arn:aws:elasticloadbalancing:region:account:loadbalancer/app/webapp-web-alb/1234567890123456 \
     --protocol HTTP \
     --port 80 \
     --default-actions Type=forward,TargetGroupArn=arn:aws:elasticloadbalancing:region:account:targetgroup/webapp-web-tg/1234567890123456
   
   # Create Application Load Balancer for App Tier
   aws elbv2 create-load-balancer \
     --name webapp-app-alb \
     --subnets subnet-private1 subnet-private2 \
     --security-groups sg-app-alb \
     --scheme internal \
     --type application
   
   # Create target group for app tier
   aws elbv2 create-target-group \
     --name webapp-app-tg \
     --protocol HTTP \
     --port 5000 \
     --vpc-id vpc-12345678 \
     --health-check-path /health \
     --health-check-interval-seconds 30
   
   # Create listener for app ALB
   aws elbv2 create-listener \
     --load-balancer-arn arn:aws:elasticloadbalancing:region:account:loadbalancer/app/webapp-app-alb/1234567890123456 \
     --protocol HTTP \
     --port 80 \
     --default-actions Type=forward,TargetGroupArn=arn:aws:elasticloadbalancing:region:account:targetgroup/webapp-app-tg/1234567890123456
   
   # Create Auto Scaling Group for Web Tier
   aws autoscaling create-auto-scaling-group \
     --auto-scaling-group-name webapp-web-asg \
     --launch-template LaunchTemplateName=webapp-web-template,Version=1 \
     --min-size 2 \
     --max-size 6 \
     --desired-capacity 2 \
     --target-group-arns arn:aws:elasticloadbalancing:region:account:targetgroup/webapp-web-tg/1234567890123456 \
     --health-check-type ELB \
     --health-check-grace-period 300 \
     --vpc-zone-identifier "subnet-12345678,subnet-87654321"
   
   # Create Auto Scaling Group for App Tier
   aws autoscaling create-auto-scaling-group \
     --auto-scaling-group-name webapp-app-asg \
     --launch-template LaunchTemplateName=webapp-app-template,Version=1 \
     --min-size 2 \
     --max-size 8 \
     --desired-capacity 2 \
     --target-group-arns arn:aws:elasticloadbalancing:region:account:targetgroup/webapp-app-tg/1234567890123456 \
     --health-check-type ELB \
     --health-check-grace-period 300 \
     --vpc-zone-identifier "subnet-private1,subnet-private2"
   
   # Create scaling policies
   aws autoscaling put-scaling-policy \
     --auto-scaling-group-name webapp-web-asg \
     --policy-name webapp-web-scale-up \
     --policy-type TargetTrackingScaling \
     --target-tracking-configuration file://scale-up-policy.json
   
   # Create scale-up-policy.json
   cat > scale-up-policy.json << 'EOF'
   {
     "TargetValue": 70.0,
     "PredefinedMetricSpecification": {
       "PredefinedMetricType": "ASGAverageCPUUtilization"
     }
   }
   EOF
   
   # Create CloudWatch alarms for monitoring
   aws cloudwatch put-metric-alarm \
     --alarm-name webapp-high-cpu \
     --alarm-description "High CPU utilization" \
     --metric-name CPUUtilization \
     --namespace AWS/EC2 \
     --statistic Average \
     --period 300 \
     --threshold 80 \
     --comparison-operator GreaterThanThreshold \
     --evaluation-periods 2
   ```

5. **Verify the Architecture**:
   ```bash
   # Check RDS instance status
   aws rds describe-db-instances --db-instance-identifier webapp-db
   
   # Check load balancer status
   aws elbv2 describe-load-balancers --names webapp-web-alb webapp-app-alb
   
   # Check auto scaling groups
   aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names webapp-web-asg webapp-app-asg
   
   # Check target group health
   aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:region:account:targetgroup/webapp-web-tg/1234567890123456
   
   # Test the application
   curl http://webapp-web-alb-1234567890.region.elb.amazonaws.com/
   curl http://webapp-web-alb-1234567890.region.elb.amazonaws.com/api/
   curl http://webapp-web-alb-1234567890.region.elb.amazonaws.com/api/data
   ```

**Completion Checklist**:
- [ ] RDS MySQL instance created and running
- [ ] Application tier EC2 instances launched with Flask app
- [ ] Web tier EC2 instances launched with Apache
- [ ] Application Load Balancers created for both tiers
- [ ] Target groups configured with health checks
- [ ] Auto Scaling Groups configured with scaling policies
- [ ] Security groups properly configured
- [ ] Application accessible via web ALB URL
- [ ] Database connectivity tested

**Screenshot Placeholder**:
![Three-Tier Architecture](screenshots/10-three-tier-architecture.png)
*Caption: Three-tier web application architecture with load balancers and auto scaling*

### Practice 2: Serverless Web Application
**Objective**: Build a serverless web application

**Steps**:
1. **Create S3 Bucket for Frontend**:
   ```bash
   # Create S3 bucket
   aws s3 mb s3://my-serverless-webapp-bucket
   
   # Enable static website hosting
   aws s3 website s3://my-serverless-webapp-bucket \
     --index-document index.html \
     --error-document error.html
   
   # Create simple frontend
   cat > index.html << 'EOF'
   <!DOCTYPE html>
   <html>
   <head>
       <title>Serverless Web App</title>
       <style>
           body { font-family: Arial, sans-serif; margin: 40px; }
           .container { max-width: 800px; margin: 0 auto; }
           button { padding: 10px 20px; margin: 5px; cursor: pointer; }
           .response { background: #f0f0f0; padding: 15px; margin: 10px 0; }
       </style>
   </head>
   <body>
       <div class="container">
           <h1>Serverless Web Application</h1>
           
           <h2>API Gateway + Lambda</h2>
           <button onclick="callAPI()">Call Lambda Function</button>
           <div id="api-response" class="response"></div>
           
           <h2>DynamoDB</h2>
           <button onclick="getData()">Get Data from DynamoDB</button>
           <button onclick="postData()">Post Data to DynamoDB</button>
           <div id="db-response" class="response"></div>
       </div>
       
       <script>
           const API_URL = 'https://your-api-id.execute-api.region.amazonaws.com/prod';
           
           async function callAPI() {
               try {
                   const response = await fetch(API_URL + '/hello');
                   const data = await response.json();
                   document.getElementById('api-response').innerHTML = 
                       '<pre>' + JSON.stringify(data, null, 2) + '</pre>';
               } catch (error) {
                   document.getElementById('api-response').innerHTML = 'Error: ' + error;
               }
           }
           
           async function getData() {
               try {
                   const response = await fetch(API_URL + '/items');
                   const data = await response.json();
                   document.getElementById('db-response').innerHTML = 
                       '<pre>' + JSON.stringify(data, null, 2) + '</pre>';
               } catch (error) {
                   document.getElementById('db-response').innerHTML = 'Error: ' + error;
               }
           }
           
           async function postData() {
               try {
                   const response = await fetch(API_URL + '/items', {
                       method: 'POST',
                       headers: { 'Content-Type': 'application/json' },
                       body: JSON.stringify({
                           id: Date.now().toString(),
                           message: 'Hello from frontend!',
                           timestamp: new Date().toISOString()
                       })
                   });
                   const data = await response.json();
                   document.getElementById('db-response').innerHTML = 
                       '<pre>' + JSON.stringify(data, null, 2) + '</pre>';
               } catch (error) {
                   document.getElementById('db-response').innerHTML = 'Error: ' + error;
               }
           }
       </script>
   </body>
   </html>
   EOF
   
   # Upload to S3
   aws s3 cp index.html s3://my-serverless-webapp-bucket/
   ```

2. **Create DynamoDB Table**:
   ```bash
   # Create DynamoDB table
   aws dynamodb create-table \
     --table-name ServerlessAppData \
     --attribute-definitions \
       AttributeName=id,AttributeType=S \
     --key-schema \
       AttributeName=id,KeyType=HASH \
     --billing-mode PAY_PER_REQUEST
   ```

3. **Create Lambda Functions**:
   ```python
   # lambda_function.py
   import json
   import boto3
   from datetime import datetime
   
   dynamodb = boto3.resource('dynamodb')
   table = dynamodb.Table('ServerlessAppData')
   
   def lambda_handler(event, context):
       http_method = event['httpMethod']
       path = event['path']
       
       if path == '/hello':
           return {
               'statusCode': 200,
               'headers': {
                   'Access-Control-Allow-Origin': '*',
                   'Access-Control-Allow-Headers': 'Content-Type',
                   'Access-Control-Allow-Methods': 'GET, POST, OPTIONS'
               },
               'body': json.dumps({
                   'message': 'Hello from Lambda!',
                   'timestamp': datetime.now().isoformat(),
                   'method': http_method
               })
           }
       
       elif path == '/items':
           if http_method == 'GET':
               # Get items from DynamoDB
               response = table.scan()
               return {
                   'statusCode': 200,
                   'headers': {
                       'Access-Control-Allow-Origin': '*',
                       'Access-Control-Allow-Headers': 'Content-Type',
                       'Access-Control-Allow-Methods': 'GET, POST, OPTIONS'
                   },
                   'body': json.dumps(response['Items'])
               }
           
           elif http_method == 'POST':
               # Post item to DynamoDB
               body = json.loads(event['body'])
               table.put_item(Item=body)
               return {
                   'statusCode': 201,
                   'headers': {
                       'Access-Control-Allow-Origin': '*',
                       'Access-Control-Allow-Headers': 'Content-Type',
                       'Access-Control-Allow-Methods': 'GET, POST, OPTIONS'
                   },
                   'body': json.dumps({'message': 'Item created successfully'})
               }
       
       return {
           'statusCode': 404,
           'body': json.dumps({'error': 'Not found'})
       }
   ```

4. **Create API Gateway**:
   - Create REST API
   - Create resources and methods
   - Deploy API to stage
   - Enable CORS

**Screenshot Placeholder**:
![Serverless Architecture](screenshots/10-serverless-architecture.png)
*Caption: Serverless web application architecture*

### Practice 3: Disaster Recovery Architecture
**Objective**: Implement multi-region disaster recovery

**Architecture Overview**:
- **Primary Region**: us-east-1 (N. Virginia)
- **Secondary Region**: us-west-2 (Oregon)
- **RTO**: < 15 minutes
- **RPO**: < 5 minutes

**Step 1: Primary Region Setup (us-east-1)**

1. **Create VPC and Networking**:
   ```bash
   # Create VPC in primary region
   aws ec2 create-vpc \
     --cidr-block 10.0.0.0/16 \
     --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=DR-Primary-VPC}]' \
     --region us-east-1
   
   # Create subnets
   aws ec2 create-subnet \
     --vpc-id vpc-xxxxxxxxx \
     --cidr-block 10.0.1.0/24 \
     --availability-zone us-east-1a \
     --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=DR-Primary-Public-1a}]'
   
   aws ec2 create-subnet \
     --vpc-id vpc-xxxxxxxxx \
     --cidr-block 10.0.2.0/24 \
     --availability-zone us-east-1b \
     --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=DR-Primary-Public-1b}]'
   
   aws ec2 create-subnet \
     --vpc-id vpc-xxxxxxxxx \
     --cidr-block 10.0.11.0/24 \
     --availability-zone us-east-1a \
     --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=DR-Primary-Private-1a}]'
   
   aws ec2 create-subnet \
     --vpc-id vpc-xxxxxxxxx \
     --cidr-block 10.0.12.0/24 \
     --availability-zone us-east-1b \
     --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=DR-Primary-Private-1b}]'
   ```

2. **Create RDS with Automated Backups**:
   ```bash
   # Create DB subnet group
   aws rds create-db-subnet-group \
     --db-subnet-group-name dr-primary-subnet-group \
     --db-subnet-group-description "DR Primary DB Subnet Group" \
     --subnet-ids subnet-xxxxxxxxx subnet-yyyyyyyyy \
     --region us-east-1
   
   # Create RDS instance with automated backups
   aws rds create-db-instance \
     --db-instance-identifier webapp-db-primary \
     --db-instance-class db.t3.micro \
     --engine mysql \
     --engine-version 8.0.35 \
     --master-username admin \
     --master-user-password MySecurePassword123! \
     --allocated-storage 20 \
     --db-subnet-group-name dr-primary-subnet-group \
     --backup-retention-period 7 \
     --preferred-backup-window "03:00-04:00" \
     --preferred-maintenance-window "sun:04:00-sun:05:00" \
     --multi-az \
     --storage-encrypted \
     --region us-east-1
   ```

3. **Create S3 Bucket with Cross-Region Replication**:
   ```bash
   # Create primary S3 bucket
   aws s3 mb s3://webapp-dr-primary-bucket-$(date +%s) --region us-east-1
   
   # Enable versioning (required for replication)
   aws s3api put-bucket-versioning \
     --bucket webapp-dr-primary-bucket-$(date +%s) \
     --versioning-configuration Status=Enabled
   
   # Create IAM role for replication
   cat > replication-role-trust-policy.json << EOF
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Principal": {
           "Service": "s3.amazonaws.com"
         },
         "Action": "sts:AssumeRole"
       }
     ]
   }
   EOF
   
   aws iam create-role \
     --role-name S3ReplicationRole \
     --assume-role-policy-document file://replication-role-trust-policy.json
   
   # Create replication policy
   cat > replication-policy.json << EOF
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "s3:GetObjectVersionForReplication",
           "s3:GetObjectVersionAcl"
         ],
         "Resource": "arn:aws:s3:::webapp-dr-primary-bucket-*/*"
       },
       {
         "Effect": "Allow",
         "Action": [
           "s3:ListBucket"
         ],
         "Resource": "arn:aws:s3:::webapp-dr-primary-bucket-*"
       },
       {
         "Effect": "Allow",
         "Action": [
           "s3:ReplicateObject",
           "s3:ReplicateDelete"
         ],
         "Resource": "arn:aws:s3:::webapp-dr-secondary-bucket-*/*"
       }
     ]
   }
   EOF
   
   aws iam put-role-policy \
     --role-name S3ReplicationRole \
     --policy-name S3ReplicationPolicy \
     --policy-document file://replication-policy.json
   ```

4. **Deploy Application Stack**:
   ```bash
   # Create Application Load Balancer
   aws elbv2 create-load-balancer \
     --name webapp-dr-primary-alb \
     --subnets subnet-xxxxxxxxx subnet-yyyyyyyyy \
     --security-groups sg-xxxxxxxxx \
     --region us-east-1
   
   # Create Auto Scaling Group
   aws autoscaling create-auto-scaling-group \
     --auto-scaling-group-name webapp-dr-primary-asg \
     --launch-template LaunchTemplateName=webapp-launch-template \
     --min-size 2 \
     --max-size 6 \
     --desired-capacity 2 \
     --vpc-zone-identifier "subnet-xxxxxxxxx,subnet-yyyyyyyyy" \
     --health-check-type ELB \
     --health-check-grace-period 300
   ```

**Step 2: Secondary Region Setup (us-west-2)**

1. **Create Secondary S3 Bucket**:
   ```bash
   # Create secondary S3 bucket
   aws s3 mb s3://webapp-dr-secondary-bucket-$(date +%s) --region us-west-2
   
   # Enable versioning
   aws s3api put-bucket-versioning \
     --bucket webapp-dr-secondary-bucket-$(date +%s) \
     --versioning-configuration Status=Enabled
   ```

2. **Configure Cross-Region Replication**:
   ```bash
   # Create replication configuration
   cat > replication-config.json << EOF
   {
     "Role": "arn:aws:iam::ACCOUNT-ID:role/S3ReplicationRole",
     "Rules": [
       {
         "ID": "ReplicateEverything",
         "Status": "Enabled",
         "Priority": 1,
         "Filter": {
           "Prefix": ""
         },
         "Destination": {
           "Bucket": "arn:aws:s3:::webapp-dr-secondary-bucket-TIMESTAMP",
           "StorageClass": "STANDARD_IA"
         }
       }
     ]
   }
   EOF
   
   aws s3api put-bucket-replication \
     --bucket webapp-dr-primary-bucket-TIMESTAMP \
     --replication-configuration file://replication-config.json
   ```

3. **Create RDS Read Replica**:
   ```bash
   # Create VPC in secondary region
   aws ec2 create-vpc \
     --cidr-block 10.1.0.0/16 \
     --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=DR-Secondary-VPC}]' \
     --region us-west-2
   
   # Create subnets in secondary region
   aws ec2 create-subnet \
     --vpc-id vpc-xxxxxxxxx \
     --cidr-block 10.1.11.0/24 \
     --availability-zone us-west-2a \
     --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=DR-Secondary-Private-2a}]' \
     --region us-west-2
   
   aws ec2 create-subnet \
     --vpc-id vpc-xxxxxxxxx \
     --cidr-block 10.1.12.0/24 \
     --availability-zone us-west-2b \
     --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=DR-Secondary-Private-2b}]' \
     --region us-west-2
   
   # Create DB subnet group in secondary region
   aws rds create-db-subnet-group \
     --db-subnet-group-name dr-secondary-subnet-group \
     --db-subnet-group-description "DR Secondary DB Subnet Group" \
     --subnet-ids subnet-xxxxxxxxx subnet-yyyyyyyyy \
     --region us-west-2
   
   # Create cross-region read replica
   aws rds create-db-instance-read-replica \
     --db-instance-identifier webapp-db-replica \
     --source-db-instance-identifier arn:aws:rds:us-east-1:ACCOUNT-ID:db:webapp-db-primary \
     --db-instance-class db.t3.micro \
     --db-subnet-group-name dr-secondary-subnet-group \
     --region us-west-2
   ```

4. **Prepare Secondary Infrastructure**:
   ```bash
   # Create launch template for secondary region
   aws ec2 create-launch-template \
     --launch-template-name webapp-secondary-launch-template \
     --launch-template-data '{
       "ImageId": "ami-0c02fb55956c7d316",
       "InstanceType": "t3.micro",
       "SecurityGroupIds": ["sg-xxxxxxxxx"],
       "UserData": "IyEvYmluL2Jhc2gKZWNobyBcIlNlY29uZGFyeSBSZWdpb24gSW5zdGFuY2VcIiA+IC90bXAvaW5zdGFuY2VfaW5mby50eHQ="
     }' \
     --region us-west-2
   ```

**Step 3: Configure Route 53 Health Checks and Failover**

1. **Create Health Checks**:
   ```bash
   # Create health check for primary region
   aws route53 create-health-check \
     --caller-reference "primary-health-check-$(date +%s)" \
     --health-check-config '{
       "Type": "HTTP",
       "ResourcePath": "/health",
       "FullyQualifiedDomainName": "webapp-dr-primary-alb-XXXXXXXXX.us-east-1.elb.amazonaws.com",
       "Port": 80,
       "RequestInterval": 30,
       "FailureThreshold": 3
     }'
   
   # Create health check for secondary region
   aws route53 create-health-check \
     --caller-reference "secondary-health-check-$(date +%s)" \
     --health-check-config '{
       "Type": "HTTP",
       "ResourcePath": "/health",
       "FullyQualifiedDomainName": "webapp-dr-secondary-alb-XXXXXXXXX.us-west-2.elb.amazonaws.com",
       "Port": 80,
       "RequestInterval": 30,
       "FailureThreshold": 3
     }'
   ```

2. **Configure DNS Failover**:
   ```bash
   # Create hosted zone (if not exists)
   aws route53 create-hosted-zone \
     --name webapp-dr.example.com \
     --caller-reference "webapp-dr-$(date +%s)"
   
   # Create primary record with failover routing
   cat > primary-record.json << EOF
   {
     "Changes": [
       {
         "Action": "CREATE",
         "ResourceRecordSet": {
           "Name": "webapp-dr.example.com",
           "Type": "A",
           "SetIdentifier": "Primary",
           "Failover": "PRIMARY",
           "HealthCheckId": "HEALTH-CHECK-ID-PRIMARY",
           "AliasTarget": {
             "DNSName": "webapp-dr-primary-alb-XXXXXXXXX.us-east-1.elb.amazonaws.com",
             "EvaluateTargetHealth": true,
             "HostedZoneId": "Z35SXDOTRQ7X7K"
           }
         }
       }
     ]
   }
   EOF
   
   aws route53 change-resource-record-sets \
     --hosted-zone-id ZXXXXXXXXXXXXX \
     --change-batch file://primary-record.json
   
   # Create secondary record with failover routing
   cat > secondary-record.json << EOF
   {
     "Changes": [
       {
         "Action": "CREATE",
         "ResourceRecordSet": {
           "Name": "webapp-dr.example.com",
           "Type": "A",
           "SetIdentifier": "Secondary",
           "Failover": "SECONDARY",
           "AliasTarget": {
             "DNSName": "webapp-dr-secondary-alb-XXXXXXXXX.us-west-2.elb.amazonaws.com",
             "EvaluateTargetHealth": true,
             "HostedZoneId": "Z1D633PJN98FT9"
           }
         }
       }
     ]
   }
   EOF
   
   aws route53 change-resource-record-sets \
     --hosted-zone-id ZXXXXXXXXXXXXX \
     --change-batch file://secondary-record.json
   ```

**Step 4: Automated Failover Scripts**

1. **RDS Promotion Script**:
   ```bash
   #!/bin/bash
   # promote-replica.sh
   
   echo "Promoting RDS read replica to standalone instance..."
   aws rds promote-read-replica \
     --db-instance-identifier webapp-db-replica \
     --backup-retention-period 7 \
     --preferred-backup-window "03:00-04:00" \
     --region us-west-2
   
   echo "Waiting for promotion to complete..."
   aws rds wait db-instance-available \
     --db-instance-identifier webapp-db-replica \
     --region us-west-2
   
   echo "RDS promotion completed successfully!"
   ```

2. **Application Deployment Script**:
   ```bash
   #!/bin/bash
   # deploy-secondary.sh
   
   echo "Scaling up secondary region infrastructure..."
   
   # Create Auto Scaling Group in secondary region
   aws autoscaling create-auto-scaling-group \
     --auto-scaling-group-name webapp-dr-secondary-asg \
     --launch-template LaunchTemplateName=webapp-secondary-launch-template \
     --min-size 2 \
     --max-size 6 \
     --desired-capacity 2 \
     --vpc-zone-identifier "subnet-xxxxxxxxx,subnet-yyyyyyyyy" \
     --health-check-type ELB \
     --health-check-grace-period 300 \
     --region us-west-2
   
   # Create Application Load Balancer
   aws elbv2 create-load-balancer \
     --name webapp-dr-secondary-alb \
     --subnets subnet-xxxxxxxxx subnet-yyyyyyyyy \
     --security-groups sg-xxxxxxxxx \
     --region us-west-2
   
   echo "Secondary region deployment initiated!"
   ```

3. **Data Synchronization Verification**:
   ```bash
   #!/bin/bash
   # verify-sync.sh
   
   echo "Verifying S3 replication status..."
   aws s3api get-bucket-replication \
     --bucket webapp-dr-primary-bucket-TIMESTAMP
   
   echo "Checking RDS replica lag..."
   aws rds describe-db-instances \
     --db-instance-identifier webapp-db-replica \
     --query 'DBInstances[0].ReadReplicaSourceDBInstanceIdentifier' \
     --region us-west-2
   
   echo "Verification completed!"
   ```

**Step 5: Testing Disaster Recovery**

1. **Simulate Primary Region Failure**:
   ```bash
   # Stop primary region instances
   aws autoscaling update-auto-scaling-group \
     --auto-scaling-group-name webapp-dr-primary-asg \
     --desired-capacity 0 \
     --region us-east-1
   
   # Monitor Route 53 health check failure
   aws route53 get-health-check \
     --health-check-id HEALTH-CHECK-ID-PRIMARY
   ```

2. **Execute Failover**:
   ```bash
   # Run promotion and deployment scripts
   ./promote-replica.sh
   ./deploy-secondary.sh
   
   # Verify failover
   nslookup webapp-dr.example.com
   curl -I http://webapp-dr.example.com
   ```

**Monitoring and Alerting**:
```bash
# Create CloudWatch alarms
aws cloudwatch put-metric-alarm \
  --alarm-name "RDS-Replica-Lag" \
  --alarm-description "Monitor RDS replica lag" \
  --metric-name "ReplicaLag" \
  --namespace "AWS/RDS" \
  --statistic "Average" \
  --period 300 \
  --threshold 300 \
  --comparison-operator "GreaterThanThreshold" \
  --dimensions Name=DBInstanceIdentifier,Value=webapp-db-replica \
  --evaluation-periods 2

# Create SNS topic for alerts
aws sns create-topic --name dr-alerts
aws sns subscribe \
  --topic-arn arn:aws:sns:us-east-1:ACCOUNT-ID:dr-alerts \
  --protocol email \
  --notification-endpoint admin@example.com
```

**Screenshot Placeholder**:
![Disaster Recovery](screenshots/10-disaster-recovery.png)
*Caption: Multi-region disaster recovery architecture with automated failover*

### Practice 4: Microservices with Containers
**Objective**: Deploy microservices using ECS

**Steps**:
1. **Create Container Images**:
   ```dockerfile
   # User Service Dockerfile
   FROM python:3.9-slim
   WORKDIR /app
   COPY requirements.txt .
   RUN pip install -r requirements.txt
   COPY . .
   EXPOSE 5000
   CMD ["python", "app.py"]
   ```

2. **Set Up ECS Cluster**:
   ```bash
   # Create ECS cluster
   aws ecs create-cluster --cluster-name microservices-cluster
   
   # Create task definitions for each service
   # Create services with load balancers
   # Configure service discovery
   ```

3. **Implement Service Mesh**:
   - Deploy AWS App Mesh
   - Configure virtual nodes and services
   - Set up traffic routing
   - Implement observability

**Screenshot Placeholder**:
![Microservices Architecture](screenshots/10-microservices-architecture.png)
*Caption: Microservices architecture with containers*

## 🔧 Architecture Best Practices

### Security Best Practices
- **Defense in depth**: Multiple security layers
- **Least privilege**: Minimal required permissions
- **Encryption**: Data at rest and in transit
- **Network isolation**: VPC and security groups
- **Monitoring**: CloudTrail and GuardDuty

### Performance Best Practices
- **Caching**: ElastiCache and CloudFront
- **Content delivery**: Global edge locations
- **Database optimization**: Read replicas and indexing
- **Auto scaling**: Responsive to demand
- **Load balancing**: Distribute traffic efficiently

### Cost Optimization Best Practices
- **Right-sizing**: Appropriate instance types
- **Reserved capacity**: Long-term commitments
- **Spot instances**: Fault-tolerant workloads
- **Storage optimization**: Appropriate storage classes
- **Monitoring**: Cost and usage tracking

## 📊 Architecture Comparison

### Traditional vs Cloud-Native
| Aspect | Traditional | Cloud-Native |
|--------|-------------|--------------|
| Scaling | Manual | Automatic |
| Availability | Single AZ | Multi-AZ |
| Maintenance | Manual | Managed |
| Cost | Fixed | Variable |
| Deployment | Slow | Fast |

### Monolith vs Microservices
| Aspect | Monolith | Microservices |
|--------|----------|---------------|
| Complexity | Low | High |
| Scalability | Limited | High |
| Technology | Single | Multiple |
| Deployment | All-or-nothing | Independent |
| Debugging | Easier | Complex |

## 🚨 Common Architecture Mistakes

1. **Single points of failure**
2. **Inadequate monitoring and alerting**
3. **Poor security practices**
4. **Not planning for scale**
5. **Ignoring cost optimization**
6. **Tight coupling between components**
7. **Insufficient disaster recovery planning**

## 🔗 Additional Resources

- [AWS Architecture Center](https://aws.amazon.com/architecture/)
- [Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [AWS Solutions Library](https://aws.amazon.com/solutions/)
- [Reference Architectures](https://aws.amazon.com/architecture/reference-architecture-diagrams/)

## 📸 Screenshots Section
*Document your architecture implementations:*

### Screenshot 1: Three-Tier Architecture Diagram
![Three-Tier Diagram](screenshots/10-three-tier-diagram.png)
*Caption: Complete three-tier web application architecture*

### Screenshot 2: Serverless Architecture Flow
![Serverless Flow](screenshots/10-serverless-flow.png)
*Caption: Serverless application data flow*

### Screenshot 3: Microservices Dashboard
![Microservices Dashboard](screenshots/10-microservices-dashboard.png)
*Caption: ECS microservices cluster dashboard*

### Screenshot 4: DR Architecture
![DR Architecture](screenshots/10-dr-architecture.png)
*Caption: Multi-region disaster recovery setup*

### Screenshot 5: Performance Monitoring
![Performance Monitoring](screenshots/10-performance-monitoring.png)
*Caption: Architecture performance monitoring dashboard*

### Screenshot 6: Cost Analysis
![Cost Analysis](screenshots/10-cost-analysis.png)
*Caption: Architecture cost breakdown and optimization*

---

## ✅ Section Completion Checklist
- [ ] Understood AWS Well-Architected Framework principles
- [ ] Implemented three-tier web application architecture
- [ ] Built serverless web application with Lambda and DynamoDB
- [ ] Designed disaster recovery architecture
- [ ] Deployed microservices using containers
- [ ] Applied security and performance best practices
- [ ] Analyzed cost optimization opportunities
- [ ] Documented architecture decisions and trade-offs

## 🎯 Next Steps
Move to **Section 11: Amazon S3 Introduction - Advanced S3** to learn about object storage and advanced S3 features.

---

*Last Updated: January 2025*
*Course Version: 2025.1*

### Practice 2: Serverless Web Application - Complete Implementation
**Objective**: Build a serverless web application

**Steps**:
1. **Create S3 Bucket for Frontend**:
   ```bash
   aws s3 mb s3://my-serverless-webapp-bucket
   aws s3 website s3://my-serverless-webapp-bucket --index-document index.html
   
   cat > index.html << 'EOF'
   <!DOCTYPE html>
   <html>
   <head>
       <title>Serverless Web App</title>
       <style>
           body { font-family: Arial, sans-serif; margin: 40px; }
           .container { max-width: 800px; margin: 0 auto; }
           button { padding: 10px 20px; margin: 5px; cursor: pointer; }
           .response { background: #f0f0f0; padding: 15px; margin: 10px 0; }
       </style>
   </head>
   <body>
       <div class="container">
           <h1>Serverless Web Application</h1>
           <h2>API Gateway + Lambda</h2>
           <button onclick="callAPI()">Call Lambda Function</button>
           <div id="api-response" class="response"></div>
           <h2>DynamoDB</h2>
           <button onclick="getData()">Get Data</button>
           <button onclick="postData()">Post Data</button>
           <div id="db-response" class="response"></div>
       </div>
       <script>
           const API_URL = 'https://your-api-id.execute-api.region.amazonaws.com/prod';
           async function callAPI() {
               try {
                   const response = await fetch(API_URL + '/hello');
                   const data = await response.json();
                   document.getElementById('api-response').innerHTML = '<pre>' + JSON.stringify(data, null, 2) + '</pre>';
               } catch (error) {
                   document.getElementById('api-response').innerHTML = 'Error: ' + error;
               }
           }
           async function getData() {
               try {
                   const response = await fetch(API_URL + '/data');
                   const data = await response.json();
                   document.getElementById('db-response').innerHTML = '<pre>' + JSON.stringify(data, null, 2) + '</pre>';
               } catch (error) {
                   document.getElementById('db-response').innerHTML = 'Error: ' + error;
               }
           }
           async function postData() {
               try {
                   const response = await fetch(API_URL + '/data', {
                       method: 'POST',
                       headers: {'Content-Type': 'application/json'},
                       body: JSON.stringify({message: 'Hello from frontend!'})
                   });
                   const data = await response.json();
                   document.getElementById('db-response').innerHTML = '<pre>' + JSON.stringify(data, null, 2) + '</pre>';
               } catch (error) {
                   document.getElementById('db-response').innerHTML = 'Error: ' + error;
               }
           }
       </script>
   </body>
   </html>
   EOF
   
   aws s3 cp index.html s3://my-serverless-webapp-bucket/
   ```

2. **Create Lambda Functions**:
   ```bash
   cat > lambda_function.py << 'EOF'
   import json
   import boto3
   
   dynamodb = boto3.resource('dynamodb')
   table = dynamodb.Table('webapp-data')
   
   def lambda_handler(event, context):
       try:
           if event['httpMethod'] == 'GET':
               if event['path'] == '/hello':
                   return {
                       'statusCode': 200,
                       'headers': {'Access-Control-Allow-Origin': '*'},
                       'body': json.dumps({'message': 'Hello from Lambda!'})
                   }
               elif event['path'] == '/data':
                   response = table.scan()
                   return {
                       'statusCode': 200,
                       'headers': {'Access-Control-Allow-Origin': '*'},
                       'body': json.dumps(response['Items'], default=str)
                   }
           elif event['httpMethod'] == 'POST':
               body = json.loads(event['body'])
               table.put_item(Item={'id': context.aws_request_id, 'message': body.get('message')})
               return {
                   'statusCode': 201,
                   'headers': {'Access-Control-Allow-Origin': '*'},
                   'body': json.dumps({'message': 'Data saved'})
               }
       except Exception as e:
           return {'statusCode': 500, 'body': json.dumps({'error': str(e)})}
   EOF
   
   zip lambda-deployment.zip lambda_function.py
   
   aws lambda create-function \
     --function-name serverless-webapp-api \
     --runtime python3.9 \
     --role arn:aws:iam::account:role/lambda-execution-role \
     --handler lambda_function.lambda_handler \
     --zip-file fileb://lambda-deployment.zip
   ```

3. **Create DynamoDB Table**:
   ```bash
   aws dynamodb create-table \
     --table-name webapp-data \
     --attribute-definitions AttributeName=id,AttributeType=S \
     --key-schema AttributeName=id,KeyType=HASH \
     --billing-mode PAY_PER_REQUEST
   ```

4. **Set Up API Gateway**:
   ```bash
   aws apigateway create-rest-api --name serverless-webapp-api
   API_ID="your-api-id"
   ROOT_ID=$(aws apigateway get-resources --rest-api-id $API_ID --query 'items[0].id' --output text)
   
   aws apigateway create-resource --rest-api-id $API_ID --parent-id $ROOT_ID --path-part hello
   aws apigateway create-resource --rest-api-id $API_ID --parent-id $ROOT_ID --path-part data
   
   aws apigateway create-deployment --rest-api-id $API_ID --stage-name prod
   ```

5. **Verify Serverless Application**:
   ```bash
   curl http://my-serverless-webapp-bucket.s3-website-region.amazonaws.com
   curl https://your-api-id.execute-api.region.amazonaws.com/prod/hello
   curl -X POST https://your-api-id.execute-api.region.amazonaws.com/prod/data -d '{"message":"test"}'
   ```

**Completion Checklist**:
- [ ] S3 bucket created with static website hosting
- [ ] Lambda function deployed
- [ ] DynamoDB table created
- [ ] API Gateway configured
- [ ] Application accessible via S3 URL

**Screenshot Placeholder**:
![Serverless Architecture](screenshots/10-serverless-architecture.png)
*Caption: Serverless web application architecture*

### Practice 3: Microservices with ECS - Complete Implementation
**Objective**: Deploy microservices using Amazon ECS

**Steps**:
1. **Create ECS Cluster**:
   ```bash
   aws ecs create-cluster --cluster-name microservices-cluster
   
   cat > trust-policy.json << 'EOF'
   {
     "Version": "2012-10-17",
     "Statement": [{
       "Effect": "Allow",
       "Principal": {"Service": "ecs-tasks.amazonaws.com"},
       "Action": "sts:AssumeRole"
     }]
   }
   EOF
   
   aws iam create-role --role-name ecsTaskExecutionRole --assume-role-policy-document file://trust-policy.json
   aws iam attach-role-policy --role-name ecsTaskExecutionRole --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
   ```

2. **Create Task Definitions**:
   ```bash
   cat > user-service-task.json << 'EOF'
   {
     "family": "user-service",
     "networkMode": "awsvpc",
     "requiresCompatibilities": ["FARGATE"],
     "cpu": "256",
     "memory": "512",
     "executionRoleArn": "arn:aws:iam::account:role/ecsTaskExecutionRole",
     "containerDefinitions": [{
       "name": "user-service",
       "image": "nginx:latest",
       "portMappings": [{"containerPort": 80}],
       "logConfiguration": {
         "logDriver": "awslogs",
         "options": {
           "awslogs-group": "/ecs/user-service",
           "awslogs-region": "us-east-1",
           "awslogs-stream-prefix": "ecs"
         }
       }
     }]
   }
   EOF
   
   aws logs create-log-group --log-group-name /ecs/user-service
   aws ecs register-task-definition --cli-input-json file://user-service-task.json
   ```

3. **Create ECS Services**:
   ```bash
   aws ecs create-service \
     --cluster microservices-cluster \
     --service-name user-service \
     --task-definition user-service:1 \
     --desired-count 2 \
     --launch-type FARGATE \
     --network-configuration "awsvpcConfiguration={subnets=[subnet-12345678,subnet-87654321],securityGroups=[sg-xxxxxxxxx],assignPublicIp=ENABLED}"
   ```

4. **Verify ECS Deployment**:
   ```bash
   aws ecs describe-clusters --clusters microservices-cluster
   aws ecs describe-services --cluster microservices-cluster --services user-service
   aws ecs list-tasks --cluster microservices-cluster
   ```

**Completion Checklist**:
- [ ] ECS cluster created
- [ ] Task execution role configured
- [ ] Task definition registered
- [ ] ECS service running
- [ ] Tasks healthy and running

**Screenshot Placeholder**:
![Microservices Architecture](screenshots/10-microservices-ecs.png)
*Caption: Microservices architecture using Amazon ECS*

## 🗑️ Cleanup/Destroy Resources

### Cleanup Practice 1: Three-Tier Architecture
```bash
# Delete Auto Scaling Groups
aws autoscaling delete-auto-scaling-group --auto-scaling-group-name webapp-web-asg --force-delete
aws autoscaling delete-auto-scaling-group --auto-scaling-group-name webapp-app-asg --force-delete

# Delete Load Balancers
aws elbv2 delete-load-balancer --load-balancer-arn arn:aws:elasticloadbalancing:region:account:loadbalancer/app/webapp-web-alb/1234567890123456
aws elbv2 delete-load-balancer --load-balancer-arn arn:aws:elasticloadbalancing:region:account:loadbalancer/app/webapp-app-alb/1234567890123456

# Delete Target Groups
aws elbv2 delete-target-group --target-group-arn arn:aws:elasticloadbalancing:region:account:targetgroup/webapp-web-tg/1234567890123456
aws elbv2 delete-target-group --target-group-arn arn:aws:elasticloadbalancing:region:account:targetgroup/webapp-app-tg/1234567890123456

# Delete Launch Templates
aws ec2 delete-launch-template --launch-template-name webapp-app-template

# Delete RDS Instance
aws rds delete-db-instance --db-instance-identifier webapp-db --skip-final-snapshot

# Wait for RDS deletion, then delete DB subnet group
aws rds delete-db-subnet-group --db-subnet-group-name webapp-db-subnet-group

# Delete CloudWatch Alarms
aws cloudwatch delete-alarms --alarm-names webapp-high-cpu
```

### Cleanup Practice 2: Serverless Architecture
```bash
# Delete API Gateway
aws apigateway delete-rest-api --rest-api-id your-api-id

# Delete Lambda Function
aws lambda delete-function --function-name serverless-webapp-api

# Delete DynamoDB Table
aws dynamodb delete-table --table-name webapp-data

# Empty and Delete S3 Bucket
aws s3 rm s3://my-serverless-webapp-bucket --recursive
aws s3 rb s3://my-serverless-webapp-bucket

# Clean up local files
rm -f lambda_function.py lambda-deployment.zip index.html
```

### Cleanup Practice 3: Microservices ECS
```bash
# Delete ECS Service
aws ecs update-service --cluster microservices-cluster --service user-service --desired-count 0
aws ecs delete-service --cluster microservices-cluster --service user-service

# Delete ECS Cluster
aws ecs delete-cluster --cluster microservices-cluster

# Delete Task Definition (deregister)
aws ecs deregister-task-definition --task-definition user-service:1

# Delete Log Group
aws logs delete-log-group --log-group-name /ecs/user-service

# Delete IAM Role
aws iam detach-role-policy --role-name ecsTaskExecutionRole --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
aws iam delete-role --role-name ecsTaskExecutionRole

# Clean up local files
rm -f trust-policy.json user-service-task.json
```