# Lab 1: Basic CloudFront Distribution

## Overview
This lab creates a basic CloudFront distribution with S3 as the origin, demonstrating CDN fundamentals, Origin Access Control (OAC), and static website hosting through CloudFront.

## Architecture
![CloudFront Architecture](screenshots/cloudfront-architecture.png)

## What We're Building
- **S3 Origin Bucket**: Static website storage
- **CloudFront Distribution**: Global CDN with caching
- **Origin Access Control**: Secure S3 access
- **Sample Website**: HTML, CSS, and error pages
- **HTTPS Redirect**: Automatic SSL/TLS

## Key Features
✅ **Global CDN**: Fast content delivery worldwide  
✅ **Origin Access Control**: Secure S3 bucket access  
✅ **HTTPS Enforcement**: Automatic redirect to HTTPS  
✅ **Caching**: Configurable TTL for performance  
✅ **Error Handling**: Custom 404 error page  

## Terraform Resources

### 1. S3 Origin Bucket
- **Purpose**: Store static website files
- **Security**: Private bucket with OAC access only
- **Versioning**: Enabled for content management

### 2. CloudFront Distribution
- **Origin**: S3 bucket with OAC
- **Caching**: 1-hour default TTL
- **Security**: HTTPS redirect enforced
- **Price Class**: 100 (US, Canada, Europe)

### 3. Sample Content
- **index.html**: Main website page
- **error.html**: Custom 404 page
- **style.css**: Stylesheet for styling

## Deployment

### Step 1: Deploy Infrastructure
```bash
cd labs/lab1
terraform init
terraform plan
terraform apply
```
![Terraform Apply](screenshots/terraform-apply.png)

### Step 2: Get Distribution URL
```bash
terraform output cloudfront_url
```
![Terraform Output](screenshots/terraform-output.png)

**Note**: CloudFront deployment takes 15-20 minutes to complete globally.

## Testing CloudFront

### Basic Functionality
```bash
# Test main website
curl -I https://d1234567890abc.cloudfront.net

# Test with cache headers
curl -H "Cache-Control: no-cache" https://d1234567890abc.cloudfront.net

# Test CSS file
curl -I https://d1234567890abc.cloudfront.net/assets/style.css

# Test 404 error page
curl -I https://d1234567890abc.cloudfront.net/nonexistent-page
```
![Basic Testing](screenshots/basic-testing.png)

### Performance Comparison
```bash
# CloudFront (cached)
time curl -s https://d1234567890abc.cloudfront.net > /dev/null

# Direct S3 (origin)
time curl -s https://bucket-name.s3.amazonaws.com/index.html > /dev/null
```
![Performance Test](screenshots/performance-test.png)

### Cache Behavior Testing
```bash
# First request (cache miss)
curl -w "%{time_total}" https://d1234567890abc.cloudfront.net

# Second request (cache hit)
curl -w "%{time_total}" https://d1234567890abc.cloudfront.net
```

## CloudFront Management

### Invalidation
```bash
# Invalidate all files
aws cloudfront create-invalidation \
  --distribution-id E1234567890ABC \
  --paths "/*"

# Invalidate specific files
aws cloudfront create-invalidation \
  --distribution-id E1234567890ABC \
  --paths "/index.html" "/assets/*"

# Check invalidation status
aws cloudfront list-invalidations \
  --distribution-id E1234567890ABC
```
![Invalidation](screenshots/invalidation.png)

### Distribution Status
```bash
# Get distribution details
aws cloudfront get-distribution --id E1234567890ABC

# List all distributions
aws cloudfront list-distributions

# Get distribution configuration
aws cloudfront get-distribution-config --id E1234567890ABC
```

## Content Updates

### Update Website Content
```bash
# Create new content locally
echo "<h1>Updated Content</h1>" > updated-index.html

# Upload to S3
aws s3 cp updated-index.html s3://bucket-name/index.html

# Invalidate CloudFront cache
aws cloudfront create-invalidation \
  --distribution-id E1234567890ABC \
  --paths "/index.html"
```
![Content Update](screenshots/content-update.png)

### Batch Upload
```bash
# Sync entire directory
aws s3 sync ./website-files s3://bucket-name/

# Invalidate all cached content
aws cloudfront create-invalidation \
  --distribution-id E1234567890ABC \
  --paths "/*"
```

