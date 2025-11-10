# Section 24: Disaster Recovery and Migrations

## 📋 Overview
This section covers disaster recovery strategies, business continuity planning, and migration approaches for moving workloads to AWS.

## 🔄 Disaster Recovery Strategies

### DR Strategy Types
- **Backup and Restore**: Lowest cost, highest RTO/RPO
- **Pilot Light**: Core systems ready, scale up during disaster
- **Warm Standby**: Scaled-down version running continuously
- **Multi-Site Active/Active**: Full production capacity in multiple sites

### Key Metrics
- **RTO (Recovery Time Objective)**: Maximum acceptable downtime
- **RPO (Recovery Point Objective)**: Maximum acceptable data loss
- **Cost**: Balance between DR capability and expense
- **Complexity**: Operational overhead and management

## 🚀 Migration Strategies

### The 6 R's of Migration
- **Rehost (Lift and Shift)**: Move without changes
- **Replatform (Lift, Tinker, and Shift)**: Minor optimizations
- **Refactor/Re-architect**: Redesign for cloud-native
- **Repurchase**: Move to SaaS solution
- **Retain**: Keep on-premises for now
- **Retire**: Decommission unnecessary systems

### Migration Tools
- **AWS Application Migration Service**: Automated lift-and-shift
- **AWS Database Migration Service**: Database migrations
- **AWS DataSync**: Data transfer service
- **AWS Snow Family**: Offline data transfer
- **AWS Migration Hub**: Centralized migration tracking

## 🛠️ Hands-On Practice

### Practice 1: Backup and Restore Strategy
**Objective**: Implement comprehensive backup and restore procedures

**Steps**:
1. **Set Up Automated Backups**:
   ```bash
   # Create backup vault
   aws backup create-backup-vault \
     --backup-vault-name ProductionBackupVault \
     --encryption-key-arn arn:aws:kms:us-east-1:ACCOUNT_ID:key/KEY_ID
   
   # Create IAM role for AWS Backup
   cat > backup-role-policy.json << 'EOF'
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Principal": {
           "Service": "backup.amazonaws.com"
         },
         "Action": "sts:AssumeRole"
       }
     ]
   }
   EOF
   
   aws iam create-role \
     --role-name AWSBackupDefaultServiceRole \
     --assume-role-policy-document file://backup-role-policy.json
   
   aws iam attach-role-policy \
     --role-name AWSBackupDefaultServiceRole \
     --policy-arn arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup
   
   aws iam attach-role-policy \
     --role-name AWSBackupDefaultServiceRole \
     --policy-arn arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores
   ```

2. **Create Backup Plan**:
   ```bash
   # Create comprehensive backup plan
   cat > backup-plan.json << 'EOF'
   {
     "BackupPlanName": "ProductionBackupPlan",
     "Rules": [
       {
         "RuleName": "DailyBackups",
         "TargetBackupVaultName": "ProductionBackupVault",
         "ScheduleExpression": "cron(0 2 ? * * *)",
         "StartWindowMinutes": 60,
         "CompletionWindowMinutes": 120,
         "Lifecycle": {
           "MoveToColdStorageAfterDays": 30,
           "DeleteAfterDays": 365
         },
         "RecoveryPointTags": {
           "BackupType": "Daily",
           "Environment": "Production"
         }
       },
       {
         "RuleName": "WeeklyBackups",
         "TargetBackupVaultName": "ProductionBackupVault",
         "ScheduleExpression": "cron(0 3 ? * SUN *)",
         "StartWindowMinutes": 60,
         "CompletionWindowMinutes": 180,
         "Lifecycle": {
           "MoveToColdStorageAfterDays": 7,
           "DeleteAfterDays": 2555
         },
         "RecoveryPointTags": {
           "BackupType": "Weekly",
           "Environment": "Production"
         }
       }
     ]
   }
   EOF
   
   # Create backup plan
   BACKUP_PLAN_ID=$(aws backup create-backup-plan \
     --backup-plan file://backup-plan.json \
     --query 'BackupPlanId' --output text)
   
   echo "Created backup plan: $BACKUP_PLAN_ID"
   ```

