# Disaster Recovery Labs

## Overview
Multi-region disaster recovery setup with AWS Backup, S3 cross-region replication, and automated failover.

## Architecture
- Primary Region: us-east-1
- DR Region: us-west-2
- AWS Backup with cross-region copy
- S3 cross-region replication
- Automated backup lifecycle

## Resources Created
- 2 Backup Vaults (primary + DR)
- Backup Plan with daily schedule
- 2 S3 Buckets with replication
- KMS Keys for encryption
- IAM Roles and Policies

## Usage

```bash
# Initialize
terraform init

# Plan
terraform plan

# Apply
terraform apply -auto-approve

# Test replication
aws s3 cp test.txt s3://$(terraform output -raw primary_s3_bucket)/
aws s3 ls s3://$(terraform output -raw dr_s3_bucket)/ --region us-west-2

# Destroy
terraform destroy -auto-approve
```

## DR Testing
1. Upload files to primary S3 bucket
2. Verify replication to DR bucket
3. Tag EC2 instances with `Backup=true`
4. Verify backup jobs in AWS Backup console
5. Check cross-region backup copies

## RTO/RPO
- RTO: 15 minutes
- RPO: 5 minutes (backup frequency)
