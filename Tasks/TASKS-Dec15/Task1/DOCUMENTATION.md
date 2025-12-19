# Task 1: Highly Available Web Application with ALB and Auto Scaling

## Project Overview

Building a scalable web application that can handle traffic spikes and remain available even when servers fail.

---

## 📸 Important: Screenshot Instructions

**Screenshot Location**: All screenshots must be saved in the `screenshots/` directory at the Task1 root level.

**Directory Structure**:
```
Task1/
├── screenshots/              ← Save all screenshots HERE
│   ├── 01-project-structure.png
│   ├── 02-main-tf.png
│   └── ...
├── terraform/
├── DOCUMENTATION.md          ← You are reading this file
└── ...
```

**How to Save Screenshots**:
1. Take screenshot using your tool
2. Navigate to: `/home/einfochips/TrainingPlanNew/Tasks/TASKS-Dec15/Task1/screenshots/`
3. Save with exact name shown in this document (e.g., `01-project-structure.png`)
4. Verify the file is in the correct location

**Quick Check**:
```bash
# From Task1 directory
ls -la screenshots/
# Should show your saved screenshots
```

---

## Architecture

### Simple Diagram

```
                    Users (Internet)
                          |
                          v
              +----------------------+
              | Application Load     |
              | Balancer (ALB)       |
              +----------------------+
                     |        |
         +-----------+        +-----------+
         |                                |
         v                                v
   +------------+                  +------------+
   | EC2 Web    |                  | EC2 Web    |
   | Server     |                  | Server     |
   | (AZ-1a)    |                  | (AZ-1b)    |
   +------------+                  +------------+
         |                                |
         +---------------+----------------+
                         |
                         v
                +------------------+
                | Auto Scaling     |
                | Group            |
                | Min: 1, Max: 3   |
                +------------------+
                         |
                         v
                +------------------+
                | CloudWatch       |
                | Alarms           |
                +------------------+
```

### How It Works

1. Users access application through ALB DNS name
2. ALB checks which instances are healthy
3. ALB sends traffic to healthy instances only
4. CloudWatch monitors CPU usage
5. When CPU > 60%, Auto Scaling adds instances
6. When CPU < 20%, Auto Scaling removes instances

---

## Infrastructure Components

| Component | Purpose | Configuration |
|-----------|---------|---------------|
| VPC | Network isolation | 10.0.0.0/16 |
| Subnets | Multi-AZ deployment | 2 public subnets |
| Internet Gateway | Internet access | Attached to VPC |
| ALB | Traffic distribution | Internet-facing, HTTP:80 |
| Target Group | Health monitoring | HTTP health checks |
| Auto Scaling Group | Automatic scaling | Min:1, Max:3, Desired:2 |
| Launch Template | Instance config | Amazon Linux 2, t2.micro |
| CloudWatch Alarms | Monitoring | CPU-based triggers |
| Security Groups | Network security | ALB and EC2 rules |

---

## Deployment Steps

### Step 1: Project Setup

```bash
cd /home/einfochips/TrainingPlanNew/Tasks/TASKS-Dec15/Task1
ls -la
cd terraform
ls -la
```

**📸 Screenshot 1.1: Project Directory Structure**

![Project Files](screenshots/01-project-structure.png)

---

### Step 2: Review Terraform Code

From the terraform directory:

```bash
cat main.tf
```

**📸 Screenshot 2.1: Main Terraform Configuration**

![Main.tf Content](screenshots/02-main-tf.png)

```bash
cat variables.tf
```

**📸 Screenshot 2.2: Variables Configuration**

![Variables.tf Content](screenshots/03-variables-tf.png)

```bash
cat user_data.sh
```

**📸 Screenshot 2.3: User Data Script**

![User Data Script](screenshots/04-user-data-sh.png)

---

### Step 3: Initialize Terraform

```bash
terraform init
```

**📸 Screenshot 3.1: Terraform Initialization**

![Terraform Init](screenshots/05-terraform-init.png)

---

### Step 4: Validate Configuration

```bash
terraform validate
```