3. **Create Backup Selection**:
   ```bash
   # Create backup selection for EC2 instances
   cat > backup-selection.json << 'EOF'
   {
     "SelectionName": "ProductionEC2Backup",
     "IamRoleArn": "arn:aws:iam::ACCOUNT_ID:role/AWSBackupDefaultServiceRole",
     "Resources": ["*"],
     "Conditions": {
       "StringEquals": {
         "aws:ResourceTag/Environment": ["Production"],
         "aws:ResourceTag/BackupEnabled": ["true"]
       }
     }
   }
   EOF
   
   # Create backup selection
   aws backup create-backup-selection \
     --backup-plan-id $BACKUP_PLAN_ID \
     --backup-selection file://backup-selection.json
   ```

4. **Test Backup and Restore**:
   ```bash
   # Create backup testing script
   cat > test_backup_restore.py << 'EOF'
   import boto3
   import time
   from datetime import datetime, timedelta
   
   backup_client = boto3.client('backup')
   ec2_client = boto3.client('ec2')
   
   def list_backup_jobs():
       """List recent backup jobs"""
       print("=== Recent Backup Jobs ===")
       
       try:
           response = backup_client.list_backup_jobs(
               MaxResults=10
           )
           
           for job in response['BackupJobs']:
               print(f"\nJob ID: {job['BackupJobId']}")
               print(f"Resource ARN: {job['ResourceArn']}")
               print(f"Status: {job['State']}")
               print(f"Creation Date: {job['CreationDate']}")
               print(f"Completion Date: {job.get('CompletionDate', 'In Progress')}")
               
               if job['State'] == 'COMPLETED':
                   print(f"Recovery Point ARN: {job['RecoveryPointArn']}")
                   
       except Exception as e:
           print(f"Error listing backup jobs: {e}")
   
   def list_recovery_points():
       """List available recovery points"""
       print(f"\n=== Available Recovery Points ===")
       
       try:
           response = backup_client.list_recovery_points_by_backup_vault(
               BackupVaultName='ProductionBackupVault'
           )
           
           for point in response['RecoveryPoints']:
               print(f"\nRecovery Point ARN: {point['RecoveryPointArn']}")
               print(f"Resource ARN: {point['ResourceArn']}")
               print(f"Creation Date: {point['CreationDate']}")
               print(f"Status: {point['Status']}")
               print(f"Size: {point.get('BackupSizeInBytes', 'Unknown')} bytes")
               
       except Exception as e:
           print(f"Error listing recovery points: {e}")
   
   def simulate_restore_job():
       """Simulate a restore job (without actually restoring)"""
       print(f"\n=== Restore Job Simulation ===")
       
       try:
           # Get the latest recovery point
           response = backup_client.list_recovery_points_by_backup_vault(
               BackupVaultName='ProductionBackupVault',
               MaxResults=1
           )
           
           if response['RecoveryPoints']:
               recovery_point = response['RecoveryPoints'][0]
               
               print(f"Would restore from: {recovery_point['RecoveryPointArn']}")
               print(f"Original resource: {recovery_point['ResourceArn']}")
               print(f"Backup date: {recovery_point['CreationDate']}")
               
               # In a real scenario, you would use start_restore_job
               print("Note: Use aws backup start-restore-job to perform actual restore")
               
               restore_metadata = {
                   "InstanceType": "t3.micro",
                   "SubnetId": "subnet-12345",
                   "SecurityGroupIds": "sg-12345"
               }
               
               print(f"Restore metadata example: {restore_metadata}")
           else:
               print("No recovery points available for restore")
               
       except Exception as e:
           print(f"Error in restore simulation: {e}")
   
   def backup_compliance_report():
       """Generate backup compliance report"""
       print(f"\n=== Backup Compliance Report ===")
       
       try:
           # Check backup plan compliance
           response = backup_client.list_backup_plans()
           
           print(f"Total Backup Plans: {len(response['BackupPlansList'])}")
           
           for plan in response['BackupPlansList']:
               print(f"\nPlan: {plan['BackupPlanName']}")
               print(f"Plan ID: {plan['BackupPlanId']}")
               print(f"Version ID: {plan['VersionId']}")
               
               # Get backup selections
               selections_response = backup_client.list_backup_selections(
                   BackupPlanId=plan['BackupPlanId']
               )
               
               print(f"Backup Selections: {len(selections_response['BackupSelectionsList'])}")
               
               for selection in selections_response['BackupSelectionsList']:
                   print(f"  - {selection['SelectionName']}")
           
           # Check recent backup success rate
           end_time = datetime.now()
           start_time = end_time - timedelta(days=7)
           
           jobs_response = backup_client.list_backup_jobs(
               ByCreatedAfter=start_time,
               ByCreatedBefore=end_time
           )
           
           total_jobs = len(jobs_response['BackupJobs'])
           completed_jobs = len([job for job in jobs_response['BackupJobs'] 
                               if job['State'] == 'COMPLETED'])
           failed_jobs = len([job for job in jobs_response['BackupJobs'] 
                            if job['State'] == 'FAILED'])
           
           if total_jobs > 0:
               success_rate = (completed_jobs / total_jobs) * 100
               print(f"\nLast 7 days backup statistics:")
               print(f"Total jobs: {total_jobs}")
               print(f"Completed: {completed_jobs}")
               print(f"Failed: {failed_jobs}")
               print(f"Success rate: {success_rate:.1f}%")
           else:
               print("\nNo backup jobs found in the last 7 days")
               
       except Exception as e:
           print(f"Error generating compliance report: {e}")
   
   if __name__ == "__main__":
       list_backup_jobs()
       list_recovery_points()
       simulate_restore_job()
       backup_compliance_report()
   EOF
   
   python3 test_backup_restore.py
   ```

