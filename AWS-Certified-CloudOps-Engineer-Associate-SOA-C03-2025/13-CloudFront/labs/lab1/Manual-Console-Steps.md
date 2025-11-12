# CloudFront Lab 1: Manual Console Steps

## Overview
This guide provides step-by-step manual instructions to create a CloudFront distribution with S3 origin using the AWS Console.

## Prerequisites
- AWS Console access
- Basic understanding of S3 and CloudFront

## Step 1: Create S3 Bucket

### 1.1 Navigate to S3 Console
1. Go to AWS Console → S3
2. Click **Create bucket**

### 1.2 Configure Bucket
1. **Bucket name**: `cloudops-dev-website-manual`
2. **Region**: `US East (N. Virginia) us-east-1`
3. **Object Ownership**: ACLs disabled (recommended)
4. **Block Public Access**: Keep all settings checked ✅
5. **Bucket Versioning**: Enable
6. **Default encryption**: Server-side encryption with Amazon S3 managed keys (SSE-S3)
7. Click **Create bucket**

![S3 Bucket Creation](screenshots/s3-bucket-creation.png)

## Step 2: Upload Website Files

### 2.1 Create index.html locally
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CloudOps CloudFront Demo</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #232f3e; text-align: center; }
        .info { background: #e8f4fd; padding: 20px; border-radius: 5px; margin: 20px 0; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 CloudOps CloudFront Demo</h1>
        <div class="info">
            <h3>Welcome to CloudFront CDN!</h3>
            <p>This static website is served through Amazon CloudFront for:</p>
            <ul>
                <li>⚡ Faster global content delivery</li>
                <li>🔒 Enhanced security with HTTPS</li>
                <li>💰 Reduced origin server load</li>
                <li>🌍 Better user experience worldwide</li>
            </ul>
        </div>
        <p style="text-align: center; color: #666; margin-top: 30px;">
            Powered by AWS CloudFront - Manual Setup
        </p>
    </div>
</body>
</html>
```

### 2.2 Upload Files to S3
1. Click on your bucket name
2. Click **Upload**
3. **Add files**: Select `index.html`
4. **Permissions**: Use bucket settings for object ACL
5. **Properties**: Standard storage class
6. Click **Upload**

![S3 File Upload](screenshots/s3-file-upload.png)

## Step 3: Create Origin Access Control (OAC)

### 3.1 Navigate to CloudFront Console
1. Go to AWS Console → CloudFront
2. In left sidebar, click **Origin access**
3. Click **Create origin access control**

### 3.2 Configure OAC
1. **Name**: `cloudops-dev-oac`
2. **Description**: `OAC for CloudOps website`
3. **Origin type**: S3
4. **Signing behavior**: Sign requests (recommended)
5. **Origin access control**: Create origin access control
6. Click **Create**

![OAC Creation](screenshots/oac-creation.png)

## Step 4: Create CloudFront Distribution

### 4.1 Start Distribution Creation
1. In CloudFront console, click **Create distribution**

### 4.2 Origin Settings
1. **Origin domain**: Select your S3 bucket from dropdown
   - `cloudops-dev-website-manual.s3.us-east-1.amazonaws.com`
2. **Origin path**: Leave empty
3. **Name**: Auto-filled (keep default)
4. **Origin access**: Origin access control settings (recommended)
5. **Origin access control**: Select the OAC created in Step 3
6. **Enable Origin Shield**: No

![Origin Settings](screenshots/origin-settings.png)

### 4.3 Default Cache Behavior
1. **Path pattern**: Default (*)
2. **Compress objects automatically**: Yes
3. **Viewer protocol policy**: Redirect HTTP to HTTPS
4. **Allowed HTTP methods**: GET, HEAD
5. **Restrict viewer access**: No
6. **Cache key and origin requests**: Cache policy and origin request policy (recommended)
7. **Cache policy**: Managed-CachingOptimized
8. **Origin request policy**: None
9. **Response headers policy**: None

![Cache Behavior](screenshots/cache-behavior.png)

### 4.4 Function Associations
1. **Viewer request**: None
2. **Origin request**: None
3. **Origin response**: None
4. **Viewer response**: None

### 4.5 Distribution Settings
1. **Price class**: Use only North America and Europe
2. **Alternate domain name (CNAME)**: Leave empty
3. **Custom SSL certificate**: Default CloudFront SSL certificate
4. **Supported HTTP versions**: HTTP/2 and HTTP/1.1
5. **Default root object**: `index.html`
6. **Standard logging**: Off
7. **IPv6**: On
8. **Description**: `CloudFront distribution for CloudOps website`
9. **Distribution state**: Enabled

![Distribution Settings](screenshots/distribution-settings.png)

### 4.6 Create Distribution
1. Click **Create distribution**
2. **Note**: Distribution deployment takes 15-20 minutes

![Distribution Creation](screenshots/distribution-creation.png)

## Step 5: Update S3 Bucket Policy

### 5.1 Copy Distribution ARN
1. In CloudFront console, click on your distribution
2. Copy the **Distribution ARN** (e.g., `arn:aws:cloudfront::123456789012:distribution/E1234567890ABC`)

### 5.2 Update S3 Bucket Policy
1. Go to S3 console → Your bucket
2. Click **Permissions** tab
3. Scroll to **Bucket policy**
4. Click **Edit**
5. Paste the following policy (replace with your values):

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
            "Resource": "arn:aws:s3:::cloudops-dev-website-manual/*",
            "Condition": {
                "StringEquals": {
                    "AWS:SourceArn": "arn:aws:cloudfront::123456789012:distribution/E1234567890ABC"
                }
            }
        }
    ]
}
```

6. Click **Save changes**

![S3 Bucket Policy](screenshots/s3-bucket-policy.png)

## Step 6: Test CloudFront Distribution

### 6.1 Get Distribution Domain Name
1. In CloudFront console, find your distribution
2. Copy the **Distribution domain name** (e.g., `d1234567890abc.cloudfront.net`)
3. **Status** should show "Deployed"

![Distribution Status](screenshots/distribution-status.png)

### 6.2 Test Website
1. Open browser and navigate to: `https://d1234567890abc.cloudfront.net`
2. Verify the website loads correctly
3. Check that HTTP redirects to HTTPS

![Website Test](screenshots/website-test.png)

### 6.3 Test Performance
1. **First load**: May be slower (cache miss)
2. **Subsequent loads**: Should be faster (cache hit)
3. Check response headers for CloudFront information

## Step 7: Monitor and Manage

### 7.1 CloudWatch Metrics
1. Go to CloudWatch console
2. Navigate to **Metrics** → **CloudFront**
3. View distribution metrics:
   - Requests
   - BytesDownloaded
   - OriginLatency
   - CacheHitRate

![CloudWatch Metrics](screenshots/cloudwatch-metrics.png)

### 7.2 Create Invalidation
1. In CloudFront console, select your distribution
2. Click **Invalidations** tab
3. Click **Create invalidation**
4. **Object paths**: `/*` (invalidate all)
5. Click **Create invalidation**

![Invalidation](screenshots/invalidation.png)

## Step 8: Update Content

### 8.1 Upload New Content
1. Modify `index.html` locally
2. Upload to S3 bucket (overwrites existing)
3. Create CloudFront invalidation for updated files

### 8.2 Verify Updates
1. Wait for invalidation to complete
2. Refresh browser to see updated content
3. Check cache headers to confirm fresh content

## Troubleshooting

### Common Issues

#### 1. 403 Forbidden Error
**Cause**: Incorrect S3 bucket policy or OAC configuration
**Solution**: 
- Verify bucket policy has correct distribution ARN
- Ensure OAC is properly configured
- Check that bucket is not publicly accessible

#### 2. Distribution Not Deploying
**Cause**: CloudFront deployment in progress
**Solution**: 
- Wait 15-20 minutes for global deployment
- Check distribution status in console

#### 3. Old Content Still Showing
**Cause**: Content cached at edge locations
**Solution**: 
- Create invalidation for updated files
- Wait for invalidation to complete
- Use hard refresh (Ctrl+F5)

### Verification Commands
```bash
# Test CloudFront response
curl -I https://d1234567890abc.cloudfront.net

# Check for CloudFront headers
curl -v https://d1234567890abc.cloudfront.net 2>&1 | grep -i "x-cache\|x-amz-cf"

# Test direct S3 access (should fail)
curl -I https://cloudops-dev-website-manual.s3.amazonaws.com/index.html
```

## Cost Considerations

### Estimated Monthly Costs
- **Data Transfer**: $0.085/GB (first 10TB)
- **HTTP/HTTPS Requests**: $0.0075/10,000 requests
- **Invalidations**: First 1,000 free, then $0.005 each

### Cost Optimization Tips
1. Use appropriate price class
2. Set proper cache TTL values
3. Minimize invalidations
4. Enable compression

## Security Best Practices

### Implemented Security
✅ **Private S3 Bucket**: No public access
✅ **Origin Access Control**: Secure CloudFront-to-S3 access
✅ **HTTPS Enforcement**: Automatic HTTP to HTTPS redirect
✅ **Bucket Policy**: Restricts access to specific CloudFront distribution

### Additional Security (Optional)
- Custom SSL certificate for custom domain
- WAF integration for additional protection
- Signed URLs for restricted content
- Geographic restrictions

## Next Steps
1. **Custom Domain**: Add custom domain with SSL certificate
2. **Multiple Origins**: Configure additional origins (API, images)
3. **Lambda@Edge**: Add serverless functions at edge locations
4. **Monitoring**: Set up detailed monitoring and alerts

## Cleanup Steps
1. **Delete CloudFront Distribution**:
   - Disable distribution first
   - Wait for deployment
   - Delete distribution
2. **Delete S3 Bucket**:
   - Empty bucket contents
   - Delete bucket
3. **Delete OAC**: Remove origin access control

**Note**: CloudFront distribution deletion takes 15-20 minutes to complete.