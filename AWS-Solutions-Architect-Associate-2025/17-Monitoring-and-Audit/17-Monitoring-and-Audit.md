# Section 20: AWS Monitoring & Audit

## 📋 Overview
This section covers AWS monitoring, logging, and auditing services including CloudWatch, CloudTrail, and Config for comprehensive infrastructure observability and compliance.

## 📊 Amazon CloudWatch

### What is CloudWatch?
- **Monitoring service**: Collect and track metrics, logs, and events
- **Alarms**: Automated responses to metric thresholds
- **Dashboards**: Visual monitoring interfaces
- **Logs**: Centralized log management
- **Events**: Event-driven automation

### CloudWatch Components
- **Metrics**: Time-series data points
- **Alarms**: Threshold-based notifications
- **Logs Groups**: Organize log streams
- **Dashboards**: Custom monitoring views
- **Insights**: Query and analyze logs

## 🔍 AWS CloudTrail

### What is CloudTrail?
- **API logging**: Record AWS API calls
- **Audit trail**: Track user and resource activity
- **Compliance**: Meet regulatory requirements
- **Security analysis**: Detect unusual activity
- **Multi-region**: Global activity tracking

## ⚙️ AWS Config

### What is Config?
- **Configuration management**: Track resource configurations
- **Compliance monitoring**: Evaluate against rules
- **Change tracking**: Historical configuration data
- **Remediation**: Automated compliance fixes
- **Inventory**: Resource discovery and tracking

## 🛠️ Hands-On Practice

### Practice 1: CloudWatch Metrics and Alarms
**Objective**: Set up comprehensive CloudWatch monitoring with custom metrics and alarms

**Steps**:
1. **Create Custom Metrics**:
   ```bash
   # Create custom metric publisher
   cat > publish_metrics.py << 'EOF'
   import boto3
   import time
   import random
   from datetime import datetime
   
   cloudwatch = boto3.client('cloudwatch')
   
   def publish_custom_metrics():
       """Publish custom application metrics"""
       
       # Simulate application metrics
       metrics_data = [
           {
               'MetricName': 'ActiveUsers',
               'Value': random.randint(100, 1000),
               'Unit': 'Count',
               'Dimensions': [
                   {'Name': 'Environment', 'Value': 'Production'},
                   {'Name': 'Application', 'Value': 'WebApp'}
               ]
           },
           {
               'MetricName': 'ResponseTime',
               'Value': random.uniform(50, 500),
               'Unit': 'Milliseconds',
               'Dimensions': [
                   {'Name': 'Environment', 'Value': 'Production'},
                   {'Name': 'Endpoint', 'Value': '/api/users'}
               ]
           },
           {
               'MetricName': 'ErrorRate',
               'Value': random.uniform(0, 5),
               'Unit': 'Percent',
               'Dimensions': [
                   {'Name': 'Environment', 'Value': 'Production'},
                   {'Name': 'Service', 'Value': 'UserService'}
               ]
           }
       ]
       
       # Publish metrics
       for metric in metrics_data:
           cloudwatch.put_metric_data(
               Namespace='MyApp/Performance',
               MetricData=[{
                   'MetricName': metric['MetricName'],
                   'Value': metric['Value'],
                   'Unit': metric['Unit'],
                   'Dimensions': metric['Dimensions'],
                   'Timestamp': datetime.utcnow()
               }]
           )
           print(f"Published {metric['MetricName']}: {metric['Value']} {metric['Unit']}")
   
   if __name__ == "__main__":
       print("Publishing custom metrics...")
       for i in range(10):
           publish_custom_metrics()
           time.sleep(60)  # Publish every minute
   EOF
   
   # Run metric publisher in background
   python3 publish_metrics.py &
   ```