**Screenshot Placeholder**:
![AWS Backup Configuration](screenshots/24-aws-backup.png)
*Caption: AWS Backup service configuration and monitoring*

### Practice 2: Pilot Light DR Strategy
**Objective**: Implement pilot light disaster recovery architecture

**Steps**:
1. **Set Up DR Region Infrastructure**:
   ```bash
   # Create DR VPC in different region
   export AWS_DEFAULT_REGION=us-west-2
   
   DR_VPC_ID=$(aws ec2 create-vpc \
     --cidr-block 10.2.0.0/16 \
     --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=DR-VPC}]' \
     --query 'Vpc.VpcId' --output text)
   
   # Enable DNS
   aws ec2 modify-vpc-attribute --vpc-id $DR_VPC_ID --enable-dns-hostnames
   aws ec2 modify-vpc-attribute --vpc-id $DR_VPC_ID --enable-dns-support
   
   # Create DR subnets
   DR_SUBNET_1=$(aws ec2 create-subnet \
     --vpc-id $DR_VPC_ID \
     --cidr-block 10.2.1.0/24 \
     --availability-zone us-west-2a \
     --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=DR-Subnet-1}]' \
     --query 'Subnet.SubnetId' --output text)
   
   DR_SUBNET_2=$(aws ec2 create-subnet \
     --vpc-id $DR_VPC_ID \
     --cidr-block 10.2.2.0/24 \
     --availability-zone us-west-2b \
     --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=DR-Subnet-2}]' \
     --query 'Subnet.SubnetId' --output text)
   
   echo "Created DR VPC: $DR_VPC_ID with subnets: $DR_SUBNET_1, $DR_SUBNET_2"
   ```

2. **Set Up Cross-Region Replication**:
   ```bash
   # Create S3 bucket in DR region
   aws s3 mb s3://my-app-dr-bucket-12345 --region us-west-2
   
   # Enable versioning on both buckets
   aws s3api put-bucket-versioning \
     --bucket my-app-dr-bucket-12345 \
     --versioning-configuration Status=Enabled
   
   # Create replication role
   cat > s3-replication-role.json << 'EOF'
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Principal": {
           "Service": "s3.amazonaws.com"
         },
         "Action": "sts:AssumeRole"
       }
     ]
   }
   EOF
   
   aws iam create-role \
     --role-name S3ReplicationRole \
     --assume-role-policy-document file://s3-replication-role.json
   
   # Create replication policy
   cat > s3-replication-policy.json << 'EOF'
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "s3:GetObjectVersionForReplication",
           "s3:GetObjectVersionAcl"
         ],
         "Resource": "arn:aws:s3:::my-app-primary-bucket-12345/*"
       },
       {
         "Effect": "Allow",
         "Action": [
           "s3:ListBucket"
         ],
         "Resource": "arn:aws:s3:::my-app-primary-bucket-12345"
       },
       {
         "Effect": "Allow",
         "Action": [
           "s3:ReplicateObject",
           "s3:ReplicateDelete"
         ],
         "Resource": "arn:aws:s3:::my-app-dr-bucket-12345/*"
       }
     ]
   }
   EOF
   
   aws iam put-role-policy \
     --role-name S3ReplicationRole \
     --policy-name S3ReplicationPolicy \
     --policy-document file://s3-replication-policy.json
   ```

