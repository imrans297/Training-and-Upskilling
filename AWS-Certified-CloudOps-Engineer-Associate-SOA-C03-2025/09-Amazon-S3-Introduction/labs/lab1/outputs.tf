output "main_bucket_name" {
  description = "Name of the main S3 bucket"
  value       = aws_s3_bucket.cloudops_bucket.id
}

output "main_bucket_arn" {
  description = "ARN of the main S3 bucket"
  value       = aws_s3_bucket.cloudops_bucket.arn
}

output "logs_bucket_name" {
  description = "Name of the logs S3 bucket"
  value       = aws_s3_bucket.cloudops_logs.id
}

output "bucket_region" {
  description = "Region where buckets are created"
  value       = aws_s3_bucket.cloudops_bucket.region
}

output "sample_objects" {
  description = "Sample objects created in the bucket"
  value = {
    readme_file = aws_s3_object.sample_file.key
    config_file = aws_s3_object.config_file.key
  }
}

output "aws_cli_commands" {
  description = "Useful AWS CLI commands for testing"
  value = {
    list_buckets = "aws s3 ls"
    list_objects = "aws s3 ls s3://${aws_s3_bucket.cloudops_bucket.id}/ --recursive"
    sync_folder = "aws s3 sync ./local-folder s3://${aws_s3_bucket.cloudops_bucket.id}/uploads/"
    copy_file = "aws s3 cp ./local-file.txt s3://${aws_s3_bucket.cloudops_bucket.id}/uploads/"
    download_file = "aws s3 cp s3://${aws_s3_bucket.cloudops_bucket.id}/samples/readme.txt ./downloaded-readme.txt"
    get_object_versions = "aws s3api list-object-versions --bucket ${aws_s3_bucket.cloudops_bucket.id} --prefix samples/"
  }
}

output "bucket_urls" {
  description = "S3 bucket URLs"
  value = {
    main_bucket = "https://${aws_s3_bucket.cloudops_bucket.id}.s3.${var.aws_region}.amazonaws.com"
    logs_bucket = "https://${aws_s3_bucket.cloudops_logs.id}.s3.${var.aws_region}.amazonaws.com"
  }
}