# 🖥️ VPC - Manual Console Steps

## **Lab 1: Create VPC and Subnets**

### **Step 1: Create VPC**
1. **Go to VPC Console** → **Your VPCs**
2. **Click "Create VPC"**
3. **Configure:**
   - **Name**: `CloudOps-VPC`
   - **IPv4 CIDR**: `10.0.0.0/16`
   - **IPv6 CIDR**: No IPv6 CIDR block
   - **Tenancy**: Default
4. **Click "Create VPC"**

### **Step 2: Enable DNS Settings**
1. **Select CloudOps-VPC**
2. **Actions** → **Edit VPC settings**
3. **Enable:**
   - ☑️ Enable DNS resolution
   - ☑️ Enable DNS hostnames
4. **Save changes**

### **Step 3: Create Public Subnets**
1. **Go to Subnets** → **Create subnet**
2. **VPC**: Select `CloudOps-VPC`
3. **Subnet 1:**
   - **Name**: `Public-Subnet-1`
   - **AZ**: us-east-1a
   - **IPv4 CIDR**: `10.0.1.0/24`
4. **Add new subnet** → **Subnet 2:**
   - **Name**: `Public-Subnet-2`
   - **AZ**: us-east-1b
   - **IPv4 CIDR**: `10.0.2.0/24`
5. **Create subnet**

### **Step 4: Enable Auto-assign Public IP**
1. **Select Public-Subnet-1**
2. **Actions** → **Edit subnet settings**
3. **☑️ Enable auto-assign public IPv4 address**
4. **Save**
5. **Repeat for Public-Subnet-2**

### **Step 5: Create Private Subnets**
1. **Create subnet**
2. **VPC**: Select `CloudOps-VPC`
3. **Subnet 1:**
   - **Name**: `Private-Subnet-1`
   - **AZ**: us-east-1a
   - **IPv4 CIDR**: `10.0.10.0/24`
4. **Add new subnet** → **Subnet 2:**
   - **Name**: `Private-Subnet-2`
   - **AZ**: us-east-1b
   - **IPv4 CIDR**: `10.0.11.0/24`
5. **Create subnet**

### **Step 6: Create Database Subnets**
1. **Create subnet**
2. **VPC**: Select `CloudOps-VPC`
3. **Subnet 1:**
   - **Name**: `Database-Subnet-1`
   - **AZ**: us-east-1a
   - **IPv4 CIDR**: `10.0.20.0/24`
4. **Add new subnet** → **Subnet 2:**
   - **Name**: `Database-Subnet-2`
   - **AZ**: us-east-1b
   - **IPv4 CIDR**: `10.0.21.0/24`
5. **Create subnet**

---

## **Lab 2: Internet Gateway and NAT Gateway**

### **Step 1: Create Internet Gateway**
1. **Go to Internet Gateways**
2. **Click "Create internet gateway"**
3. **Name**: `CloudOps-IGW`
4. **Create internet gateway**

### **Step 2: Attach Internet Gateway**
1. **Select CloudOps-IGW**
2. **Actions** → **Attach to VPC**
3. **VPC**: Select `CloudOps-VPC`
4. **Attach internet gateway**

### **Step 3: Allocate Elastic IPs**
1. **Go to Elastic IPs**
2. **Allocate Elastic IP address**
3. **Tags**: Name = `NAT-EIP-1`
4. **Allocate**
5. **Repeat for NAT-EIP-2**

### **Step 4: Create NAT Gateways**
1. **Go to NAT Gateways**
2. **Create NAT gateway**
3. **NAT Gateway 1:**
   - **Name**: `CloudOps-NAT-1`
   - **Subnet**: `Public-Subnet-1`
   - **Elastic IP**: Select `NAT-EIP-1`
4. **Create NAT gateway**
5. **Repeat for NAT Gateway 2:**
   - **Name**: `CloudOps-NAT-2`
   - **Subnet**: `Public-Subnet-2`
   - **Elastic IP**: Select `NAT-EIP-2`

---

## **Lab 3: Configure Route Tables**

### **Step 1: Create Public Route Table**
1. **Go to Route Tables**
2. **Create route table**
3. **Name**: `Public-Route-Table`
4. **VPC**: `CloudOps-VPC`
5. **Create route table**

### **Step 2: Add Internet Gateway Route**
1. **Select Public-Route-Table**
2. **Routes tab** → **Edit routes**
3. **Add route:**
   - **Destination**: `0.0.0.0/0`
   - **Target**: Internet Gateway → `CloudOps-IGW`
4. **Save changes**

### **Step 3: Associate Public Subnets**
1. **Subnet associations tab** → **Edit subnet associations**
2. **Select:**
   - ☑️ Public-Subnet-1
   - ☑️ Public-Subnet-2
3. **Save associations**

### **Step 4: Create Private Route Tables**
1. **Create route table**
2. **Name**: `Private-Route-Table-1`
3. **VPC**: `CloudOps-VPC`
4. **Create route table**

### **Step 5: Add NAT Gateway Route**
1. **Select Private-Route-Table-1**
2. **Routes tab** → **Edit routes**
3. **Add route:**
   - **Destination**: `0.0.0.0/0`
   - **Target**: NAT Gateway → `CloudOps-NAT-1`
4. **Save changes**

### **Step 6: Associate Private Subnet**
1. **Subnet associations tab** → **Edit subnet associations**
2. **Select:** ☑️ Private-Subnet-1
3. **Save associations**

