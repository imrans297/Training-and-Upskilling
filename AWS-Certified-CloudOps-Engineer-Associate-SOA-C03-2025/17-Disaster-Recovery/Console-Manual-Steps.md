# 🖥️ Disaster Recovery - Manual Console Steps

## **Lab 1: AWS Backup Configuration**

### **Step 1: Create Backup Vault**
1. **Go to AWS Backup Console**
2. **Backup vaults** → **Create backup vault**
3. **Configure:**
   - **Name**: `cloudops-backup-vault`
   - **Encryption**: AWS managed key or select KMS key
4. **Create backup vault**

### **Step 2: Create Backup Plan**
1. **Backup plans** → **Create backup plan**
2. **Start with template** or **Build a new plan**
3. **Configure:**
   - **Name**: `CloudOps-DR-Plan`
   - **Rule name**: `DailyBackups`
   - **Backup frequency**: Daily
   - **Backup window**: Start at 5:00 AM UTC
   - **Lifecycle**: 
     - Move to cold storage: 7 days
     - Delete after: 30 days
4. **Copy to destination:**
   - **Destination region**: us-west-2
   - **Destination vault**: Create new `cloudops-dr-vault`
   - **Lifecycle**: Delete after 90 days
5. **Create plan**

### **Step 3: Assign Resources**
1. **Select backup plan**
2. **Resource assignments** → **Assign resources**
3. **Configure:**
   - **Assignment name**: `CloudOps-Resources`
   - **IAM role**: Default or create new
   - **Resource selection**: Tags
   - **Key**: `Backup`
   - **Value**: `true`
4. **Assign resources**

---

## **Lab 2: S3 Cross-Region Replication**

### **Step 1: Create Primary Bucket**
1. **Go to S3 Console**
2. **Create bucket**
3. **Configure:**
   - **Name**: `cloudops-primary-bucket-unique`
   - **Region**: us-east-1
   - **Versioning**: Enable
4. **Create bucket**

### **Step 2: Create DR Bucket**
1. **Create bucket**
2. **Configure:**
   - **Name**: `cloudops-dr-bucket-unique`
   - **Region**: us-west-2
   - **Versioning**: Enable
3. **Create bucket**

### **Step 3: Configure Replication**
1. **Select primary bucket**
2. **Management** → **Replication rules** → **Create replication rule**
3. **Configure:**
   - **Rule name**: `ReplicateAll`
   - **Status**: Enabled
   - **Source bucket**: Entire bucket
   - **Destination**: 
     - **Bucket**: `cloudops-dr-bucket-unique`
     - **Region**: us-west-2
   - **IAM role**: Create new role
   - **Storage class**: Standard-IA
4. **Save**

### **Step 4: Test Replication**
1. **Upload file** to primary bucket
2. **Check DR bucket** in us-west-2
3. **Verify file** appears within minutes

---

## **Lab 3: RDS Multi-AZ and Read Replica**

### **Step 1: Create Primary RDS Instance**
1. **Go to RDS Console**
2. **Create database**
3. **Configure:**
   - **Engine**: MySQL
   - **Version**: 8.0.35
   - **Template**: Production
   - **DB instance identifier**: `cloudops-db-primary`
   - **Master username**: `admin`
   - **Master password**: Set secure password
   - **Instance class**: db.t3.micro
   - **Storage**: 20 GB
   - **Multi-AZ**: ☑️ Enable
   - **Backup retention**: 7 days
   - **Encryption**: Enable
4. **Create database**

### **Step 2: Create Cross-Region Read Replica**
1. **Select primary database**
2. **Actions** → **Create read replica**
3. **Configure:**
   - **DB instance identifier**: `cloudops-db-replica`
   - **Destination region**: us-west-2
   - **Instance class**: db.t3.micro
   - **Encryption**: Enable
4. **Create read replica**

### **Step 3: Monitor Replication Lag**
1. **Select replica database**
2. **Monitoring tab**
3. **Check metric**: `ReplicaLag`

---

## **Lab 4: Route 53 Health Checks and Failover**

### **Step 1: Create Health Checks**
1. **Go to Route 53 Console**
2. **Health checks** → **Create health check**
3. **Primary Health Check:**
   - **Name**: `Primary-Health-Check`
   - **Monitor**: Endpoint
   - **Protocol**: HTTP
   - **IP address**: Primary ALB IP or domain
   - **Path**: `/health`
   - **Request interval**: Fast (10 seconds)
   - **Failure threshold**: 3
4. **Create health check**
5. **Repeat for DR region**