2. **Create CloudWatch Alarms**:
   ```bash
   # Create high error rate alarm
   aws cloudwatch put-metric-alarm \
     --alarm-name "High-Error-Rate" \
     --alarm-description "Alert when error rate exceeds 3%" \
     --metric-name ErrorRate \
     --namespace MyApp/Performance \
     --statistic Average \
     --period 300 \
     --threshold 3.0 \
     --comparison-operator GreaterThanThreshold \
     --evaluation-periods 2 \
     --alarm-actions arn:aws:sns:us-east-1:ACCOUNT_ID:alerts \
     --dimensions Name=Environment,Value=Production Name=Service,Value=UserService
   
   # Create high response time alarm
   aws cloudwatch put-metric-alarm \
     --alarm-name "High-Response-Time" \
     --alarm-description "Alert when response time exceeds 300ms" \
     --metric-name ResponseTime \
     --namespace MyApp/Performance \
     --statistic Average \
     --period 300 \
     --threshold 300.0 \
     --comparison-operator GreaterThanThreshold \
     --evaluation-periods 3 \
     --alarm-actions arn:aws:sns:us-east-1:ACCOUNT_ID:alerts \
     --dimensions Name=Environment,Value=Production Name=Endpoint,Value=/api/users
   
   # Create composite alarm
   aws cloudwatch put-composite-alarm \
     --alarm-name "Application-Health-Composite" \
     --alarm-description "Overall application health" \
     --alarm-rule "(ALARM('High-Error-Rate') OR ALARM('High-Response-Time'))" \
     --actions-enabled \
     --alarm-actions arn:aws:sns:us-east-1:ACCOUNT_ID:alerts
   ```

3. **Create CloudWatch Dashboard**:
   ```bash
   # Create dashboard configuration
   cat > dashboard.json << 'EOF'
   {
     "widgets": [
       {
         "type": "metric",
         "properties": {
           "metrics": [
             ["MyApp/Performance", "ActiveUsers", "Environment", "Production", "Application", "WebApp"],
             [".", "ResponseTime", "Environment", "Production", "Endpoint", "/api/users"],
             [".", "ErrorRate", "Environment", "Production", "Service", "UserService"]
           ],
           "period": 300,
           "stat": "Average",
           "region": "us-east-1",
           "title": "Application Performance Metrics",
           "yAxis": {
             "left": {
               "min": 0
             }
           }
         }
       },
       {
         "type": "log",
         "properties": {
           "query": "SOURCE '/aws/lambda/my-function'\n| fields @timestamp, @message\n| filter @message like /ERROR/\n| sort @timestamp desc\n| limit 100",
           "region": "us-east-1",
           "title": "Recent Errors",
           "view": "table"
         }
       }
     ]
   }
   EOF
   
   # Create dashboard
   aws cloudwatch put-dashboard \
     --dashboard-name "Application-Monitoring" \
     --dashboard-body file://dashboard.json
   ```

**Screenshot Placeholder**:
![CloudWatch Dashboard](screenshots/20-cloudwatch-dashboard.png)
*Caption: CloudWatch dashboard with custom metrics and alarms*

### Practice 2: CloudWatch Logs Analysis
**Objective**: Set up centralized logging with CloudWatch Logs Insights

**Steps**:
1. **Create Log Groups and Streams**:
   ```bash
   # Create log groups
   aws logs create-log-group --log-group-name /myapp/application
   aws logs create-log-group --log-group-name /myapp/access
   aws logs create-log-group --log-group-name /myapp/error
   
   # Set retention policy
   aws logs put-retention-policy \
     --log-group-name /myapp/application \
     --retention-in-days 30
   
   aws logs put-retention-policy \
     --log-group-name /myapp/access \
     --retention-in-days 7
   
   aws logs put-retention-policy \
     --log-group-name /myapp/error \
     --retention-in-days 90
   ```