## Monitoring and Analytics

### CloudWatch Metrics
```bash
# Get CloudFront metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/CloudFront \
  --metric-name Requests \
  --dimensions Name=DistributionId,Value=E1234567890ABC \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z \
  --period 3600 \
  --statistics Sum
```

### Real-time Logs (if enabled)
```bash
# Configure real-time logs
aws cloudfront create-realtime-log-config \
  --name cloudops-realtime-logs \
  --end-points StreamType=Kinesis,KinesisStreamConfig='{RoleArn=arn:aws:iam::123456789012:role/CloudFrontRealtimeLogRole,StreamArn=arn:aws:kinesis:us-east-1:123456789012:stream/cloudfront-logs}' \
  --fields timestamp c-ip sc-status cs-method cs-uri-stem
```

![CloudFront Metrics](screenshots/cloudfront-metrics.png)

## Security Features

### Origin Access Control (OAC)
```json
{
  "OriginAccessControlConfig": {
    "Name": "cloudops-dev-oac",
    "Description": "OAC for cloudops website",
    "OriginAccessControlOriginType": "s3",
    "SigningBehavior": "always",
    "SigningProtocol": "sigv4"
  }
}
```

### S3 Bucket Policy
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowCloudFrontServicePrincipal",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudfront.amazonaws.com"
      },
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::bucket-name/*",
      "Condition": {
        "StringEquals": {
          "AWS:SourceArn": "arn:aws:cloudfront::123456789012:distribution/E1234567890ABC"
        }
      }
    }
  ]
}
```

## Performance Optimization

### Cache Behaviors
- **Default TTL**: 3600 seconds (1 hour)
- **Maximum TTL**: 86400 seconds (24 hours)
- **Minimum TTL**: 0 seconds

### Compression
```hcl
default_cache_behavior {
  compress = true
  # Other settings...
}
```

### Price Classes
- **PriceClass_All**: All edge locations (highest cost)
- **PriceClass_200**: US, Canada, Europe, Asia, Middle East, Africa
- **PriceClass_100**: US, Canada, Europe (lowest cost)

![Performance Metrics](screenshots/performance-metrics.png)

## Troubleshooting

### Common Issues
1. **403 Forbidden**: Check OAC and S3 bucket policy
2. **Slow initial load**: CloudFront deployment in progress
3. **Cached old content**: Create invalidation

### Debug Commands
```bash
# Check distribution status
aws cloudfront get-distribution --id E1234567890ABC --query 'Distribution.Status'

# Verify OAC configuration
aws cloudfront get-origin-access-control --id E1234567890ABC

# Test direct S3 access (should fail)
curl -I https://bucket-name.s3.amazonaws.com/index.html
```

### Response Headers Analysis
```bash
# Check CloudFront headers
curl -I https://d1234567890abc.cloudfront.net

# Look for:
# X-Cache: Hit from cloudfront (cached)
# X-Cache: Miss from cloudfront (not cached)
# X-Amz-Cf-Pop: Edge location
# X-Amz-Cf-Id: Request ID
```

## Cost Optimization

### Monthly Cost Estimate
- **Data Transfer**: $0.085/GB (first 10TB)
- **HTTP/HTTPS Requests**: $0.0075/10,000 requests
- **Invalidations**: First 1,000 free, then $0.005 each

### Cost Reduction Tips
1. Use appropriate price class
2. Optimize cache TTL settings
3. Minimize invalidations
4. Compress content

## Use Cases

### 1. Static Website Hosting
- Corporate websites
- Documentation sites
- Landing pages

### 2. API Acceleration
- REST API caching
- GraphQL endpoint caching
- Microservices acceleration

### 3. Media Delivery
- Image optimization
- Video streaming
- Software downloads

## Next Steps
- **Lab 2**: Custom Domain and SSL Certificate
- **Lab 3**: Multiple Origins and Behaviors
- **Lab 4**: Lambda@Edge Functions

## Cleanup
```bash
# Note: CloudFront distributions take time to delete
terraform destroy
```
![Terraform Destroy](screenshots/terraform-destroy.png)

**Important**: CloudFront distribution deletion can take 15-20 minutes to complete.