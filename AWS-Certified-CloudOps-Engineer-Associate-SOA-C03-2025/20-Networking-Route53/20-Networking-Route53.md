# 20. Networking - Route 53

## Lab 1: DNS Basics and Hosted Zones

### Create Hosted Zone
```bash
# Create public hosted zone
aws route53 create-hosted-zone \
  --name cloudops.example.com \
  --caller-reference "cloudops-zone-$(date +%s)" \
  --hosted-zone-config Comment="CloudOps domain zone"

# Create private hosted zone
aws route53 create-hosted-zone \
  --name internal.cloudops.com \
  --caller-reference "internal-zone-$(date +%s)" \
  --vpc VPCRegion=us-east-1,VPCId=vpc-xxxxxxxxx \
  --hosted-zone-config Comment="Internal CloudOps zone",PrivateZone=true

# List hosted zones
aws route53 list-hosted-zones

# Get hosted zone details
aws route53 get-hosted-zone \
  --id Z123456789ABCDEFGHIJ
```

### Basic DNS Records
```bash
# Create A record
aws route53 change-resource-record-sets \
  --hosted-zone-id Z123456789ABCDEFGHIJ \
  --change-batch '{
    "Changes": [{
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "www.cloudops.example.com",
        "Type": "A",
        "TTL": 300,
        "ResourceRecords": [{"Value": "192.0.2.1"}]
      }
    }]
  }'

# Create CNAME record
aws route53 change-resource-record-sets \
  --hosted-zone-id Z123456789ABCDEFGHIJ \
  --change-batch '{
    "Changes": [{
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "blog.cloudops.example.com",
        "Type": "CNAME",
        "TTL": 300,
        "ResourceRecords": [{"Value": "www.cloudops.example.com"}]
      }
    }]
  }'

# Create MX record
aws route53 change-resource-record-sets \
  --hosted-zone-id Z123456789ABCDEFGHIJ \
  --change-batch '{
    "Changes": [{
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "cloudops.example.com",
        "Type": "MX",
        "TTL": 300,
        "ResourceRecords": [
          {"Value": "10 mail.cloudops.example.com"},
          {"Value": "20 mail2.cloudops.example.com"}
        ]
      }
    }]
  }'
```

## Terraform Route 53 Configuration

```hcl
# route53.tf
resource "aws_route53_zone" "main" {
  name = "cloudops.example.com"
  
  tags = {
    Name = "CloudOps Main Zone"
  }
}

resource "aws_route53_zone" "private" {
  name = "internal.cloudops.com"
  
  vpc {
    vpc_id = aws_vpc.main.id
  }
  
  tags = {
    Name = "CloudOps Private Zone"
  }
}

# A record
resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.cloudops.example.com"
  type    = "A"
  ttl     = 300
  records = ["192.0.2.1"]
}

# CNAME record
resource "aws_route53_record" "blog" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "blog.cloudops.example.com"
  type    = "CNAME"
  ttl     = 300
  records = ["www.cloudops.example.com"]
}

# Alias record for ALB
resource "aws_route53_record" "app" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "app.cloudops.example.com"
  type    = "A"
  
  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

# MX record
resource "aws_route53_record" "mx" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "cloudops.example.com"
  type    = "MX"
  ttl     = 300
  records = [
    "10 mail.cloudops.example.com",
    "20 mail2.cloudops.example.com"
  ]
}
```

## Lab 2: Health Checks and Monitoring

