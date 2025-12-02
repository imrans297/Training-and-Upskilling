# 15. Monitoring, Auditing and Performance

## Lab 1: CloudWatch Metrics and Alarms

### Create Custom Metrics
```bash
# Put custom metric data
aws cloudwatch put-metric-data \
  --namespace "CloudOps/Application" \
  --metric-data MetricName=CustomMetric,Value=100,Unit=Count,Timestamp=$(date -u +%Y-%m-%dT%H:%M:%S)

# Put metric with dimensions
aws cloudwatch put-metric-data \
  --namespace "CloudOps/WebServer" \
  --metric-data '[
    {
      "MetricName": "PageViews",
      "Value": 150,
      "Unit": "Count",
      "Dimensions": [
        {
          "Name": "InstanceId",
          "Value": "i-xxxxxxxxx"
        }
      ]
    }
  ]'
```

### Create CloudWatch Alarms
```bash
# Create CPU alarm
aws cloudwatch put-metric-alarm \
  --alarm-name "High-CPU-Usage" \
  --alarm-description "Alarm when CPU exceeds 80%" \
  --metric-name CPUUtilization \
  --namespace AWS/EC2 \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=InstanceId,Value=i-xxxxxxxxx \
  --evaluation-periods 2 \
  --alarm-actions arn:aws:sns:us-east-1:123456789012:cloudops-alerts

# Create composite alarm
aws cloudwatch put-composite-alarm \
  --alarm-name "System-Health-Alarm" \
  --alarm-description "Composite alarm for system health" \
  --alarm-rule "(ALARM('High-CPU-Usage') OR ALARM('High-Memory-Usage'))" \
  --actions-enabled \
  --alarm-actions arn:aws:sns:us-east-1:123456789012:cloudops-alerts
```

## Terraform CloudWatch Configuration

```hcl
# cloudwatch.tf
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "High-CPU-Usage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  
  dimensions = {
    InstanceId = aws_instance.cloudops_instance.id
  }
  
  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_log_group" "cloudops_logs" {
  name              = "/cloudops/application"
  retention_in_days = 14
  
  tags = {
    Environment = "Production"
  }
}

resource "aws_sns_topic" "alerts" {
  name = "cloudops-alerts"
}

resource "aws_sns_topic_subscription" "email_alerts" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "admin@example.com"
}
```

## Lab 2: CloudWatch Logs

### Configure Log Groups and Streams
```bash
# Create log group
aws logs create-log-group \
  --log-group-name /cloudops/application \
  --retention-in-days 14

# Create log stream
aws logs create-log-stream \
  --log-group-name /cloudops/application \
  --log-stream-name application-$(date +%Y%m%d)

# Put log events
aws logs put-log-events \
  --log-group-name /cloudops/application \
  --log-stream-name application-$(date +%Y%m%d) \
  --log-events timestamp=$(date +%s000),message="Application started successfully"
```

### CloudWatch Logs Insights Queries
```bash
# Query logs
aws logs start-query \
  --log-group-name /cloudops/application \
  --start-time $(date -d '1 hour ago' +%s) \
  --end-time $(date +%s) \
  --query-string 'fields @timestamp, @message | filter @message like /ERROR/ | sort @timestamp desc | limit 20'

# Get query results
aws logs get-query-results --query-id query-id-here
```

### Terraform Log Configuration
```hcl
# logs.tf
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/cloudops/application"
  retention_in_days = 14
  
  tags = {
    Application = "CloudOps"
  }
}

resource "aws_cloudwatch_log_metric_filter" "error_count" {
  name           = "ErrorCount"
  log_group_name = aws_cloudwatch_log_group.app_logs.name
  pattern        = "ERROR"
  
  metric_transformation {
    name      = "ErrorCount"
    namespace = "CloudOps/Application"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "error_alarm" {
  alarm_name          = "High-Error-Rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ErrorCount"
  namespace           = "CloudOps/Application"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "High error rate detected"
  
  alarm_actions = [aws_sns_topic.alerts.arn]
}
```

## Lab 3: CloudTrail Auditing

### Enable CloudTrail
```bash
# Create S3 bucket for CloudTrail
aws s3 mb s3://cloudops-cloudtrail-logs-$(date +%s)

# Create CloudTrail
aws cloudtrail create-trail \
  --name cloudops-trail \
  --s3-bucket-name cloudops-cloudtrail-logs-$(date +%s) \
  --include-global-service-events \
  --is-multi-region-trail \
  --enable-log-file-validation

# Start logging
aws cloudtrail start-logging --name cloudops-trail

# Create event data store
aws cloudtrail create-event-data-store \
  --name cloudops-event-store \
  --multi-region-enabled \
  --organization-enabled
```

### CloudTrail Log Analysis
```bash
# Lookup events
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=RunInstances \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z

# Query event data store
aws cloudtrail start-query \
  --query-statement "SELECT eventTime, eventName, userIdentity.type, sourceIPAddress FROM cloudops-event-store WHERE eventTime > '2024-01-01 00:00:00' AND eventName = 'RunInstances'"
```