2. **Generate Sample Logs**:
   ```bash
   # Create log generator
   cat > generate_logs.py << 'EOF'
   import boto3
   import json
   import time
   import random
   from datetime import datetime
   
   logs_client = boto3.client('logs')
   
   def create_log_stream(log_group, stream_name):
       """Create log stream if it doesn't exist"""
       try:
           logs_client.create_log_stream(
               logGroupName=log_group,
               logStreamName=stream_name
           )
       except logs_client.exceptions.ResourceAlreadyExistsException:
           pass
   
   def send_log_events(log_group, stream_name, events):
       """Send log events to CloudWatch Logs"""
       try:
           response = logs_client.put_log_events(
               logGroupName=log_group,
               logStreamName=stream_name,
               logEvents=events
           )
           return response.get('nextSequenceToken')
       except Exception as e:
           print(f"Error sending logs: {e}")
           return None
   
   def generate_application_logs():
       """Generate application logs"""
       log_levels = ['INFO', 'WARN', 'ERROR', 'DEBUG']
       components = ['UserService', 'OrderService', 'PaymentService', 'NotificationService']
       
       events = []
       for i in range(50):
           level = random.choice(log_levels)
           component = random.choice(components)
           
           if level == 'ERROR':
               message = f"[{level}] {component}: Database connection failed - Connection timeout"
           elif level == 'WARN':
               message = f"[{level}] {component}: High memory usage detected - 85% utilized"
           else:
               message = f"[{level}] {component}: Processing request {random.randint(1000, 9999)}"
           
           events.append({
               'timestamp': int(time.time() * 1000),
               'message': json.dumps({
                   'timestamp': datetime.now().isoformat(),
                   'level': level,
                   'component': component,
                   'message': message,
                   'requestId': f'req-{random.randint(100000, 999999)}',
                   'userId': f'user-{random.randint(1, 1000)}'
               })
           })
           
           time.sleep(0.1)
       
       return events
   
   def generate_access_logs():
       """Generate access logs"""
       methods = ['GET', 'POST', 'PUT', 'DELETE']
       endpoints = ['/api/users', '/api/orders', '/api/products', '/api/payments']
       status_codes = [200, 201, 400, 401, 404, 500]
       
       events = []
       for i in range(100):
           method = random.choice(methods)
           endpoint = random.choice(endpoints)
           status = random.choice(status_codes)
           response_time = random.randint(10, 2000)
           
           events.append({
               'timestamp': int(time.time() * 1000),
               'message': f'{random.randint(1, 255)}.{random.randint(1, 255)}.{random.randint(1, 255)}.{random.randint(1, 255)} - - [{datetime.now().strftime("%d/%b/%Y:%H:%M:%S +0000")}] "{method} {endpoint} HTTP/1.1" {status} {random.randint(100, 5000)} {response_time}ms'
           })
           
           time.sleep(0.05)
       
       return events
   
   if __name__ == "__main__":
       # Create log streams
       create_log_stream('/myapp/application', 'app-server-1')
       create_log_stream('/myapp/access', 'nginx-access')
       create_log_stream('/myapp/error', 'app-errors')
       
       print("Generating application logs...")
       app_events = generate_application_logs()
       send_log_events('/myapp/application', 'app-server-1', app_events)
       
       print("Generating access logs...")
       access_events = generate_access_logs()
       send_log_events('/myapp/access', 'nginx-access', access_events)
       
       print("Log generation completed!")
   EOF
   
   python3 generate_logs.py
   ```