**📸 Screenshot 4.1: Configuration Validation**

![Terraform Validate](screenshots/06-terraform-validate.png)

---

### Step 5: Plan Infrastructure

```bash
terraform plan
```

**📸 Screenshot 5.1: Terraform Plan Output**

![Terraform Plan](screenshots/07-terraform-plan.png)

---

### Step 6: Apply Configuration

```bash
terraform apply
```

**📸 Screenshot 6.1: Terraform Apply Progress**

![Apply Progress](screenshots/09-terraform-apply-progress.png)

**📸 Screenshot 6.2: Apply Complete**

![Apply Complete](screenshots/10-terraform-apply-complete.png)

**📸 Screenshot 6.3: Terraform Outputs**

![Outputs](screenshots/11-terraform-outputs.png)

---

## AWS Console Verification

### Step 7: Verify VPC Resources

Navigate to: **AWS Console → VPC Dashboard**

**📸 Screenshot 7.1: VPC Created**

![VPC Dashboard](screenshots/12-vpc-dashboard.png)

**📸 Screenshot 7.2: Subnets**

![Subnets List](screenshots/13-subnets.png)

**📸 Screenshot 7.3: Internet Gateway**

![Internet Gateway](screenshots/14-internet-gateway.png)

**📸 Screenshot 7.4: Route Table**

![Route Table](screenshots/15-route-table.png)

---

### Step 8: Verify EC2 Instances

Navigate to: **AWS Console → EC2 → Instances**

**📸 Screenshot 8.1: EC2 Instances Running**

![EC2 Instances](screenshots/16-ec2-instances.png)

**📸 Screenshot 8.2: Instance 1 Details**

![Instance 1 Details](screenshots/17-instance-1-details.png)

**📸 Screenshot 8.3: Instance 2 Details**

![Instance 2 Details](screenshots/18-instance-2-details.png)

**📸 Screenshot 8.4: Instance Tags**

![Instance Tags](screenshots/19-instance-tags.png)

---

### Step 9: Verify Security Groups

Navigate to: **AWS Console → EC2 → Security Groups**

**📸 Screenshot 9.1: Security Groups List**

![Security Groups](screenshots/20-security-groups.png)

**📸 Screenshot 9.2: ALB Security Group Rules**

![ALB SG Rules](screenshots/21-alb-sg-rules.png)

**📸 Screenshot 9.3: Web Server Security Group Rules**

![Web SG Rules](screenshots/22-web-sg-rules.png)

---

### Step 10: Verify Load Balancer

Navigate to: **AWS Console → EC2 → Load Balancers**

**📸 Screenshot 10.1: Load Balancer List**

![Load Balancers](screenshots/23-load-balancers.png)

**📸 Screenshot 10.2: Load Balancer Details**

![ALB Details](screenshots/24-alb-details.png)

**📸 Screenshot 10.3: Load Balancer Listeners**

![ALB Listeners](screenshots/25-alb-listeners.png)

---

### Step 11: Verify Target Group

Navigate to: **AWS Console → EC2 → Target Groups**

**📸 Screenshot 11.2: Target Group Details**

![Target Group Details](screenshots/28-target-group-details.png)

**📸 Screenshot 11.3: Registered Targets**

One of EC2 Instance Got terminated due to low capacity or no used and desired/Min capacity count we have set for 1
![Registered Targets](screenshots/29.1-registered-targets.png)

![Registered Targets](screenshots/29-registered-targets.png)

**📸 Screenshot 11.4: Health Check Configuration**

![Health Check Settings](screenshots/30-health-check-config.png)

---

### Step 12: Verify Auto Scaling Group

Navigate to: **AWS Console → EC2 → Auto Scaling Groups**

**📸 Screenshot 12.1: ASG Details**

![ASG Details](screenshots/31-asg-details.png)

**📸 Screenshot 12.2: ASG Instance Management**

![ASG Instances](screenshots/32-asg-instances.png)

**📸 Screenshot 12.3: ASG Activity History**

![ASG Activity](screenshots/33-asg-activity.png)