3. **Create DR Automation Scripts**:
   ```bash
   # Create DR failover script
   cat > dr_failover.py << 'EOF'
   import boto3
   import json
   import time
   from datetime import datetime
   
   def initiate_dr_failover():
       """Initiate disaster recovery failover"""
       print("=== DR Failover Initiated ===")
       print(f"Timestamp: {datetime.now().isoformat()}")
       
       # Step 1: Update Route 53 to point to DR region
       print("\n1. Updating DNS to point to DR region...")
       route53 = boto3.client('route53')
       
       # This would update your Route 53 records
       # Example: Change A record to point to DR ALB
       print("   - DNS failover completed")
       
       # Step 2: Scale up DR infrastructure
       print("\n2. Scaling up DR infrastructure...")
       
       # Switch to DR region
       ec2_dr = boto3.client('ec2', region_name='us-west-2')
       
       # Start pre-configured AMIs
       print("   - Starting EC2 instances from AMIs...")
       
       # Step 3: Restore database from latest backup
       print("\n3. Restoring database...")
       rds_dr = boto3.client('rds', region_name='us-west-2')
       
       # Restore RDS from snapshot
       print("   - Database restore initiated...")
       
       # Step 4: Update application configuration
       print("\n4. Updating application configuration...")
       
       # Update parameter store values for DR
       ssm_dr = boto3.client('ssm', region_name='us-west-2')
       
       print("   - Configuration updated")
       
       # Step 5: Verify services
       print("\n5. Verifying services...")
       print("   - Health checks passed")
       
       print(f"\n✅ DR Failover completed at {datetime.now().isoformat()}")
       
       return {
           'status': 'success',
           'failover_time': datetime.now().isoformat(),
           'dr_region': 'us-west-2'
       }
   
   def dr_health_check():
       """Perform DR environment health check"""
       print("=== DR Health Check ===")
       
       health_status = {
           'vpc': False,
           'subnets': False,
           'security_groups': False,
           'amis': False,
           'database_snapshots': False,
           's3_replication': False
       }
       
       try:
           # Check VPC
           ec2_dr = boto3.client('ec2', region_name='us-west-2')
           vpcs = ec2_dr.describe_vpcs(
               Filters=[{'Name': 'tag:Name', 'Values': ['DR-VPC']}]
           )
           health_status['vpc'] = len(vpcs['Vpcs']) > 0
           
           # Check subnets
           subnets = ec2_dr.describe_subnets(
               Filters=[{'Name': 'tag:Name', 'Values': ['DR-Subnet-*']}]
           )
           health_status['subnets'] = len(subnets['Subnets']) >= 2
           
           # Check AMIs
           images = ec2_dr.describe_images(
               Owners=['self'],
               Filters=[{'Name': 'tag:Purpose', 'Values': ['DR']}]
           )
           health_status['amis'] = len(images['Images']) > 0
           
           # Check RDS snapshots
           rds_dr = boto3.client('rds', region_name='us-west-2')
           snapshots = rds_dr.describe_db_snapshots(
               SnapshotType='manual',
               MaxRecords=5
           )
           health_status['database_snapshots'] = len(snapshots['DBSnapshots']) > 0
           
           # Check S3 replication
           s3_dr = boto3.client('s3', region_name='us-west-2')
           try:
               s3_dr.head_bucket(Bucket='my-app-dr-bucket-12345')
               health_status['s3_replication'] = True
           except:
               health_status['s3_replication'] = False
           
       except Exception as e:
           print(f"Error during health check: {e}")
       
       # Print results
       print("\nDR Environment Status:")
       for component, status in health_status.items():
           status_icon = "✅" if status else "❌"
           print(f"{status_icon} {component.replace('_', ' ').title()}: {'Ready' if status else 'Not Ready'}")
       
       overall_health = all(health_status.values())
       print(f"\nOverall DR Readiness: {'✅ Ready' if overall_health else '❌ Not Ready'}")
       
       return health_status
   
   def create_dr_runbook():
       """Create DR runbook documentation"""
       print("=== DR Runbook ===")
       
       runbook = {
           "disaster_recovery_procedures": {
               "detection": [
                   "Monitor primary region health checks",
                   "Check CloudWatch alarms",
                   "Verify application availability"
               ],
               "decision": [
                   "Assess impact and duration",
                   "Get approval from incident commander",
                   "Notify stakeholders"
               ],
               "execution": [
                   "Execute DR failover script",
                   "Update DNS records",
                   "Scale up DR infrastructure",
                   "Restore database from backup",
                   "Update application configuration",
                   "Verify service functionality"
               ],
               "communication": [
                   "Notify customers of service restoration",
                   "Update status page",
                   "Communicate with internal teams"
               ],
               "recovery": [
                   "Monitor DR environment",
                   "Plan failback when primary region recovers",
                   "Conduct post-incident review"
               ]
           },
           "contacts": {
               "incident_commander": "on-call-manager@company.com",
               "technical_lead": "tech-lead@company.com",
               "communications": "comms@company.com"
           },
           "rto_rpo": {
               "rto": "4 hours",
               "rpo": "1 hour"
           }
         }
       
       print(json.dumps(runbook, indent=2))
       
       return runbook
   
   if __name__ == "__main__":
       # Perform health check
       health_status = dr_health_check()
       
       # Create runbook
       runbook = create_dr_runbook()
       
       # Simulate failover (commented out for safety)
       # failover_result = initiate_dr_failover()
       print("\nNote: Actual failover execution is commented out for safety")
   EOF
   
   python3 dr_failover.py
   ```

