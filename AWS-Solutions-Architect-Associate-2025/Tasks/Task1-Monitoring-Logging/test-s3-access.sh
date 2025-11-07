#!/bin/bash
echo "Testing S3 access from EC2 instance..."

# Create test file
echo "Test data from $(hostname) at $(date)" > /tmp/s3-test-file.txt

# Upload to S3 (this will use NAT Gateway for internet access)
aws s3 cp /tmp/s3-test-file.txt s3://monitoring-logs-storage-12366645/ec2-tests/

# List S3 bucket contents
aws s3 ls s3://monitoring-logs-storage-12366645/ec2-tests/

# Download file back
aws s3 cp s3://monitoring-logs-storage-12366645/ec2-tests/s3-test-file.txt /tmp/downloaded-file.txt

echo "S3 access test completed successfully!"