3. **CloudWatch Logs Insights Queries**:
   ```bash
   # Create Logs Insights queries
   cat > logs_insights_queries.py << 'EOF'
   import boto3
   import time
   import json
   
   logs_client = boto3.client('logs')
   
   def run_insights_query(query, log_groups, start_time, end_time):
       """Run CloudWatch Logs Insights query"""
       response = logs_client.start_query(
           logGroupNames=log_groups,
           startTime=start_time,
           endTime=end_time,
           queryString=query
       )
       
       query_id = response['queryId']
       
       # Wait for query to complete
       while True:
           response = logs_client.get_query_results(queryId=query_id)
           if response['status'] == 'Complete':
               return response['results']
           elif response['status'] == 'Failed':
               print(f"Query failed: {response}")
               return None
           time.sleep(1)
   
   def analyze_logs():
       """Run various log analysis queries"""
       end_time = int(time.time())
       start_time = end_time - 3600  # Last hour
       
       queries = [
           {
               'name': 'Error Count by Component',
               'query': '''
                   fields @timestamp, @message
                   | filter @message like /ERROR/
                   | parse @message /\[(?<level>\w+)\]\s+(?<component>\w+):/
                   | stats count() by component
                   | sort count desc
               ''',
               'log_groups': ['/myapp/application']
           },
           {
               'name': 'Top 10 Slowest Requests',
               'query': '''
                   fields @timestamp, @message
                   | parse @message /(?<ip>\d+\.\d+\.\d+\.\d+).*"(?<method>\w+)\s+(?<endpoint>\/\S+).*"\s+(?<status>\d+)\s+\d+\s+(?<response_time>\d+)ms/
                   | filter response_time > 100
                   | sort response_time desc
                   | limit 10
               ''',
               'log_groups': ['/myapp/access']
           },
           {
               'name': 'Request Count by Status Code',
               'query': '''
                   fields @timestamp, @message
                   | parse @message /(?<ip>\d+\.\d+\.\d+\.\d+).*"(?<method>\w+)\s+(?<endpoint>\/\S+).*"\s+(?<status>\d+)/
                   | stats count() by status
                   | sort count desc
               ''',
               'log_groups': ['/myapp/access']
           },
           {
               'name': 'Average Response Time by Endpoint',
               'query': '''
                   fields @timestamp, @message
                   | parse @message /(?<ip>\d+\.\d+\.\d+\.\d+).*"(?<method>\w+)\s+(?<endpoint>\/\S+).*"\s+(?<status>\d+)\s+\d+\s+(?<response_time>\d+)ms/
                   | stats avg(response_time) by endpoint
                   | sort avg desc
               ''',
               'log_groups': ['/myapp/access']
           }
       ]
       
       for query_info in queries:
           print(f"\n=== {query_info['name']} ===")
           results = run_insights_query(
               query_info['query'],
               query_info['log_groups'],
               start_time,
               end_time
           )
           
           if results:
               for result in results[:10]:  # Show top 10 results
                   row = {field['field']: field['value'] for field in result}
                   print(json.dumps(row, indent=2))
           else:
               print("No results found")
   
   if __name__ == "__main__":
       analyze_logs()
   EOF
   
   python3 logs_insights_queries.py
   ```

**Screenshot Placeholder**:
![CloudWatch Logs Insights](screenshots/20-logs-insights.png)
*Caption: CloudWatch Logs Insights queries and analysis*

### Practice 3: AWS CloudTrail Setup
**Objective**: Configure CloudTrail for comprehensive API logging and analysis

**Steps**:
1. **Create CloudTrail**:
   ```bash
   # Create S3 bucket for CloudTrail logs
   aws s3 mb s3://my-cloudtrail-logs-12345
   
   # Create bucket policy for CloudTrail
   cat > cloudtrail-bucket-policy.json << 'EOF'
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Sid": "AWSCloudTrailAclCheck",
         "Effect": "Allow",
         "Principal": {
           "Service": "cloudtrail.amazonaws.com"
         },
         "Action": "s3:GetBucketAcl",
         "Resource": "arn:aws:s3:::my-cloudtrail-logs-12345"
       },
       {
         "Sid": "AWSCloudTrailWrite",
         "Effect": "Allow",
         "Principal": {
           "Service": "cloudtrail.amazonaws.com"
         },
         "Action": "s3:PutObject",
         "Resource": "arn:aws:s3:::my-cloudtrail-logs-12345/*",
         "Condition": {
           "StringEquals": {
             "s3:x-amz-acl": "bucket-owner-full-control"
           }
         }
       }
     ]
   }
   EOF
   
   aws s3api put-bucket-policy \
     --bucket my-cloudtrail-logs-12345 \
     --policy file://cloudtrail-bucket-policy.json
   
   # Create CloudTrail
   aws cloudtrail create-trail \
     --name my-organization-trail \
     --s3-bucket-name my-cloudtrail-logs-12345 \
     --include-global-service-events \
     --is-multi-region-trail \
     --enable-log-file-validation
   
   # Start logging
   aws cloudtrail start-logging --name my-organization-trail
   ```