**Screenshot Placeholder**:
![Pilot Light DR Setup](screenshots/24-pilot-light-dr.png)
*Caption: Pilot light disaster recovery architecture and automation*

### Practice 3: Database Migration with DMS
**Objective**: Migrate database using AWS Database Migration Service

**Steps**:
1. **Set Up DMS Replication Instance**:
   ```bash
   # Create DMS subnet group
   aws dms create-replication-subnet-group \
     --replication-subnet-group-identifier dms-subnet-group \
     --replication-subnet-group-description "DMS subnet group" \
     --subnet-ids $PRIVATE_SUBNET_1 $PRIVATE_SUBNET_2
   
   # Create DMS replication instance
   aws dms create-replication-instance \
     --replication-instance-identifier migration-instance \
     --replication-instance-class dms.t3.micro \
     --allocated-storage 20 \
     --vpc-security-group-ids $DB_SG \
     --replication-subnet-group-identifier dms-subnet-group \
     --multi-az false \
     --publicly-accessible false
   
   # Wait for replication instance
   aws dms wait replication-instance-available \
     --replication-instance-identifier migration-instance
   ```

2. **Create Migration Endpoints**:
   ```bash
   # Create source endpoint (on-premises MySQL)
   aws dms create-endpoint \
     --endpoint-identifier source-mysql \
     --endpoint-type source \
     --engine-name mysql \
     --server-name source-db.example.com \
     --port 3306 \
     --database-name production \
     --username dbuser \
     --password dbpassword
   
   # Create target endpoint (RDS MySQL)
   aws dms create-endpoint \
     --endpoint-identifier target-rds-mysql \
     --endpoint-type target \
     --engine-name mysql \
     --server-name prod-db.cluster-xyz.us-east-1.rds.amazonaws.com \
     --port 3306 \
     --database-name production \
     --username admin \
     --password rdspassword
   ```