### Create Health Checks
```bash
# HTTP health check
aws route53 create-health-check \
  --caller-reference "http-health-check-$(date +%s)" \
  --health-check-config '{
    "Type": "HTTP",
    "ResourcePath": "/health",
    "FullyQualifiedDomainName": "app.cloudops.example.com",
    "Port": 80,
    "RequestInterval": 30,
    "FailureThreshold": 3,
    "MeasureLatency": true,
    "EnableSNI": false
  }'

# HTTPS health check with SNI
aws route53 create-health-check \
  --caller-reference "https-health-check-$(date +%s)" \
  --health-check-config '{
    "Type": "HTTPS",
    "ResourcePath": "/api/health",
    "FullyQualifiedDomainName": "api.cloudops.example.com",
    "Port": 443,
    "RequestInterval": 30,
    "FailureThreshold": 3,
    "EnableSNI": true
  }'

# Calculated health check
aws route53 create-health-check \
  --caller-reference "calculated-health-check-$(date +%s)" \
  --health-check-config '{
    "Type": "CALCULATED",
    "ChildHealthChecks": ["health-check-id-1", "health-check-id-2"],
    "ChildHealthCheckCount": 1,
    "Inverted": false
  }'

# CloudWatch alarm health check
aws route53 create-health-check \
  --caller-reference "cloudwatch-health-check-$(date +%s)" \
  --health-check-config '{
    "Type": "CLOUDWATCH_METRIC",
    "AlarmRegion": "us-east-1",
    "AlarmName": "TargetResponseTime",
    "InsufficientDataHealthStatus": "Failure"
  }'
```

### Health Check Notifications
```bash
# Create SNS topic for health check notifications
aws sns create-topic --name route53-health-alerts

# Subscribe to topic
aws sns subscribe \
  --topic-arn arn:aws:sns:us-east-1:123456789012:route53-health-alerts \
  --protocol email \
  --notification-endpoint admin@cloudops.example.com

# Tag health check for notifications
aws route53 change-tags-for-resource \
  --resource-type healthcheck \
  --resource-id health-check-id \
  --add-tags Key=Name,Value="App Health Check" Key=Environment,Value=Production
```

### Terraform Health Checks
```hcl
# health-checks.tf
resource "aws_route53_health_check" "app_health" {
  fqdn                            = "app.cloudops.example.com"
  port                            = 80
  type                            = "HTTP"
  resource_path                   = "/health"
  failure_threshold               = "3"
  request_interval                = "30"
  measure_latency                 = true
  
  tags = {
    Name = "App Health Check"
  }
}

resource "aws_route53_health_check" "api_health" {
  fqdn                            = "api.cloudops.example.com"
  port                            = 443
  type                            = "HTTPS"
  resource_path                   = "/api/health"
  failure_threshold               = "3"
  request_interval                = "30"
  enable_sni                      = true
  
  tags = {
    Name = "API Health Check"
  }
}

resource "aws_route53_health_check" "calculated_health" {
  type                            = "CALCULATED"
  child_health_checks             = [
    aws_route53_health_check.app_health.id,
    aws_route53_health_check.api_health.id
  ]
  child_health_threshold          = 1
  
  tags = {
    Name = "Overall System Health"
  }
}

resource "aws_cloudwatch_metric_alarm" "health_check_failed" {
  alarm_name          = "Route53-Health-Check-Failed"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = "60"
  statistic           = "Minimum"
  threshold           = "1"
  alarm_description   = "Health check failed"
  
  dimensions = {
    HealthCheckId = aws_route53_health_check.app_health.id
  }
  
  alarm_actions = [aws_sns_topic.health_alerts.arn]
}
```

## Lab 3: Routing Policies

### Weighted Routing
```bash
# Create weighted records
aws route53 change-resource-record-sets \
  --hosted-zone-id Z123456789ABCDEFGHIJ \
  --change-batch '{
    "Changes": [
      {
        "Action": "CREATE",
        "ResourceRecordSet": {
          "Name": "app.cloudops.example.com",
          "Type": "A",
          "SetIdentifier": "Primary-80",
          "Weight": 80,
          "TTL": 60,
          "ResourceRecords": [{"Value": "192.0.2.1"}]
        }
      },
      {
        "Action": "CREATE",
        "ResourceRecordSet": {
          "Name": "app.cloudops.example.com",
          "Type": "A",
          "SetIdentifier": "Secondary-20",
          "Weight": 20,
          "TTL": 60,
          "ResourceRecords": [{"Value": "192.0.2.2"}]
        }
      }
    ]
  }'
```