**📸 Screenshot 12.4: ASG Scaling Policies**

![ASG Policies](screenshots/34-asg-policies.png)

---

### Step 13: Verify CloudWatch Alarms

Navigate to: **AWS Console → CloudWatch → Alarms**

**📸 Screenshot 13.1: CloudWatch Alarms List**

![CloudWatch Alarms](screenshots/36-cloudwatch-alarms.png)

**📸 Screenshot 13.2: High CPU Alarm Configuration**

![High CPU Alarm](screenshots/37-high-cpu-alarm.png)

**📸 Screenshot 13.3: Low CPU Alarm Configuration**

![Low CPU Alarm](screenshots/38-low-cpu-alarm.png)

---

## Application Testing

### Step 14: Access Web Application

```bash
terraform output alb_url
```

**📸 Screenshot 14.1: Load Balancing Demo**

![ALB URL Output](screenshots/39-alb-url-output.png)

---

## High Availability Testing

### Test 1: Scale to 2 Instances First

**Note**: Currently ASG has Min: 1, so only 1 instance is running. We need to scale to 2 instances before testing failover.

#### Step 15: Update ASG Desired Capacity

```bash
# Scale to 2 instances
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name ha-webapp-asg \
  --desired-capacity 2
```

**📸 Screenshot 15.1: Setting Desired Capacity**

![Set Capacity](screenshots/43-set-desired-capacity.png)

---

#### Step 16: Wait for Second Instance

Wait 2-3 minutes for the second instance to launch and become healthy.

```bash
# Check instances
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=ha-webapp-web-server" "Name=instance-state-name,Values=running" \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name,Placement.AvailabilityZone]' \
  --output table
```

**📸 Screenshot 16.1: Two Instances Running**

![Two Instances](screenshots/44-two-instances-running.png)

**📸 Screenshot 16.2: ASG Activity - Second Instance Launched**

![ASG Activity](screenshots/45-asg-second-instance.png)

---

#### Step 17: Verify Both Targets Healthy

Navigate to: **EC2 → Target Groups → Targets**

**📸 Screenshot 17.1: Two Healthy Targets**

![Two Targets](screenshots/46-two-targets-healthy.png)

---

### Test 2: Instance Failover

#### Step 18: Stop One Instance

**📸 Screenshot 18.1: Stopping Instance**

![Stop Instance](screenshots/47-stop-instance-action.png)

**📸 Screenshot 18.2: Instance Stopped**

![Instance Stopped](screenshots/48-instance-stopped.png)

---

#### Step 19: Application Still Works

**📸 Screenshot 19.1: App Still Accessible**

![App Still Working](screenshots/49-app-still-working.png)

---

#### Step 20: Target Group Health

**📸 Screenshot 20.1: One Target Unhealthy**

![Target Unhealthy](screenshots/50-target-unhealthy.png)

---

#### Step 21: ASG Launches Replacement

**📸 Screenshot 21.1: ASG Launching Instance**

![ASG Launching](screenshots/51-asg-launching-instance.png)

**📸 Screenshot 21.2: New Instance Running**

![New Instance](screenshots/51-asg-launching-instance.png)

**📸 Screenshot 21.3: Targets Healthy Again**

![Targets Healthy](screenshots/53-targets-healthy-again.png)

---

## Auto Scaling Testing

### Test 3: Scale Out (CPU > 60%)

#### Step 22: Connect to Instance via SSH

Get instance public IP and connect via SSH:

```bash
# Get instance public IP
INSTANCE_IP=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=ha-webapp-web-server" "Name=instance-state-name,Values=running" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

echo "Connecting to: $INSTANCE_IP"

# SSH to instance
ssh -i "jayimrankey.pem" ec2-user@ec2-3-91-26-128.compute-1.amazonaws.com
ssh -i /home/einfochips/backup/Keys/jayimrankey.pem ec2-user@$INSTANCE_IP
```

**📸 Screenshot 22.1: SSH Connected to Instance**

![SSH Connected](screenshots/54-ssh-connected.png)

---