### Terraform CloudTrail Configuration
```hcl
# cloudtrail.tf
resource "aws_s3_bucket" "cloudtrail_bucket" {
  bucket        = "cloudops-cloudtrail-${random_string.bucket_suffix.result}"
  force_destroy = true
}

resource "aws_s3_bucket_policy" "cloudtrail_bucket_policy" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail_bucket.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

resource "aws_cloudtrail" "cloudops_trail" {
  name           = "cloudops-trail"
  s3_bucket_name = aws_s3_bucket.cloudtrail_bucket.bucket
  
  include_global_service_events = true
  is_multi_region_trail        = true
  enable_log_file_validation   = true
  
  event_selector {
    read_write_type                 = "All"
    include_management_events       = true
    
    data_resource {
      type   = "AWS::S3::Object"
      values = ["${aws_s3_bucket.cloudtrail_bucket.arn}/*"]
    }
  }
  
  tags = {
    Name = "CloudOps Trail"
  }
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}
```

## Lab 4: AWS Config

### Enable AWS Config
```bash
# Create configuration recorder
aws configservice put-configuration-recorder \
  --configuration-recorder name=cloudops-recorder,roleARN=arn:aws:iam::123456789012:role/config-role \
  --recording-group allSupported=true,includeGlobalResourceTypes=true

# Create delivery channel
aws configservice put-delivery-channel \
  --delivery-channel name=cloudops-delivery-channel,s3BucketName=cloudops-config-bucket

# Start configuration recorder
aws configservice start-configuration-recorder \
  --configuration-recorder-name cloudops-recorder
```

### Config Rules
```bash
# Create Config rule
aws configservice put-config-rule \
  --config-rule '{
    "ConfigRuleName": "required-tags",
    "Source": {
      "Owner": "AWS",
      "SourceIdentifier": "REQUIRED_TAGS"
    },
    "InputParameters": "{\"tag1Key\":\"Environment\",\"tag1Value\":\"Production,Development,Staging\"}"
  }'

# Get compliance details
aws configservice get-compliance-details-by-config-rule \
  --config-rule-name required-tags
```

### Terraform Config Configuration
```hcl
# config.tf
resource "aws_config_configuration_recorder" "cloudops_recorder" {
  name     = "cloudops-recorder"
  role_arn = aws_iam_role.config_role.arn
  
  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "cloudops_delivery_channel" {
  name           = "cloudops-delivery-channel"
  s3_bucket_name = aws_s3_bucket.config_bucket.bucket
}

resource "aws_config_config_rule" "required_tags" {
  name = "required-tags"
  
  source {
    owner             = "AWS"
    source_identifier = "REQUIRED_TAGS"
  }
  
  input_parameters = jsonencode({
    tag1Key   = "Environment"
    tag1Value = "Production,Development,Staging"
  })
  
  depends_on = [aws_config_configuration_recorder.cloudops_recorder]
}
```

## Lab 5: Performance Monitoring

### CloudWatch Dashboard
```bash
# Create dashboard
aws cloudwatch put-dashboard \
  --dashboard-name "CloudOps-Dashboard" \
  --dashboard-body '{
    "widgets": [
      {
        "type": "metric",
        "properties": {
          "metrics": [
            ["AWS/EC2", "CPUUtilization", "InstanceId", "i-xxxxxxxxx"],
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", "app/cloudops-alb/1234567890123456"]
          ],
          "period": 300,
          "stat": "Average",
          "region": "us-east-1",
          "title": "EC2 and ALB Metrics"
        }
      }
    ]
  }'
```

### Terraform Dashboard
```hcl
# dashboard.tf
resource "aws_cloudwatch_dashboard" "cloudops_dashboard" {
  dashboard_name = "CloudOps-Dashboard"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.cloudops_instance.id],
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.cloudops_alb.arn_suffix]
          ]
          period = 300
          stat   = "Average"
          region = "us-east-1"
          title  = "System Performance"
        }
      }
    ]
  })
}
```

## Lab 6: X-Ray Tracing

### Enable X-Ray
```bash
# Create X-Ray service map
aws xray get-service-graph \
  --start-time $(date -d '1 hour ago' +%s) \
  --end-time $(date +%s)

# Get trace summaries
aws xray get-trace-summaries \
  --time-range-type TimeRangeByStartTime \
  --start-time $(date -d '1 hour ago' +%s) \
  --end-time $(date +%s)
```

### Terraform X-Ray Configuration
```hcl
# xray.tf
resource "aws_xray_sampling_rule" "cloudops_sampling" {
  rule_name      = "CloudOpsSampling"
  priority       = 9000
  version        = 1
  reservoir_size = 1
  fixed_rate     = 0.1
  url_path       = "*"
  host           = "*"
  http_method    = "*"
  service_type   = "*"
  service_name   = "*"
  resource_arn   = "*"
}
```

## Best Practices

1. **Set up comprehensive monitoring** for all critical resources
2. **Use CloudWatch Logs** for centralized logging
3. **Enable CloudTrail** for audit trails
4. **Create meaningful alarms** with appropriate thresholds
5. **Use dashboards** for visualization
6. **Implement automated responses** to alerts
7. **Regular review** of monitoring data

## Troubleshooting Commands

```bash
# Check CloudWatch agent status
sudo systemctl status amazon-cloudwatch-agent

# View CloudWatch agent logs
sudo tail -f /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log

# Test metric filters
aws logs filter-log-events \
  --log-group-name /cloudops/application \
  --filter-pattern "ERROR"
```

## Cleanup

```bash
# Delete alarms
aws cloudwatch delete-alarms --alarm-names "High-CPU-Usage"

# Delete log groups
aws logs delete-log-group --log-group-name /cloudops/application

# Delete CloudTrail
aws cloudtrail delete-trail --name cloudops-trail
```