### Latency-based Routing
```bash
# Create latency-based records
aws route53 change-resource-record-sets \
  --hosted-zone-id Z123456789ABCDEFGHIJ \
  --change-batch '{
    "Changes": [
      {
        "Action": "CREATE",
        "ResourceRecordSet": {
          "Name": "app.cloudops.example.com",
          "Type": "A",
          "SetIdentifier": "US-East",
          "Region": "us-east-1",
          "TTL": 60,
          "ResourceRecords": [{"Value": "192.0.2.1"}],
          "HealthCheckId": "health-check-id-1"
        }
      },
      {
        "Action": "CREATE",
        "ResourceRecordSet": {
          "Name": "app.cloudops.example.com",
          "Type": "A",
          "SetIdentifier": "EU-West",
          "Region": "eu-west-1",
          "TTL": 60,
          "ResourceRecords": [{"Value": "192.0.2.2"}],
          "HealthCheckId": "health-check-id-2"
        }
      }
    ]
  }'
```

### Failover Routing
```bash
# Create failover records
aws route53 change-resource-record-sets \
  --hosted-zone-id Z123456789ABCDEFGHIJ \
  --change-batch '{
    "Changes": [
      {
        "Action": "CREATE",
        "ResourceRecordSet": {
          "Name": "app.cloudops.example.com",
          "Type": "A",
          "SetIdentifier": "Primary",
          "Failover": "PRIMARY",
          "TTL": 60,
          "ResourceRecords": [{"Value": "192.0.2.1"}],
          "HealthCheckId": "health-check-id-1"
        }
      },
      {
        "Action": "CREATE",
        "ResourceRecordSet": {
          "Name": "app.cloudops.example.com",
          "Type": "A",
          "SetIdentifier": "Secondary",
          "Failover": "SECONDARY",
          "TTL": 60,
          "ResourceRecords": [{"Value": "192.0.2.2"}]
        }
      }
    ]
  }'
```

### Terraform Routing Policies
```hcl
# routing-policies.tf

# Weighted routing
resource "aws_route53_record" "weighted_primary" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "app.cloudops.example.com"
  type    = "A"
  ttl     = 60
  
  set_identifier = "Primary-80"
  weighted_routing_policy {
    weight = 80
  }
  
  records = [aws_eip.primary.public_ip]
}

resource "aws_route53_record" "weighted_secondary" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "app.cloudops.example.com"
  type    = "A"
  ttl     = 60
  
  set_identifier = "Secondary-20"
  weighted_routing_policy {
    weight = 20
  }
  
  records = [aws_eip.secondary.public_ip]
}

# Latency-based routing
resource "aws_route53_record" "latency_us_east" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "api.cloudops.example.com"
  type    = "A"
  ttl     = 60
  
  set_identifier = "US-East"
  latency_routing_policy {
    region = "us-east-1"
  }
  
  health_check_id = aws_route53_health_check.us_east_health.id
  records         = [aws_eip.us_east.public_ip]
}

resource "aws_route53_record" "latency_eu_west" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "api.cloudops.example.com"
  type    = "A"
  ttl     = 60
  
  set_identifier = "EU-West"
  latency_routing_policy {
    region = "eu-west-1"
  }
  
  health_check_id = aws_route53_health_check.eu_west_health.id
  records         = [aws_eip.eu_west.public_ip]
}

# Failover routing
resource "aws_route53_record" "failover_primary" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "db.cloudops.example.com"
  type    = "A"
  ttl     = 60
  
  set_identifier = "Primary"
  failover_routing_policy {
    type = "PRIMARY"
  }
  
  health_check_id = aws_route53_health_check.primary_db.id
  records         = [aws_eip.primary_db.public_ip]
}

resource "aws_route53_record" "failover_secondary" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "db.cloudops.example.com"
  type    = "A"
  ttl     = 60
  
  set_identifier = "Secondary"
  failover_routing_policy {
    type = "SECONDARY"
  }
  
  records = [aws_eip.secondary_db.public_ip]
}

# Geolocation routing
resource "aws_route53_record" "geo_us" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "content.cloudops.example.com"
  type    = "A"
  ttl     = 60
  
  set_identifier = "US-Content"
  geolocation_routing_policy {
    country = "US"
  }
  
  records = [aws_eip.us_content.public_ip]
}

resource "aws_route53_record" "geo_eu" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "content.cloudops.example.com"
  type    = "A"
  ttl     = 60
  
  set_identifier = "EU-Content"
  geolocation_routing_policy {
    continent = "EU"
  }
  
  records = [aws_eip.eu_content.public_ip]
}
```