2. **Create CloudTrail Analysis**:
   ```bash
   # Create CloudTrail log analyzer
   cat > analyze_cloudtrail.py << 'EOF'
   import boto3
   import json
   import gzip
   from datetime import datetime, timedelta
   from collections import defaultdict
   
   s3 = boto3.client('s3')
   cloudtrail = boto3.client('cloudtrail')
   
   def lookup_events(start_time, end_time, attribute_key=None, attribute_value=None):
       """Lookup CloudTrail events"""
       kwargs = {
           'StartTime': start_time,
           'EndTime': end_time,
           'MaxItems': 50
       }
       
       if attribute_key and attribute_value:
           kwargs['LookupAttributes'] = [
               {
                   'AttributeKey': attribute_key,
                   'AttributeValue': attribute_value
               }
           ]
       
       response = cloudtrail.lookup_events(**kwargs)
       return response['Events']
   
   def analyze_user_activity():
       """Analyze user activity from CloudTrail"""
       print("=== User Activity Analysis ===")
       
       end_time = datetime.now()
       start_time = end_time - timedelta(hours=24)
       
       # Get events for specific user
       events = lookup_events(start_time, end_time, 'Username', 'admin')
       
       if events:
           print(f"Found {len(events)} events for user 'admin'")
           
           # Analyze event types
           event_counts = defaultdict(int)
           for event in events:
               event_counts[event['EventName']] += 1
           
           print("\nTop Event Types:")
           for event_name, count in sorted(event_counts.items(), key=lambda x: x[1], reverse=True)[:10]:
               print(f"- {event_name}: {count}")
           
           # Show recent events
           print("\nRecent Events:")
           for event in events[:5]:
               print(f"- {event['EventTime']}: {event['EventName']} from {event.get('SourceIPAddress', 'N/A')}")
       else:
           print("No events found for user 'admin'")
   
   def analyze_failed_logins():
       """Analyze failed login attempts"""
       print("\n=== Failed Login Analysis ===")
       
       end_time = datetime.now()
       start_time = end_time - timedelta(hours=24)
       
       # Look for ConsoleLogin events
       events = lookup_events(start_time, end_time, 'EventName', 'ConsoleLogin')
       
       failed_logins = []
       for event in events:
           cloud_trail_event = json.loads(event['CloudTrailEvent'])
           if cloud_trail_event.get('errorMessage'):
               failed_logins.append({
                   'time': event['EventTime'],
                   'source_ip': cloud_trail_event.get('sourceIPAddress'),
                   'user_name': cloud_trail_event.get('userName'),
                   'error': cloud_trail_event.get('errorMessage')
               })
       
       if failed_logins:
           print(f"Found {len(failed_logins)} failed login attempts")
           for login in failed_logins[:10]:
               print(f"- {login['time']}: {login['user_name']} from {login['source_ip']} - {login['error']}")
       else:
           print("No failed login attempts found")
   
   def analyze_resource_changes():
       """Analyze resource creation/modification events"""
       print("\n=== Resource Changes Analysis ===")
       
       end_time = datetime.now()
       start_time = end_time - timedelta(hours=24)
       
       # Look for resource creation events
       create_events = ['CreateBucket', 'RunInstances', 'CreateDBInstance', 'CreateFunction']
       
       for event_name in create_events:
           events = lookup_events(start_time, end_time, 'EventName', event_name)
           if events:
               print(f"\n{event_name} Events ({len(events)}):")
               for event in events[:5]:
                   cloud_trail_event = json.loads(event['CloudTrailEvent'])
                   user = cloud_trail_event.get('userName', 'Unknown')
                   source_ip = cloud_trail_event.get('sourceIPAddress', 'Unknown')
                   print(f"- {event['EventTime']}: {user} from {source_ip}")
   
   def generate_security_report():
       """Generate security analysis report"""
       print("\n=== Security Analysis Report ===")
       
       end_time = datetime.now()
       start_time = end_time - timedelta(hours=24)
       
       # Check for suspicious activities
       suspicious_events = [
           'DeleteTrail',
           'StopLogging',
           'PutBucketPolicy',
           'CreateUser',
           'AttachUserPolicy',
           'CreateRole'
       ]
       
       total_suspicious = 0
       for event_name in suspicious_events:
           events = lookup_events(start_time, end_time, 'EventName', event_name)
           if events:
               total_suspicious += len(events)
               print(f"- {event_name}: {len(events)} events")
       
       if total_suspicious == 0:
           print("No suspicious activities detected")
       else:
           print(f"\nTotal suspicious events: {total_suspicious}")
   
   if __name__ == "__main__":
       analyze_user_activity()
       analyze_failed_logins()
       analyze_resource_changes()
       generate_security_report()
   EOF
   
   python3 analyze_cloudtrail.py
   ```