### **Step 2: Create Hosted Zone**
1. **Hosted zones** → **Create hosted zone**
2. **Domain name**: `cloudops.example.com`
3. **Create hosted zone**

### **Step 3: Configure Failover Records**
1. **Create record**
2. **Primary Record:**
   - **Record name**: `app`
   - **Record type**: A
   - **Value**: Primary ALB IP
   - **Routing policy**: Failover
   - **Failover record type**: Primary
   - **Health check**: Select primary health check
   - **Record ID**: `Primary`
3. **Create record**

4. **Create record** for DR:
   - **Record name**: `app`
   - **Record type**: A
   - **Value**: DR ALB IP
   - **Routing policy**: Failover
   - **Failover record type**: Secondary
   - **Record ID**: `DR`
5. **Create record**

---

## **Lab 5: CloudWatch Alarms for DR**

### **Step 1: Create RTO Alarm**
1. **Go to CloudWatch Console**
2. **Alarms** → **Create alarm**
3. **Select metric:**
   - **Namespace**: Custom → CloudOps/DR
   - **Metric**: RecoveryTimeObjective
4. **Configure:**
   - **Threshold**: Greater than 15 minutes
   - **Evaluation periods**: 1
5. **Configure actions:**
   - **SNS topic**: Create new or select existing
6. **Create alarm**

### **Step 2: Create Backup Job Alarm**
1. **Create alarm**
2. **Select metric:**
   - **Namespace**: AWS/Backup
   - **Metric**: NumberOfBackupJobsFailed
3. **Configure:**
   - **Threshold**: Greater than 0
   - **Evaluation periods**: 1
4. **Create alarm**

---

## **Lab 6: DR Testing Procedure**

### **Step 1: Document Current State**
1. **Record all resource IDs**
2. **Take screenshots** of configurations
3. **Document DNS records**
4. **Note application endpoints**

### **Step 2: Simulate Primary Failure**
1. **Stop primary EC2 instances** or ASG
2. **Wait for health check failure** (3-5 minutes)
3. **Verify DNS failover** to DR region:
```bash
nslookup app.cloudops.example.com
```

### **Step 3: Promote RDS Replica**
1. **Select read replica**
2. **Actions** → **Promote**
3. **Configure:**
   - **Backup retention**: 7 days
   - **Backup window**: Set preferred time
4. **Promote read replica**

### **Step 4: Scale DR Resources**
1. **Update DR Auto Scaling Group**
2. **Set desired capacity** to production levels
3. **Verify instances** are healthy

### **Step 5: Verify Application**
1. **Test application URL**
2. **Check database connectivity**
3. **Verify S3 access**
4. **Test all critical functions**

### **Step 6: Document Results**
1. **Record actual RTO** (time to restore)
2. **Record actual RPO** (data loss)
3. **Note any issues**
4. **Update DR procedures**

---

## **Lab 7: Restore to Primary Region**

### **Step 1: Restore Primary Resources**
1. **Start primary EC2 instances**
2. **Verify health checks** pass
3. **Update DNS** back to primary

### **Step 2: Restore Database**
1. **Create new RDS instance** from backup
2. **Or restore from snapshot**
3. **Update application** connection strings

### **Step 3: Verify Replication**
1. **Check S3 replication** status
2. **Verify backup jobs** running
3. **Test health checks**

---

## **Verification Checklist**

### **Backup Verification:**
- ☑️ Backup jobs completing successfully
- ☑️ Cross-region copies created
- ☑️ Lifecycle policies working
- ☑️ Restore tests successful

### **Replication Verification:**
- ☑️ S3 replication active
- ☑️ RDS replica lag < 5 minutes
- ☑️ Data consistency verified

### **Failover Verification:**
- ☑️ Health checks functioning
- ☑️ DNS failover working
- ☑️ Application accessible
- ☑️ RTO/RPO met

---

## **Cleanup**

### **Step 1: Delete Replication**
1. **S3 Console** → Select primary bucket
2. **Management** → **Replication rules** → Delete

### **Step 2: Delete RDS Replica**
1. **RDS Console** → Select replica
2. **Actions** → **Delete**
3. **Skip final snapshot**

### **Step 3: Delete Backup Plan**
1. **AWS Backup Console**
2. **Backup plans** → Select plan → **Delete**

### **Step 4: Delete Health Checks**
1. **Route 53 Console**
2. **Health checks** → Select → **Delete**

### **Step 5: Delete Buckets**
1. **Empty buckets** first
2. **Delete buckets**