## Lab 4: Private DNS and Resolver

### Route 53 Resolver
```bash
# Create resolver endpoint
aws route53resolver create-resolver-endpoint \
  --creator-request-id "resolver-endpoint-$(date +%s)" \
  --security-group-ids sg-xxxxxxxxx \
  --direction INBOUND \
  --ip-addresses SubnetId=subnet-xxxxxxxxx,Ip=10.0.1.100 SubnetId=subnet-yyyyyyyyy,Ip=10.0.2.100

# Create resolver rule
aws route53resolver create-resolver-rule \
  --creator-request-id "resolver-rule-$(date +%s)" \
  --domain-name onprem.example.com \
  --rule-type FORWARD \
  --resolver-endpoint-id rslvr-in-xxxxxxxxx \
  --target-ips Ip=192.168.1.10,Port=53 Ip=192.168.1.11,Port=53

# Associate rule with VPC
aws route53resolver associate-resolver-rule \
  --resolver-rule-id rslvr-rr-xxxxxxxxx \
  --vpc-id vpc-xxxxxxxxx
```

### Terraform Resolver Configuration
```hcl
# resolver.tf
resource "aws_route53_resolver_endpoint" "inbound" {
  name      = "cloudops-inbound-endpoint"
  direction = "INBOUND"
  
  security_group_ids = [aws_security_group.resolver_sg.id]
  
  ip_address {
    subnet_id = aws_subnet.private_1.id
    ip        = "10.0.1.100"
  }
  
  ip_address {
    subnet_id = aws_subnet.private_2.id
    ip        = "10.0.2.100"
  }
  
  tags = {
    Name = "CloudOps Inbound Resolver"
  }
}

resource "aws_route53_resolver_endpoint" "outbound" {
  name      = "cloudops-outbound-endpoint"
  direction = "OUTBOUND"
  
  security_group_ids = [aws_security_group.resolver_sg.id]
  
  ip_address {
    subnet_id = aws_subnet.private_1.id
  }
  
  ip_address {
    subnet_id = aws_subnet.private_2.id
  }
  
  tags = {
    Name = "CloudOps Outbound Resolver"
  }
}

resource "aws_route53_resolver_rule" "onprem_forward" {
  domain_name          = "onprem.example.com"
  name                 = "onprem-forward-rule"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.outbound.id
  
  target_ip {
    ip   = "192.168.1.10"
    port = 53
  }
  
  target_ip {
    ip   = "192.168.1.11"
    port = 53
  }
  
  tags = {
    Name = "On-premises Forward Rule"
  }
}

resource "aws_route53_resolver_rule_association" "onprem_association" {
  resolver_rule_id = aws_route53_resolver_rule.onprem_forward.id
  vpc_id           = aws_vpc.main.id
}

resource "aws_security_group" "resolver_sg" {
  name_prefix = "resolver-sg"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }
  
  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }
  
  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["192.168.0.0/16"]
  }
  
  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["192.168.0.0/16"]
  }
}
```

## Lab 5: DNS Security and DNSSEC

### Enable DNSSEC
```bash
# Enable DNSSEC signing
aws route53 enable-hosted-zone-dnssec \
  --hosted-zone-id Z123456789ABCDEFGHIJ

# Get DNSSEC status
aws route53 get-dnssec \
  --hosted-zone-id Z123456789ABCDEFGHIJ

# Create DS record in parent zone
aws route53 change-resource-record-sets \
  --hosted-zone-id Z987654321JIHGFEDCBA \
  --change-batch '{
    "Changes": [{
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "cloudops.example.com",
        "Type": "DS",
        "TTL": 300,
        "ResourceRecords": [{"Value": "12345 7 1 1234567890ABCDEF1234567890ABCDEF12345678"}]
      }
    }]
  }'
```