### **Step 7: Repeat for Private-Route-Table-2**
1. **Create Private-Route-Table-2**
2. **Add route to CloudOps-NAT-2**
3. **Associate with Private-Subnet-2**

---

## **Lab 4: Security Groups**

### **Step 1: Create Web Security Group**
1. **Go to Security Groups**
2. **Create security group**
3. **Configure:**
   - **Name**: `Web-SG`
   - **Description**: `Security group for web servers`
   - **VPC**: `CloudOps-VPC`

### **Step 2: Add Inbound Rules**
1. **Inbound rules** → **Add rule**
2. **Rule 1:**
   - **Type**: HTTP
   - **Source**: 0.0.0.0/0
3. **Add rule** → **Rule 2:**
   - **Type**: HTTPS
   - **Source**: 0.0.0.0/0
4. **Add rule** → **Rule 3:**
   - **Type**: SSH
   - **Source**: My IP
5. **Create security group**

### **Step 3: Create Database Security Group**
1. **Create security group**
2. **Configure:**
   - **Name**: `Database-SG`
   - **Description**: `Security group for database`
   - **VPC**: `CloudOps-VPC`
3. **Inbound rules** → **Add rule:**
   - **Type**: MySQL/Aurora
   - **Source**: Custom → Select `Web-SG`
4. **Create security group**

---

## **Lab 5: VPC Endpoints**

### **Step 1: Create S3 Gateway Endpoint**
1. **Go to Endpoints**
2. **Create endpoint**
3. **Configure:**
   - **Name**: `S3-Gateway-Endpoint`
   - **Service category**: AWS services
   - **Service**: com.amazonaws.us-east-1.s3 (Gateway)
   - **VPC**: `CloudOps-VPC`
   - **Route tables**: Select all route tables
4. **Create endpoint**

### **Step 2: Create Interface Endpoint (Optional)**
1. **Create endpoint**
2. **Configure:**
   - **Name**: `EC2-Interface-Endpoint`
   - **Service**: com.amazonaws.us-east-1.ec2
   - **VPC**: `CloudOps-VPC`
   - **Subnets**: Select private subnets
   - **Security groups**: Create or select SG allowing HTTPS
   - **☑️ Enable DNS name**
3. **Create endpoint**

---

## **Lab 6: VPC Flow Logs**

### **Step 1: Create CloudWatch Log Group**
1. **Go to CloudWatch Console**
2. **Logs** → **Log groups**
3. **Create log group**
4. **Name**: `/aws/vpc/flowlogs`
5. **Create**

### **Step 2: Create IAM Role**
1. **Go to IAM Console**
2. **Roles** → **Create role**
3. **Trusted entity**: AWS service → VPC Flow Logs
4. **Permissions**: Create inline policy:
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ],
    "Resource": "*"
  }]
}
```
5. **Role name**: `VPCFlowLogsRole`
6. **Create role**

### **Step 3: Enable Flow Logs**
1. **Go to VPC Console**
2. **Select CloudOps-VPC**
3. **Flow logs tab** → **Create flow log**
4. **Configure:**
   - **Name**: `VPC-Flow-Logs`
   - **Filter**: All
   - **Destination**: CloudWatch Logs
   - **Log group**: `/aws/vpc/flowlogs`
   - **IAM role**: `VPCFlowLogsRole`
5. **Create flow log**

---

## **Lab 7: Test Connectivity**

### **Step 1: Launch Test Instance in Public Subnet**
1. **Go to EC2 Console**
2. **Launch instance**
3. **Configure:**
   - **Name**: `Public-Test-Instance`
   - **AMI**: Amazon Linux 2
   - **Instance type**: t2.micro
   - **Network**: `CloudOps-VPC`
   - **Subnet**: `Public-Subnet-1`
   - **Auto-assign public IP**: Enable
   - **Security group**: `Web-SG`
4. **Launch**

### **Step 2: Launch Test Instance in Private Subnet**
1. **Launch instance**
2. **Configure:**
   - **Name**: `Private-Test-Instance`
   - **Network**: `CloudOps-VPC`
   - **Subnet**: `Private-Subnet-1`
   - **Auto-assign public IP**: Disable
   - **Security group**: Create new allowing SSH from Web-SG
3. **Launch**

### **Step 3: Test Internet Access**
1. **SSH to Public-Test-Instance**
2. **Test internet:**
```bash
ping -c 4 google.com
curl https://checkip.amazonaws.com
```
3. **SSH to Private-Test-Instance** (via public instance)
4. **Test internet via NAT:**
```bash
ping -c 4 google.com
curl https://checkip.amazonaws.com
```

---

## **Verification**

### **Check VPC:**
```bash
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=CloudOps-VPC"
```

### **Check Subnets:**
```bash
aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-xxxxx"
```

### **Check Route Tables:**
```bash
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=vpc-xxxxx"
```

### **View Flow Logs:**
1. **CloudWatch Console** → **Log groups**
2. **Select /aws/vpc/flowlogs**
3. **View log streams**

---

## **Cleanup**

1. **Terminate EC2 instances**
2. **Delete NAT Gateways**
3. **Release Elastic IPs**
4. **Delete VPC endpoints**
5. **Detach and delete Internet Gateway**
6. **Delete subnets**
7. **Delete route tables**
8. **Delete security groups**
9. **Delete VPC**