#### Step 23: Install Stress Tool

```bash
sudo amazon-linux-extras install epel -y
sudo yum install stress -y
```

**📸 Screenshot 23.1: Installing Stress**

![Install Stress](screenshots/55-install-stress.png)

---

#### Step 24: Generate CPU Load

```bash
stress --cpu 2 --timeout 600
```

**📸 Screenshot 24.1: Stress Running**

![Stress Running](screenshots/56-stress-running.png)

---

#### Step 25: Monitor CPU

**📸 Screenshot 25.1: CPU Rising Above 60%**

![CPU Rising](screenshots/57-cpu-rising.png)

---

#### Step 26: High CPU Alarm Triggers

**📸 Screenshot 26.1: Alarm Triggered**

![High CPU Alarm](screenshots/58-high-cpu-alarm-triggered.png)

**📸 Screenshot 26.2: Alarm History**

![Alarm History](screenshots/59-alarm-history.png)

---

#### Step 27: ASG Scales Out

**📸 Screenshot 27.1: Scaling Out Activity**

![ASG Scaling Out](screenshots/60-asg-scaling-out.png)

**📸 Screenshot 27.2: Capacity Increased to 2**

![ASG Capacity 3](screenshots/61-asg-capacity-3.png)

---

#### Step 28: Second Instance Launched

**📸 Screenshot 28.1: Two Instances Running**

![Three Instances](screenshots/62-two-instances-running.png)

---

#### Step 29: Target Group Updated

**📸 Screenshot 29.1: Two Healthy Targets**

![Three Targets](screenshots/63-two-targets-healthy.png)

---

#### Step 30: Second Instance Serving

**📸 Screenshot 30.1: Second Instance in App**

![Third Instance](screenshots/64-second-instance-serving.png)

---

### Test 4: Scale In (CPU < 20%)

#### Step 31: Stop Stress Test

**📸 Screenshot 31.1: Stress Stopped**

![Stress Stopped](screenshots/65-stress-stopped.png)

---

#### Step 32: CPU Dropping

**📸 Screenshot 32.1: CPU Below 20%**

![CPU Dropping](screenshots/66-cpu-dropping.png)

---

#### Step 33: Low CPU Alarm Triggers

**📸 Screenshot 33.1: Low CPU Alarm**

![Low CPU Alarm](screenshots/67-low-cpu-alarm-triggered.png)

---

#### Step 34: ASG Scales In

**📸 Screenshot 34.1: Scaling In Activity**

![ASG Scaling In](screenshots/68-asg-scaling-in.png)

**📸 Screenshot 34.2: Capacity Decreased to 1**

![ASG Capacity 2](screenshots/69-asg-capacity-2.png)

---

#### Step 35: Instance Terminated

**📸 Screenshot 35.1: Instance Terminating**

![Instance Terminating](screenshots/70-instance-terminating.png)

**📸 Screenshot 35.2: One Instances Again**

![Two Instances](screenshots/71-one-instances-final.png)

---

#### Step 36: Target Group Updated

**📸 Screenshot 36.1: One Targets Again**

![Two Targets](screenshots/72-one-targets-final.png)

---

## Monitoring

### Step 37: CloudWatch Metrics

**📸 Screenshot 37.1: ALB Metrics**

![ALB Metrics](screenshots/73-alb-metrics.png)

**📸 Screenshot 37.2: ASG Metrics**

![ASG Metrics](screenshots/74-asg-metrics.png)

**📸 Screenshot 37.3: CPU Metrics Timeline**

![CPU Timeline](screenshots/75-ec2-cpu-metrics.png)

---


## Configuration Summary

### Auto Scaling
- Min: 1, Max: 3, Desired: 2
- Health Check: ELB, Grace Period: 300s

### Scaling Policies
- Scale Out: CPU > 60%, Add 1 instance
- Scale In: CPU < 20%, Remove 1 instance
- Cooldown: 300 seconds

### Health Checks
- Protocol: HTTP, Port: 80, Path: /
- Interval: 30s, Timeout: 5s
- Thresholds: 2/2

---
