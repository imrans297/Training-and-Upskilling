# 13. CloudFront

## Lab 1: Basic CloudFront Distribution

### Create CloudFront Distribution
```bash
# Create distribution configuration
cat > distribution-config.json << EOF
{
  "CallerReference": "cloudops-distribution-$(date +%s)",
  "Comment": "CloudOps CDN Distribution",
  "DefaultRootObject": "index.html",
  "Origins": {
    "Quantity": 1,
    "Items": [
      {
        "Id": "S3-cloudops-bucket",
        "DomainName": "cloudops-bucket.s3.amazonaws.com",
        "S3OriginConfig": {
          "OriginAccessIdentity": "origin-access-identity/cloudfront/E1234567890123"
        }
      }
    ]
  },
  "DefaultCacheBehavior": {
    "TargetOriginId": "S3-cloudops-bucket",
    "ViewerProtocolPolicy": "redirect-to-https",
    "TrustedSigners": {
      "Enabled": false,
      "Quantity": 0
    },
    "ForwardedValues": {
      "QueryString": false,
      "Cookies": {
        "Forward": "none"
      }
    },
    "MinTTL": 0,
    "DefaultTTL": 86400,
    "MaxTTL": 31536000
  },
  "Enabled": true,
  "PriceClass": "PriceClass_100"
}
EOF

# Create distribution
aws cloudfront create-distribution \
  --distribution-config file://distribution-config.json

# Get distribution status
aws cloudfront get-distribution \
  --id E1234567890123 \
  --query 'Distribution.Status'
```

### Create Origin Access Identity
```bash
# Create OAI
aws cloudfront create-origin-access-identity \
  --origin-access-identity-config CallerReference="cloudops-oai-$(date +%s)",Comment="CloudOps OAI"

# Update S3 bucket policy for OAI
cat > oai-bucket-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity E1234567890123"
      },
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::cloudops-bucket/*"
    }
  ]
}
EOF

aws s3api put-bucket-policy \
  --bucket cloudops-bucket \
  --policy file://oai-bucket-policy.json
```

## Terraform CloudFront Configuration

```hcl
# cloudfront.tf
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "CloudOps OAI"
}

resource "aws_cloudfront_distribution" "main" {
  origin {
    domain_name = aws_s3_bucket.content.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.content.id}"
    
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }
  
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudOps CDN Distribution"
  default_root_object = "index.html"
  
  aliases = ["cdn.cloudops.example.com"]
  
  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.content.id}"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
    
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    
    min_ttl     = 0
    default_ttl = 86400
    max_ttl     = 31536000
  }
  
  # Cache behavior for API endpoints
  ordered_cache_behavior {
    path_pattern           = "/api/*"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = "ALB-${aws_lb.api.name}"
    compress               = true
    viewer_protocol_policy = "https-only"
    
    forwarded_values {
      query_string = true
      headers      = ["Authorization", "CloudFront-Forwarded-Proto"]
      cookies {
        forward = "all"
      }
    }
    
    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }
  
  price_class = "PriceClass_100"
  
  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE"]
    }
  }
  
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
  
  tags = {
    Name = "CloudOps Distribution"
  }
}

# Multiple origins
resource "aws_cloudfront_distribution" "multi_origin" {
  # S3 Origin
  origin {
    domain_name = aws_s3_bucket.content.bucket_regional_domain_name
    origin_id   = "S3-content"
    
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }
  
  # ALB Origin
  origin {
    domain_name = aws_lb.api.dns_name
    origin_id   = "ALB-api"
    
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }
  
  enabled = true
  
  default_cache_behavior {
    target_origin_id       = "S3-content"
    viewer_protocol_policy = "redirect-to-https"
    
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }
  
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
```

## Lab 2: Custom SSL Certificate

### Request ACM Certificate
```bash
# Request certificate
aws acm request-certificate \
  --domain-name cdn.cloudops.example.com \
  --subject-alternative-names "*.cloudops.example.com" \
  --validation-method DNS \
  --region us-east-1

# Get certificate validation records
aws acm describe-certificate \
  --certificate-arn arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012 \
  --query 'Certificate.DomainValidationOptions'

# Update distribution with custom certificate
aws cloudfront update-distribution \
  --id E1234567890123 \
  --distribution-config file://updated-distribution-config.json \
  --if-match ETAG-VALUE
```