3. **Create Migration Task**:
   ```bash
   # Create table mapping rules
   cat > table-mappings.json << 'EOF'
   {
     "rules": [
       {
         "rule-type": "selection",
         "rule-id": "1",
         "rule-name": "1",
         "object-locator": {
           "schema-name": "production",
           "table-name": "%"
         },
         "rule-action": "include"
       },
       {
         "rule-type": "transformation",
         "rule-id": "2",
         "rule-name": "2",
         "rule-target": "table",
         "object-locator": {
           "schema-name": "production",
           "table-name": "users"
         },
         "rule-action": "rename",
         "value": "app_users"
       }
     ]
   }
   EOF
   
   # Create migration task
   aws dms create-replication-task \
     --replication-task-identifier mysql-migration-task \
     --source-endpoint-arn $(aws dms describe-endpoints \
       --endpoint-identifier source-mysql \
       --query 'Endpoints[0].EndpointArn' --output text) \
     --target-endpoint-arn $(aws dms describe-endpoints \
       --endpoint-identifier target-rds-mysql \
       --query 'Endpoints[0].EndpointArn' --output text) \
     --replication-instance-arn $(aws dms describe-replication-instances \
       --replication-instance-identifier migration-instance \
       --query 'ReplicationInstances[0].ReplicationInstanceArn' --output text) \
     --migration-type full-load-and-cdc \
     --table-mappings file://table-mappings.json
   ```

4. **Monitor Migration Progress**:
   ```bash
   # Create migration monitoring script
   cat > monitor_migration.py << 'EOF'
   import boto3
   import time
   import json
   from datetime import datetime
   
   dms_client = boto3.client('dms')
   
   def monitor_migration_task():
       """Monitor DMS migration task progress"""
       print("=== DMS Migration Monitoring ===")
       
       try:
           # Get migration task details
           response = dms_client.describe_replication_tasks(
               Filters=[
                   {
                       'Name': 'replication-task-id',
                       'Values': ['mysql-migration-task']
                   }
               ]
           )
           
           if response['ReplicationTasks']:
               task = response['ReplicationTasks'][0]
               
               print(f"Task ID: {task['ReplicationTaskIdentifier']}")
               print(f"Status: {task['Status']}")
               print(f"Migration Type: {task['MigrationType']}")
               print(f"Source Endpoint: {task['SourceEndpointArn'].split('/')[-1]}")
               print(f"Target Endpoint: {task['TargetEndpointArn'].split('/')[-1]}")
               
               if 'ReplicationTaskStats' in task:
                   stats = task['ReplicationTaskStats']
                   print(f"\nMigration Statistics:")
                   print(f"Full Load Progress: {stats.get('FullLoadProgressPercent', 0)}%")
                   print(f"Tables Loaded: {stats.get('TablesLoaded', 0)}")
                   print(f"Tables Loading: {stats.get('TablesLoading', 0)}")
                   print(f"Tables Queued: {stats.get('TablesQueued', 0)}")
                   print(f"Tables Errored: {stats.get('TablesErrored', 0)}")
               
               # Get table statistics
               table_stats_response = dms_client.describe_table_statistics(
                   ReplicationTaskArn=task['ReplicationTaskArn']
               )
               
               if table_stats_response['TableStatistics']:
                   print(f"\nTable Statistics:")
                   for table_stat in table_stats_response['TableStatistics']:
                       print(f"  Table: {table_stat['SchemaName']}.{table_stat['TableName']}")
                       print(f"    State: {table_stat['TableState']}")
                       print(f"    Full Load Rows: {table_stat.get('FullLoadRows', 0)}")
                       print(f"    Inserts: {table_stat.get('Inserts', 0)}")
                       print(f"    Updates: {table_stat.get('Updates', 0)}")
                       print(f"    Deletes: {table_stat.get('Deletes', 0)}")
           else:
               print("No migration tasks found")
               
       except Exception as e:
           print(f"Error monitoring migration: {e}")
   
   def check_migration_logs():
       """Check migration task logs"""
       print(f"\n=== Migration Logs ===")
       
       try:
           # Get replication instance logs
           response = dms_client.describe_replication_instances(
               Filters=[
                   {
                       'Name': 'replication-instance-id',
                       'Values': ['migration-instance']
                   }
               ]
           )
           
           if response['ReplicationInstances']:
               instance = response['ReplicationInstances'][0]
               
               # In a real scenario, you would check CloudWatch Logs
               print("Check CloudWatch Logs for detailed migration logs:")
               print(f"Log Group: /aws/dms/task/{instance['ReplicationInstanceIdentifier']}")
               
       except Exception as e:
           print(f"Error checking logs: {e}")
   
   def migration_best_practices():
       """Display migration best practices"""
       print(f"\n=== Migration Best Practices ===")
       
       practices = [
           "Test migration with a subset of data first",
           "Monitor source database performance during migration",
           "Use CDC for minimal downtime migrations",
           "Validate data integrity after migration",
           "Plan for rollback procedures",
           "Monitor DMS task performance and logs",
           "Consider network bandwidth and latency",
           "Use appropriate instance size for migration volume"
       ]
       
       for i, practice in enumerate(practices, 1):
           print(f"{i}. {practice}")
   
   if __name__ == "__main__":
       monitor_migration_task()
       check_migration_logs()
       migration_best_practices()
   EOF
   
   python3 monitor_migration.py
   ```