### Terraform DNSSEC Configuration
```hcl
# dnssec.tf
resource "aws_route53_key_signing_key" "main" {
  hosted_zone_id             = aws_route53_zone.main.id
  key_management_service_arn = aws_kms_key.dnssec.arn
  name                       = "cloudops_ksk"
}

resource "aws_route53_hosted_zone_dnssec" "main" {
  hosted_zone_id = aws_route53_key_signing_key.main.hosted_zone_id
}

resource "aws_kms_key" "dnssec" {
  description             = "DNSSEC KSK for cloudops.example.com"
  customer_master_key_spec = "ECC_NIST_P256"
  key_usage               = "SIGN_VERIFY"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow Route 53 DNSSEC Service"
        Effect = "Allow"
        Principal = {
          Service = "dnssec-route53.amazonaws.com"
        }
        Action = [
          "kms:DescribeKey",
          "kms:GetPublicKey",
          "kms:Sign"
        ]
        Resource = "*"
      }
    ]
  })
}
```

## Lab 6: DNS Monitoring and Troubleshooting

### Query Logging
```bash
# Create CloudWatch log group
aws logs create-log-group \
  --log-group-name /aws/route53/queries

# Configure query logging
aws route53 create-query-logging-config \
  --hosted-zone-id Z123456789ABCDEFGHIJ \
  --cloud-watch-logs-log-group-arn arn:aws:logs:us-east-1:123456789012:log-group:/aws/route53/queries
```

### DNS Testing and Troubleshooting
```bash
# Test DNS resolution
dig @8.8.8.8 app.cloudops.example.com A
nslookup app.cloudops.example.com 8.8.8.8

# Test from different locations
dig @resolver1.opendns.com app.cloudops.example.com A
dig @1.1.1.1 app.cloudops.example.com A

# Check health check status
aws route53 get-health-check-status \
  --health-check-id health-check-id

# List health check failures
aws route53 list-health-checks \
  --query 'HealthChecks[?Status==`FAILURE`]'
```

### Terraform Monitoring
```hcl
# monitoring.tf
resource "aws_cloudwatch_log_group" "route53_queries" {
  name              = "/aws/route53/queries"
  retention_in_days = 30
}

resource "aws_route53_query_log" "main" {
  depends_on = [aws_cloudwatch_log_resource_policy.route53_query_logging_policy]
  
  destination_arn = aws_cloudwatch_log_group.route53_queries.arn
  hosted_zone_id  = aws_route53_zone.main.zone_id
}

resource "aws_cloudwatch_log_resource_policy" "route53_query_logging_policy" {
  policy_document = data.aws_iam_policy_document.route53_query_logging_policy.json
  policy_name     = "route53-query-logging-policy"
}

data "aws_iam_policy_document" "route53_query_logging_policy" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    
    resources = ["arn:aws:logs:*:*:log-group:/aws/route53/*"]
    
    principals {
      identifiers = ["route53.amazonaws.com"]
      type        = "Service"
    }
  }
}
```

## Best Practices

1. **Use health checks** for critical endpoints
2. **Implement proper TTL values** for different record types
3. **Use alias records** for AWS resources
4. **Enable query logging** for troubleshooting
5. **Implement DNSSEC** for security
6. **Use private hosted zones** for internal resources
7. **Monitor DNS performance** and availability

## DNS Performance Optimization

```bash
# Check DNS propagation
dig +trace app.cloudops.example.com

# Test from multiple locations
for server in 8.8.8.8 1.1.1.1 208.67.222.222; do
  echo "Testing from $server:"
  dig @$server app.cloudops.example.com A +short
done

# Monitor query response time
aws cloudwatch get-metric-statistics \
  --namespace AWS/Route53 \
  --metric-name QueryTime \
  --dimensions Name=HostedZoneId,Value=Z123456789ABCDEFGHIJ \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-01T23:59:59Z \
  --period 3600 \
  --statistics Average
```

## Cleanup

```bash
# Delete records
aws route53 change-resource-record-sets \
  --hosted-zone-id Z123456789ABCDEFGHIJ \
  --change-batch '{
    "Changes": [{
      "Action": "DELETE",
      "ResourceRecordSet": {
        "Name": "www.cloudops.example.com",
        "Type": "A",
        "TTL": 300,
        "ResourceRecords": [{"Value": "192.0.2.1"}]
      }
    }]
  }'

# Delete health checks
aws route53 delete-health-check \
  --health-check-id health-check-id

# Delete hosted zone
aws route53 delete-hosted-zone \
  --id Z123456789ABCDEFGHIJ
```