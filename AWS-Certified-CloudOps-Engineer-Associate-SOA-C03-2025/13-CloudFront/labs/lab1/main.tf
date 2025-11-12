terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Random suffix for unique names
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# S3 Bucket for static website
resource "aws_s3_bucket" "website_bucket" {
  bucket = "${var.project_name}-${var.environment}-website-${random_string.suffix.result}"

  tags = merge(local.common_tags, {
    Name = "CloudFront Website Bucket"
    Type = "Static Website"
  })
}

# S3 Bucket versioning
resource "aws_s3_bucket_versioning" "website_versioning" {
  bucket = aws_s3_bucket.website_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket public access block
resource "aws_s3_bucket_public_access_block" "website_pab" {
  bucket = aws_s3_bucket.website_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Origin Access Control for CloudFront
resource "aws_cloudfront_origin_access_control" "website_oac" {
  name                              = "${var.project_name}-${var.environment}-oac"
  description                       = "OAC for ${var.project_name} website"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "website_distribution" {
  origin {
    domain_name              = aws_s3_bucket.website_bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.website_oac.id
    origin_id                = "S3-${aws_s3_bucket.website_bucket.id}"
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront distribution for ${var.project_name} website"
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.website_bucket.id}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = merge(local.common_tags, {
    Name = "CloudFront Distribution"
    Type = "CDN"
  })
}

# S3 Bucket Policy for CloudFront OAC
resource "aws_s3_bucket_policy" "website_policy" {
  bucket = aws_s3_bucket.website_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.website_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.website_distribution.arn
          }
        }
      }
    ]
  })
}

# Sample website files
resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.website_bucket.id
  key          = "index.html"
  content_type = "text/html"
  content = <<-EOT
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
            .stats { display: flex; justify-content: space-around; margin: 20px 0; }
            .stat { text-align: center; }
            .stat h3 { margin: 0; color: #ff9900; }
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
            
            <div class="stats">
                <div class="stat">
                    <h3>Environment</h3>
                    <p>${var.environment}</p>
                </div>
                <div class="stat">
                    <h3>Project</h3>
                    <p>${var.project_name}</p>
                </div>
                <div class="stat">
                    <h3>Region</h3>
                    <p>${var.aws_region}</p>
                </div>
            </div>
            
            <div class="info">
                <h3>🔧 Technical Details</h3>
                <p><strong>Origin:</strong> Amazon S3</p>
                <p><strong>CDN:</strong> Amazon CloudFront</p>
                <p><strong>Security:</strong> Origin Access Control (OAC)</p>
                <p><strong>Cache TTL:</strong> 1 hour default</p>
                <p><strong>Generated:</strong> ${timestamp()}</p>
            </div>
            
            <p style="text-align: center; color: #666; margin-top: 30px;">
                Powered by AWS CloudFront & Terraform
            </p>
        </div>
    </body>
    </html>
  EOT

  tags = merge(local.common_tags, {
    Name = "Website Index"
    Type = "HTML"
  })
}

resource "aws_s3_object" "error_html" {
  bucket       = aws_s3_bucket.website_bucket.id
  key          = "error.html"
  content_type = "text/html"
  content = <<-EOT
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Page Not Found - CloudOps</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; text-align: center; }
            .container { max-width: 600px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
            h1 { color: #e74c3c; }
            .error-code { font-size: 72px; color: #e74c3c; margin: 20px 0; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="error-code">404</div>
            <h1>Page Not Found</h1>
            <p>The page you're looking for doesn't exist.</p>
            <p><a href="/">← Back to Home</a></p>
        </div>
    </body>
    </html>
  EOT

  tags = merge(local.common_tags, {
    Name = "Error Page"
    Type = "HTML"
  })
}

resource "aws_s3_object" "css_file" {
  bucket       = aws_s3_bucket.website_bucket.id
  key          = "assets/style.css"
  content_type = "text/css"
  content = <<-EOT
    /* CloudOps Demo Styles */
    .highlight {
        background: linear-gradient(45deg, #ff9900, #232f3e);
        color: white;
        padding: 10px 20px;
        border-radius: 5px;
        display: inline-block;
        margin: 10px 0;
    }
    
    .feature-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
        gap: 20px;
        margin: 20px 0;
    }
    
    .feature-card {
        background: #f8f9fa;
        padding: 20px;
        border-radius: 8px;
        border-left: 4px solid #ff9900;
    }
  EOT

  tags = merge(local.common_tags, {
    Name = "Stylesheet"
    Type = "CSS"
  })
}