### Terraform SSL Configuration
```hcl
# ssl.tf
resource "aws_acm_certificate" "cert" {
  domain_name               = "cdn.cloudops.example.com"
  subject_alternative_names = ["*.cloudops.example.com"]
  validation_method         = "DNS"
  
  lifecycle {
    create_before_destroy = true
  }
  
  tags = {
    Name = "CloudOps CDN Certificate"
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.main.zone_id
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}
```

## Lab 3: Cache Behaviors and Optimization

### Configure Cache Behaviors
```bash
# Create cache behavior for different content types
cat > cache-behaviors.json << EOF
{
  "CacheBehaviors": {
    "Quantity": 3,
    "Items": [
      {
        "PathPattern": "/images/*",
        "TargetOriginId": "S3-cloudops-bucket",
        "ViewerProtocolPolicy": "https-only",
        "ForwardedValues": {
          "QueryString": false,
          "Cookies": {"Forward": "none"}
        },
        "MinTTL": 86400,
        "DefaultTTL": 604800,
        "MaxTTL": 31536000,
        "Compress": true
      },
      {
        "PathPattern": "/api/*",
        "TargetOriginId": "ALB-api",
        "ViewerProtocolPolicy": "https-only",
        "ForwardedValues": {
          "QueryString": true,
          "Headers": ["Authorization", "Content-Type"],
          "Cookies": {"Forward": "all"}
        },
        "MinTTL": 0,
        "DefaultTTL": 0,
        "MaxTTL": 0
      },
      {
        "PathPattern": "*.css",
        "TargetOriginId": "S3-cloudops-bucket",
        "ViewerProtocolPolicy": "https-only",
        "ForwardedValues": {
          "QueryString": false,
          "Cookies": {"Forward": "none"}
        },
        "MinTTL": 31536000,
        "DefaultTTL": 31536000,
        "MaxTTL": 31536000,
        "Compress": true
      }
    ]
  }
}
EOF
```

### Cache Invalidation
```bash
# Create invalidation
aws cloudfront create-invalidation \
  --distribution-id E1234567890123 \
  --invalidation-batch Paths="/*",CallerReference="invalidation-$(date +%s)"

# Create specific path invalidation
aws cloudfront create-invalidation \
  --distribution-id E1234567890123 \
  --invalidation-batch Paths="/images/*,/css/*",CallerReference="assets-invalidation-$(date +%s)"

# Check invalidation status
aws cloudfront get-invalidation \
  --distribution-id E1234567890123 \
  --id I1234567890123
```

### Terraform Cache Configuration
```hcl
# cache-behaviors.tf
resource "aws_cloudfront_distribution" "optimized" {
  origin {
    domain_name = aws_s3_bucket.content.bucket_regional_domain_name
    origin_id   = "S3-content"
    
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }
  
  enabled = true
  
  # Default behavior for HTML content
  default_cache_behavior {
    target_origin_id       = "S3-content"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    
    min_ttl     = 0
    default_ttl = 86400
    max_ttl     = 31536000
  }
  
  # Cache behavior for images
  ordered_cache_behavior {
    path_pattern           = "/images/*"
    target_origin_id       = "S3-content"
    viewer_protocol_policy = "https-only"
    compress               = true
    
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    
    min_ttl     = 86400
    default_ttl = 604800
    max_ttl     = 31536000
  }
  
  # Cache behavior for CSS/JS
  ordered_cache_behavior {
    path_pattern           = "*.{css,js}"
    target_origin_id       = "S3-content"
    viewer_protocol_policy = "https-only"
    compress               = true
    
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    
    min_ttl     = 31536000
    default_ttl = 31536000
    max_ttl     = 31536000
  }
  
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
```

## Lab 4: Lambda@Edge Functions

### Create Lambda@Edge Function
```python
# lambda-edge-function.py
import json

def lambda_handler(event, context):
    request = event['Records'][0]['cf']['request']
    headers = request['headers']
    
    # Add security headers
    response = {
        'status': '200',
        'statusDescription': 'OK',
        'headers': {
            'strict-transport-security': [{
                'key': 'Strict-Transport-Security',
                'value': 'max-age=31536000; includeSubDomains'
            }],
            'x-content-type-options': [{
                'key': 'X-Content-Type-Options',
                'value': 'nosniff'
            }],
            'x-frame-options': [{
                'key': 'X-Frame-Options',
                'value': 'DENY'
            }],
            'x-xss-protection': [{
                'key': 'X-XSS-Protection',
                'value': '1; mode=block'
            }]
        }
    }
    
    # A/B Testing logic
    if 'cloudfront-viewer-country' in headers:
        country = headers['cloudfront-viewer-country'][0]['value']
        if country == 'US':
            request['uri'] = '/us' + request['uri']
        elif country == 'GB':
            request['uri'] = '/uk' + request['uri']
    
    return request
```

