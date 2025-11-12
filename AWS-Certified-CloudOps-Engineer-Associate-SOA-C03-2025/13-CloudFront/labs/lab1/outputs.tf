output "cloudfront_distribution_id" {
  description = "CloudFront Distribution ID"
  value       = aws_cloudfront_distribution.website_distribution.id
}

output "cloudfront_domain_name" {
  description = "CloudFront Distribution Domain Name"
  value       = aws_cloudfront_distribution.website_distribution.domain_name
}

output "cloudfront_url" {
  description = "CloudFront Distribution URL"
  value       = "https://${aws_cloudfront_distribution.website_distribution.domain_name}"
}

output "s3_bucket_name" {
  description = "S3 Bucket Name"
  value       = aws_s3_bucket.website_bucket.id
}

output "s3_bucket_website_endpoint" {
  description = "S3 Bucket Website Endpoint"
  value       = aws_s3_bucket.website_bucket.bucket_regional_domain_name
}

output "origin_access_control_id" {
  description = "Origin Access Control ID"
  value       = aws_cloudfront_origin_access_control.website_oac.id
}

output "useful_commands" {
  description = "Useful AWS CLI commands for CloudFront management"
  value = {
    # CloudFront commands
    get_distribution = "aws cloudfront get-distribution --id ${aws_cloudfront_distribution.website_distribution.id}"
    list_distributions = "aws cloudfront list-distributions"
    create_invalidation = "aws cloudfront create-invalidation --distribution-id ${aws_cloudfront_distribution.website_distribution.id} --paths '/*'"
    get_invalidation = "aws cloudfront list-invalidations --distribution-id ${aws_cloudfront_distribution.website_distribution.id}"
    
    # S3 commands
    sync_website = "aws s3 sync ./website-files s3://${aws_s3_bucket.website_bucket.id}/"
    list_objects = "aws s3 ls s3://${aws_s3_bucket.website_bucket.id}/ --recursive"
    
    # Testing commands
    test_website = "curl -I https://${aws_cloudfront_distribution.website_distribution.domain_name}"
    test_cache_headers = "curl -H 'Cache-Control: no-cache' https://${aws_cloudfront_distribution.website_distribution.domain_name}"
  }
}

output "performance_urls" {
  description = "URLs for performance testing"
  value = {
    cloudfront_url = "https://${aws_cloudfront_distribution.website_distribution.domain_name}"
    direct_s3_url = "https://${aws_s3_bucket.website_bucket.bucket_regional_domain_name}/index.html"
    css_file = "https://${aws_cloudfront_distribution.website_distribution.domain_name}/assets/style.css"
    error_page = "https://${aws_cloudfront_distribution.website_distribution.domain_name}/nonexistent-page"
  }
}