**Screenshot Placeholder**:
![CloudTrail Analysis](screenshots/20-cloudtrail-analysis.png)
*Caption: CloudTrail event analysis and security monitoring*

### Practice 4: AWS Config Rules and Compliance
**Objective**: Set up AWS Config for resource compliance monitoring

**Steps**:
1. **Set Up AWS Config**:
   ```bash
   # Create S3 bucket for Config
   aws s3 mb s3://my-aws-config-12345
   
   # Create Config service role
   cat > config-role.json << 'EOF'
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Principal": {
           "Service": "config.amazonaws.com"
         },
         "Action": "sts:AssumeRole"
       }
     ]
   }
   EOF
   
   aws iam create-role \
     --role-name ConfigServiceRole \
     --assume-role-policy-document file://config-role.json
   
   aws iam attach-role-policy \
     --role-name ConfigServiceRole \
     --policy-arn arn:aws:iam::aws:policy/service-role/ConfigRole
   
   # Create delivery channel
   aws configservice put-delivery-channel \
     --delivery-channel name=default,s3BucketName=my-aws-config-12345
   
   # Create configuration recorder
   aws configservice put-configuration-recorder \
     --configuration-recorder name=default,roleARN=arn:aws:iam::ACCOUNT_ID:role/ConfigServiceRole,recordingGroup='{
       "allSupported": true,
       "includeGlobalResourceTypes": true,
       "resourceTypes": []
     }'
   
   # Start configuration recorder
   aws configservice start-configuration-recorder \
     --configuration-recorder-name default
   ```

2. **Create Config Rules**:
   ```bash
   # Create compliance rules
   
   # Rule 1: S3 bucket public access prohibited
   aws configservice put-config-rule \
     --config-rule '{
       "ConfigRuleName": "s3-bucket-public-access-prohibited",
       "Source": {
         "Owner": "AWS",
         "SourceIdentifier": "S3_BUCKET_PUBLIC_ACCESS_PROHIBITED"
       }
     }'
   
   # Rule 2: EC2 instances should not have public IP
   aws configservice put-config-rule \
     --config-rule '{
       "ConfigRuleName": "ec2-instance-no-public-ip",
       "Source": {
         "Owner": "AWS",
         "SourceIdentifier": "EC2_INSTANCE_NO_PUBLIC_IP"
       }
     }'
   
   # Rule 3: RDS instances should be encrypted
   aws configservice put-config-rule \
     --config-rule '{
       "ConfigRuleName": "rds-storage-encrypted",
       "Source": {
         "Owner": "AWS",
         "SourceIdentifier": "RDS_STORAGE_ENCRYPTED"
       }
     }'
   
   # Rule 4: Security groups should not allow unrestricted access
   aws configservice put-config-rule \
     --config-rule '{
       "ConfigRuleName": "ec2-security-group-attached-to-eni",
       "Source": {
         "Owner": "AWS",
         "SourceIdentifier": "EC2_SECURITY_GROUP_ATTACHED_TO_ENI"
       }
     }'
   ```