**Screenshot Placeholder**:
![DMS Migration Setup](screenshots/24-dms-migration.png)
*Caption: AWS DMS database migration configuration and monitoring*

### Practice 4: Application Migration with MGN
**Objective**: Use AWS Application Migration Service for server migration

**Steps**:
1. **Set Up MGN Service**:
   ```bash
   # Initialize MGN service
   aws mgn initialize-service
   
   # Create replication configuration template
   cat > replication-config.json << 'EOF'
   {
     "associateDefaultSecurityGroup": true,
     "bandwidthThrottling": 0,
     "createPublicIP": false,
     "dataPlaneRouting": "PRIVATE_IP",
     "defaultLargeStagingDiskType": "GP2",
     "ebsEncryption": "DEFAULT",
     "replicationServerInstanceType": "t3.small",
     "replicationServersSecurityGroupsIDs": ["sg-12345"],
     "stagingAreaSubnetId": "subnet-12345",
     "stagingAreaTags": {
       "Environment": "Migration",
       "Purpose": "Staging"
     },
     "useDedicatedReplicationServer": false
   }
   EOF
   
   # Create replication configuration template
   aws mgn create-replication-configuration-template \
     --cli-input-json file://replication-config.json
   ```

2. **Create Migration Monitoring**:
   ```bash
   # Create MGN monitoring script
   cat > monitor_mgn.py << 'EOF'
   import boto3
   import json
   from datetime import datetime
   
   mgn_client = boto3.client('mgn')
   
   def list_source_servers():
       """List source servers in MGN"""
       print("=== Source Servers ===")
       
       try:
           response = mgn_client.describe_source_servers()
           
           for server in response['items']:
               print(f"\nSource Server ID: {server['sourceServerID']}")
               print(f"Hostname: {server.get('sourceProperties', {}).get('identificationHints', {}).get('hostname', 'Unknown')}")
               print(f"OS: {server.get('sourceProperties', {}).get('os', {}).get('fullString', 'Unknown')}")
               print(f"Replication Status: {server.get('dataReplicationInfo', {}).get('dataReplicationState', 'Unknown')}")
               print(f"Launch Status: {server.get('launchedInstance', {}).get('ec2InstanceID', 'Not Launched')}")
               
               # Show replication progress
               if 'dataReplicationInfo' in server:
                   repl_info = server['dataReplicationInfo']
                   if 'replicatedDisks' in repl_info:
                       print("Disk Replication Progress:")
                       for disk in repl_info['replicatedDisks']:
                           print(f"  Device: {disk.get('deviceName', 'Unknown')}")
                           print(f"  Progress: {disk.get('totalStorageBytes', 0)} bytes")
                           
       except Exception as e:
           print(f"Error listing source servers: {e}")
   
   def check_launch_templates():
       """Check launch templates for migrated servers"""
       print(f"\n=== Launch Templates ===")
       
       try:
           response = mgn_client.describe_launch_configuration_templates()
           
           for template in response['items']:
               print(f"\nTemplate ID: {template['launchConfigurationTemplateID']}")
               print(f"Instance Type: {template.get('ec2LaunchTemplateData', {}).get('instanceType', 'Unknown')}")
               print(f"Security Groups: {template.get('ec2LaunchTemplateData', {}).get('securityGroupIDs', [])}")
               print(f"Subnet ID: {template.get('ec2LaunchTemplateData', {}).get('subnetId', 'Unknown')}")
               
       except Exception as e:
           print(f"Error checking launch templates: {e}")
   
   def migration_wave_management():
       """Demonstrate migration wave management"""
       print(f"\n=== Migration Wave Management ===")
       
       # This would typically involve grouping servers into waves
       migration_waves = {
           "Wave 1 - Web Servers": {
               "servers": ["web-01", "web-02"],
               "dependencies": [],
               "migration_window": "Weekend 1"
           },
           "Wave 2 - Application Servers": {
               "servers": ["app-01", "app-02"],
               "dependencies": ["Wave 1"],
               "migration_window": "Weekend 2"
           },
           "Wave 3 - Database Servers": {
               "servers": ["db-01", "db-02"],
               "dependencies": ["Wave 2"],
               "migration_window": "Weekend 3"
           }
         }
       
       print("Migration Wave Plan:")
       for wave_name, wave_info in migration_waves.items():
           print(f"\n{wave_name}:")
           print(f"  Servers: {', '.join(wave_info['servers'])}")
           print(f"  Dependencies: {', '.join(wave_info['dependencies']) if wave_info['dependencies'] else 'None'}")
           print(f"  Window: {wave_info['migration_window']}")
   
   def post_migration_validation():
       """Post-migration validation checklist"""
       print(f"\n=== Post-Migration Validation ===")
       
       validation_checklist = [
           "Verify all applications are running",
           "Check network connectivity",
           "Validate database connections",
           "Test user authentication",
           "Verify backup procedures",
           "Check monitoring and alerting",
           "Validate security group configurations",
           "Test disaster recovery procedures",
           "Update DNS records if needed",
           "Notify stakeholders of completion"
       ]
       
       print("Validation Checklist:")
       for i, item in enumerate(validation_checklist, 1):
           print(f"{i}. {item}")
   
   if __name__ == "__main__":
       list_source_servers()
       check_launch_templates()
       migration_wave_management()
       post_migration_validation()
   EOF
   
   python3 monitor_mgn.py
   ```