### Deploy Lambda@Edge
```bash
# Create Lambda function in us-east-1 (required for Lambda@Edge)
aws lambda create-function \
  --region us-east-1 \
  --function-name cloudops-edge-function \
  --runtime python3.9 \
  --role arn:aws:iam::123456789012:role/lambda-edge-role \
  --handler lambda_function.lambda_handler \
  --zip-file fileb://function.zip

# Publish version
aws lambda publish-version \
  --function-name cloudops-edge-function \
  --region us-east-1

# Associate with CloudFront distribution
aws cloudfront update-distribution \
  --id E1234567890123 \
  --distribution-config file://distribution-with-lambda-edge.json \
  --if-match ETAG-VALUE
```

### Terraform Lambda@Edge
```hcl
# lambda-edge.tf
resource "aws_lambda_function" "edge_function" {
  provider = aws.us_east_1
  
  filename         = "edge-function.zip"
  function_name    = "cloudops-edge-function"
  role            = aws_iam_role.lambda_edge_role.arn
  handler         = "lambda_function.lambda_handler"
  runtime         = "python3.9"
  timeout         = 5
  
  publish = true
}

resource "aws_cloudfront_distribution" "with_lambda_edge" {
  origin {
    domain_name = aws_s3_bucket.content.bucket_regional_domain_name
    origin_id   = "S3-content"
    
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }
  
  enabled = true
  
  default_cache_behavior {
    target_origin_id       = "S3-content"
    viewer_protocol_policy = "redirect-to-https"
    
    lambda_function_association {
      event_type   = "viewer-request"
      lambda_arn   = aws_lambda_function.edge_function.qualified_arn
      include_body = false
    }
    
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }
  
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_iam_role" "lambda_edge_role" {
  name = "lambda-edge-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = [
            "lambda.amazonaws.com",
            "edgelambda.amazonaws.com"
          ]
        }
      }
    ]
  })
}
```

## Lab 5: CloudFront Monitoring and Analytics

### Enable Real-time Logs
```bash
# Create real-time log configuration
aws cloudfront create-realtime-log-config \
  --name cloudops-realtime-logs \
  --end-points StreamType=Kinesis,KinesisStreamConfig='{RoleArn=arn:aws:iam::123456789012:role/cloudfront-realtime-logs-role,StreamArn=arn:aws:kinesis:us-east-1:123456789012:stream/cloudfront-logs}' \
  --fields timestamp c-ip sc-status cs-method cs-uri-stem

# Associate with distribution
aws cloudfront update-distribution \
  --id E1234567890123 \
  --distribution-config file://distribution-with-realtime-logs.json \
  --if-match ETAG-VALUE
```

### CloudWatch Metrics and Alarms
```bash
# Create alarm for high error rate
aws cloudwatch put-metric-alarm \
  --alarm-name "CloudFront-High-4xx-Errors" \
  --alarm-description "High 4xx error rate" \
  --metric-name 4xxErrorRate \
  --namespace AWS/CloudFront \
  --statistic Average \
  --period 300 \
  --threshold 5 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=DistributionId,Value=E1234567890123 \
  --evaluation-periods 2

# Create alarm for cache hit ratio
aws cloudwatch put-metric-alarm \
  --alarm-name "CloudFront-Low-Cache-Hit-Rate" \
  --alarm-description "Low cache hit rate" \
  --metric-name CacheHitRate \
  --namespace AWS/CloudFront \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator LessThanThreshold \
  --dimensions Name=DistributionId,Value=E1234567890123 \
  --evaluation-periods 3
```