3. **Config Compliance Analysis**:
   ```bash
   # Create Config compliance analyzer
   cat > config_compliance.py << 'EOF'
   import boto3
   import json
   from datetime import datetime
   
   config_client = boto3.client('config')
   
   def get_compliance_summary():
       """Get overall compliance summary"""
       print("=== Compliance Summary ===")
       
       response = config_client.get_compliance_summary_by_config_rule()
       summary = response['ComplianceSummary']
       
       print(f"Compliant Rules: {summary.get('CompliantResourceCount', {}).get('CappedCount', 0)}")
       print(f"Non-Compliant Rules: {summary.get('NonCompliantResourceCount', {}).get('CappedCount', 0)}")
       print(f"Insufficient Data: {summary.get('ComplianceByConfigRule', {}).get('InsufficientDataCount', 0)}")
   
   def get_config_rules_compliance():
       """Get compliance status for all Config rules"""
       print("\n=== Config Rules Compliance ===")
       
       response = config_client.describe_compliance_by_config_rule()
       
       for rule_compliance in response['ComplianceByConfigRules']:
           rule_name = rule_compliance['ConfigRuleName']
           compliance = rule_compliance['Compliance']
           
           print(f"\nRule: {rule_name}")
           print(f"Status: {compliance['ComplianceType']}")
           
           if compliance['ComplianceType'] == 'NON_COMPLIANT':
               # Get non-compliant resources
               resources_response = config_client.get_compliance_details_by_config_rule(
                   ConfigRuleName=rule_name,
                   ComplianceTypes=['NON_COMPLIANT']
               )
               
               if resources_response['EvaluationResults']:
                   print("Non-compliant resources:")
                   for result in resources_response['EvaluationResults'][:5]:
                       resource_id = result['EvaluationResultIdentifier']['EvaluationResultQualifier']['ResourceId']
                       resource_type = result['EvaluationResultIdentifier']['EvaluationResultQualifier']['ResourceType']
                       print(f"  - {resource_type}: {resource_id}")
   
   def get_resource_compliance():
       """Get compliance status by resource type"""
       print("\n=== Resource Type Compliance ===")
       
       response = config_client.describe_compliance_by_resource()
       
       resource_compliance = {}
       for compliance in response['ComplianceByResources']:
           resource_type = compliance['ResourceType']
           compliance_type = compliance['Compliance']['ComplianceType']
           
           if resource_type not in resource_compliance:
               resource_compliance[resource_type] = {'COMPLIANT': 0, 'NON_COMPLIANT': 0, 'NOT_APPLICABLE': 0}
           
           resource_compliance[resource_type][compliance_type] += 1
       
       for resource_type, counts in resource_compliance.items():
           total = sum(counts.values())
           compliant_pct = (counts['COMPLIANT'] / total) * 100 if total > 0 else 0
           
           print(f"\n{resource_type}:")
           print(f"  Total: {total}")
           print(f"  Compliant: {counts['COMPLIANT']} ({compliant_pct:.1f}%)")
           print(f"  Non-Compliant: {counts['NON_COMPLIANT']}")
   
   def get_configuration_history(resource_type, resource_id):
       """Get configuration history for a resource"""
       print(f"\n=== Configuration History for {resource_type}: {resource_id} ===")
       
       try:
           response = config_client.get_resource_config_history(
               resourceType=resource_type,
               resourceId=resource_id,
               limit=5
           )
           
           for config_item in response['configurationItems']:
               print(f"\nConfiguration Date: {config_item['configurationItemCaptureTime']}")
               print(f"Status: {config_item['configurationItemStatus']}")
               print(f"Resource Name: {config_item.get('resourceName', 'N/A')}")
               
               if config_item.get('tags'):
                   print("Tags:")
                   for tag_key, tag_value in config_item['tags'].items():
                       print(f"  {tag_key}: {tag_value}")
                       
       except Exception as e:
           print(f"Error getting configuration history: {e}")
   
   def generate_compliance_report():
       """Generate comprehensive compliance report"""
       print("\n=== Compliance Report ===")
       print(f"Generated: {datetime.now().isoformat()}")
       
       # Get all rules and their compliance
       rules_response = config_client.describe_config_rules()
       total_rules = len(rules_response['ConfigRules'])
       
       compliance_response = config_client.describe_compliance_by_config_rule()
       compliant_rules = sum(1 for rule in compliance_response['ComplianceByConfigRules'] 
                           if rule['Compliance']['ComplianceType'] == 'COMPLIANT')
       
       compliance_percentage = (compliant_rules / total_rules) * 100 if total_rules > 0 else 0
       
       print(f"\nOverall Compliance: {compliance_percentage:.1f}%")
       print(f"Total Rules: {total_rules}")
       print(f"Compliant Rules: {compliant_rules}")
       print(f"Non-Compliant Rules: {total_rules - compliant_rules}")
       
       # Recommendations
       print("\nRecommendations:")
       if compliance_percentage < 80:
           print("- Review and remediate non-compliant resources")
           print("- Consider implementing automated remediation")
           print("- Review security group configurations")
           print("- Ensure encryption is enabled for sensitive resources")
       else:
           print("- Maintain current compliance levels")
           print("- Continue monitoring for configuration drift")
   
   if __name__ == "__main__":
       get_compliance_summary()
       get_config_rules_compliance()
       get_resource_compliance()
       generate_compliance_report()
   EOF
   
   python3 config_compliance.py
   ```