**Screenshot Placeholder**:
![MGN Application Migration](screenshots/24-mgn-migration.png)
*Caption: AWS Application Migration Service setup and monitoring*

## ✅ Section Completion Checklist

- [ ] Implemented automated backup and restore procedures
- [ ] Set up pilot light disaster recovery architecture
- [ ] Configured cross-region replication for critical data
- [ ] Created DR failover automation scripts
- [ ] Set up database migration with DMS
- [ ] Configured application migration with MGN
- [ ] Tested migration procedures and validation
- [ ] Created comprehensive DR runbooks
- [ ] Established RTO/RPO targets and monitoring
- [ ] Documented migration wave planning

## 🎯 Key Takeaways

- **DR Strategy Selection**: Choose based on RTO/RPO requirements and budget
- **Automation**: Automate DR procedures to reduce human error
- **Testing**: Regularly test DR procedures and migration processes
- **Cross-Region**: Use multiple regions for geographic redundancy
- **Data Replication**: Implement appropriate replication strategies
- **Migration Planning**: Plan migrations in waves with dependency mapping
- **Validation**: Thoroughly validate migrated systems and data
- **Documentation**: Maintain detailed runbooks and procedures

## 📚 Additional Resources

- [AWS Disaster Recovery Guide](https://docs.aws.amazon.com/whitepapers/latest/disaster-recovery-workloads-on-aws/)
- [AWS Backup User Guide](https://docs.aws.amazon.com/aws-backup/)
- [AWS DMS User Guide](https://docs.aws.amazon.com/dms/)
- [AWS Application Migration Service](https://docs.aws.amazon.com/mgn/)
- [Migration Best Practices](https://aws.amazon.com/cloud-migration/)
- [AWS Well-Architected Reliability Pillar](https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/)