### Terraform Monitoring Configuration
```hcl
# monitoring.tf
resource "aws_cloudwatch_metric_alarm" "high_error_rate" {
  alarm_name          = "CloudFront-High-4xx-Errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "4xxErrorRate"
  namespace           = "AWS/CloudFront"
  period              = "300"
  statistic           = "Average"
  threshold           = "5"
  alarm_description   = "High 4xx error rate"
  
  dimensions = {
    DistributionId = aws_cloudfront_distribution.main.id
  }
  
  alarm_actions = [aws_sns_topic.cloudfront_alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "low_cache_hit_rate" {
  alarm_name          = "CloudFront-Low-Cache-Hit-Rate"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "CacheHitRate"
  namespace           = "AWS/CloudFront"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Low cache hit rate"
  
  dimensions = {
    DistributionId = aws_cloudfront_distribution.main.id
  }
  
  alarm_actions = [aws_sns_topic.cloudfront_alerts.arn]
}

resource "aws_sns_topic" "cloudfront_alerts" {
  name = "cloudfront-alerts"
}
```

## Lab 6: Security and Access Control

### Signed URLs and Cookies
```python
# signed-urls.py
import boto3
from botocore.signers import CloudFrontSigner
from datetime import datetime, timedelta
import rsa

def create_signed_url(url, key_id, private_key_path, expiration_hours=1):
    # Load private key
    with open(private_key_path, 'rb') as key_file:
        private_key = rsa.PrivateKey.load_pkcs1(key_file.read())
    
    # Create signer
    signer = CloudFrontSigner(key_id, private_key)
    
    # Set expiration
    expire_date = datetime.utcnow() + timedelta(hours=expiration_hours)
    
    # Create signed URL
    signed_url = signer.generate_presigned_url(
        url, date_less_than=expire_date
    )
    
    return signed_url

# Usage
signed_url = create_signed_url(
    'https://d1234567890123.cloudfront.net/private/video.mp4',
    'K1234567890123',
    'private_key.pem',
    24
)
```

### WAF Integration
```bash
# Create WAF web ACL
aws wafv2 create-web-acl \
  --name cloudops-waf-acl \
  --scope CLOUDFRONT \
  --default-action Allow={} \
  --rules '[
    {
      "Name": "RateLimitRule",
      "Priority": 1,
      "Statement": {
        "RateBasedStatement": {
          "Limit": 2000,
          "AggregateKeyType": "IP"
        }
      },
      "Action": {
        "Block": {}
      },
      "VisibilityConfig": {
        "SampledRequestsEnabled": true,
        "CloudWatchMetricsEnabled": true,
        "MetricName": "RateLimitRule"
      }
    }
  ]'

# Associate WAF with CloudFront
aws cloudfront update-distribution \
  --id E1234567890123 \
  --distribution-config file://distribution-with-waf.json \
  --if-match ETAG-VALUE
```

### Terraform Security Configuration
```hcl
# security.tf
resource "aws_wafv2_web_acl" "cloudfront_waf" {
  name  = "cloudops-waf-acl"
  scope = "CLOUDFRONT"
  
  default_action {
    allow {}
  }
  
  rule {
    name     = "RateLimitRule"
    priority = 1
    
    action {
      block {}
    }
    
    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }
    
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitRule"
      sampled_requests_enabled   = true
    }
  }
  
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "CloudOpsWAF"
    sampled_requests_enabled   = true
  }
}

resource "aws_cloudfront_distribution" "secure" {
  web_acl_id = aws_wafv2_web_acl.cloudfront_waf.arn
  
  # ... other configuration
}
```

## Best Practices

1. **Use Origin Access Identity** for S3 origins
2. **Enable compression** for better performance
3. **Configure appropriate TTLs** for different content types
4. **Use custom SSL certificates** for branded domains
5. **Implement security headers** with Lambda@Edge
6. **Monitor performance** with CloudWatch
7. **Use WAF** for additional security

## Performance Optimization

```bash
# Check distribution performance
aws cloudfront get-distribution-config \
  --id E1234567890123 \
  --query 'DistributionConfig.DefaultCacheBehavior'

# Monitor cache statistics
aws cloudwatch get-metric-statistics \
  --namespace AWS/CloudFront \
  --metric-name CacheHitRate \
  --dimensions Name=DistributionId,Value=E1234567890123 \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-01T23:59:59Z \
  --period 3600 \
  --statistics Average
```

## Cleanup

```bash
# Disable distribution
aws cloudfront update-distribution \
  --id E1234567890123 \
  --distribution-config file://disabled-distribution-config.json \
  --if-match ETAG-VALUE

# Delete distribution (after disabled)
aws cloudfront delete-distribution \
  --id E1234567890123 \
  --if-match ETAG-VALUE

# Delete OAI
aws cloudfront delete-origin-access-identity \
  --id E1234567890123 \
  --if-match ETAG-VALUE
```