**Screenshot Placeholder**:
![AWS Config Compliance](screenshots/20-config-compliance.png)
*Caption: AWS Config rules and compliance monitoring dashboard*

## ✅ Section Completion Checklist

- [ ] Set up CloudWatch custom metrics and alarms
- [ ] Created comprehensive monitoring dashboards
- [ ] Configured CloudWatch Logs with retention policies
- [ ] Implemented Logs Insights for log analysis
- [ ] Set up CloudTrail for API logging
- [ ] Analyzed CloudTrail events for security insights
- [ ] Configured AWS Config for resource compliance
- [ ] Created Config rules for security compliance
- [ ] Generated compliance reports and remediation plans
- [ ] Integrated monitoring with notification systems

## 🎯 Key Takeaways

- **CloudWatch**: Comprehensive monitoring for metrics, logs, and alarms
- **CloudTrail**: Essential for audit trails and security analysis
- **Config**: Continuous compliance monitoring and configuration management
- **Integration**: Combine all three services for complete observability
- **Automation**: Use alarms and rules for automated responses
- **Retention**: Set appropriate log retention policies for cost optimization
- **Security**: Monitor for suspicious activities and compliance violations
- **Dashboards**: Create visual representations for stakeholder reporting

## 📚 Additional Resources

- [Amazon CloudWatch User Guide](https://docs.aws.amazon.com/cloudwatch/)
- [AWS CloudTrail User Guide](https://docs.aws.amazon.com/cloudtrail/)
- [AWS Config Developer Guide](https://docs.aws.amazon.com/config/)
- [AWS Monitoring and Observability](https://aws.amazon.com/products/management-and-governance/use-cases/monitoring-and-observability/)
- [AWS Well-Architected Operational Excellence](https://docs.aws.amazon.com/wellarchitected/latest/operational-excellence-pillar/)