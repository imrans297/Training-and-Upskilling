# Section 2: Getting Started with AWS

## 📋 Overview
This section covers the fundamentals of Amazon Web Services (AWS), including account setup, basic navigation, and understanding the AWS global infrastructure.

## 🎯 What is Amazon Web Services (AWS)?
AWS is a comprehensive cloud computing platform that provides:
- **Infrastructure as a Service (IaaS)**: Virtual servers, storage, networking
- **Platform as a Service (PaaS)**: Development platforms, databases
- **Software as a Service (SaaS)**: Ready-to-use applications
- **200+ Services**: Compute, storage, databases, analytics, machine learning, and more

## 🌍 AWS Global Infrastructure

### Regions
- **Definition**: Geographic areas with multiple data centers
- **Current Count**: 33+ regions worldwide
- **Selection Criteria**:
  - Compliance and data governance
  - Proximity to customers (latency)
  - Available services
  - Pricing

### Availability Zones (AZs)
- **Definition**: Isolated data centers within a region
- **Count**: 2-6 AZs per region (usually 3)
- **Purpose**: High availability and fault tolerance
- **Connectivity**: High-speed, low-latency links

### Edge Locations
- **Definition**: Content delivery endpoints
- **Count**: 400+ edge locations globally
- **Purpose**: Content caching and delivery (CloudFront)
- **Services**: CloudFront, Route 53, AWS Global Accelerator

## 🏗️ AWS Services Categories

### 1. Compute Services
- **EC2**: Virtual servers in the cloud
- **Lambda**: Serverless compute
- **ECS/EKS**: Container services
- **Elastic Beanstalk**: Platform as a Service

### 2. Storage Services
- **S3**: Object storage
- **EBS**: Block storage for EC2
- **EFS**: File storage
- **Glacier**: Archive storage

### 3. Database Services
- **RDS**: Relational databases
- **DynamoDB**: NoSQL database
- **ElastiCache**: In-memory caching
- **Redshift**: Data warehouse

### 4. Networking Services
- **VPC**: Virtual Private Cloud
- **CloudFront**: Content Delivery Network
- **Route 53**: DNS service
- **Direct Connect**: Dedicated network connection

### 5. Security Services
- **IAM**: Identity and Access Management
- **KMS**: Key Management Service
- **CloudTrail**: API logging
- **GuardDuty**: Threat detection

## 💰 AWS Pricing Models

### 1. Pay-as-you-go
- No upfront costs
- Pay only for what you use
- Scale up or down based on demand

### 2. Save when you reserve
- Reserved Instances (1-3 years)
- Significant discounts (up to 75%)
- Predictable workloads

### 3. Pay less by using more
- Volume-based discounts
- Tiered pricing for many services
- Data transfer discounts

### 4. Pay less as AWS grows
- AWS passes savings to customers
- Regular price reductions
- New lower-cost services

## 🆓 AWS Free Tier

### Always Free
- **Lambda**: 1M requests per month
- **DynamoDB**: 25GB storage
- **CloudFront**: 1TB data transfer out

### 12 Months Free
- **EC2**: 750 hours per month (t2.micro)
- **S3**: 5GB standard storage
- **RDS**: 750 hours per month (db.t2.micro)

### Trials
- **Redshift**: 2 months free
- **ElastiCache**: 750 hours
- **CloudWatch**: 10 custom metrics

## 🛠️ Hands-On Practice

### Practice 1: Create AWS Account
**Objective**: Set up your AWS Free Tier account

**Steps**:
1. Go to [aws.amazon.com](https://aws.amazon.com)
2. Click "Create an AWS Account"
3. Enter email address and account name
4. Choose "Personal" account type
5. Fill in contact information
6. Add payment method (required but won't be charged for free tier)
7. Verify phone number
8. Choose Basic Support Plan (free)
9. Complete account setup

**Screenshot Placeholder**:
![AWS Account Creation](screenshots/02-aws-account-creation.png)
*Caption: AWS account creation process*

### Practice 2: AWS Management Console Navigation
**Objective**: Familiarize yourself with the AWS Console

**Steps**:
1. Sign in to AWS Management Console
2. Explore the main dashboard
3. Use the search bar to find services
4. Pin frequently used services
5. Check your billing dashboard
6. Set up billing alerts

**Screenshot Placeholder**:
![AWS Console Dashboard](screenshots/02-aws-console-dashboard.png)
*Caption: AWS Management Console main dashboard*

### Practice 3: Explore AWS Global Infrastructure
**Objective**: Understand regions and availability zones

**Steps**:
1. In the console, check current region (top-right)
2. Click on region dropdown
3. Explore available regions
4. Note the services available in different regions
5. Switch to a different region
6. Observe how the console changes

**Screenshot Placeholder**:
![AWS Regions](screenshots/02-aws-regions.png)
*Caption: AWS regions selection dropdown*

### Practice 4: Set Up Billing Alerts
**Objective**: Monitor your AWS spending

**Steps**:
1. Go to Billing & Cost Management
2. Navigate to "Billing preferences"
3. Enable "Receive Billing Alerts"
4. Go to CloudWatch
5. Create a billing alarm
6. Set threshold (e.g., $10)
7. Configure SNS notification

**Screenshot Placeholder**:
![Billing Alert Setup](screenshots/02-billing-alert-setup.png)
*Caption: Setting up billing alerts in AWS*

### Practice 5: AWS Free Tier Usage Monitoring
**Objective**: Track your free tier usage

**Steps**:
1. Go to Billing & Cost Management
2. Click on "Free Tier"
3. Review current usage
4. Understand usage limits
5. Set up free tier alerts
6. Monitor regularly

**Screenshot Placeholder**:
![Free Tier Usage](screenshots/02-free-tier-usage.png)
*Caption: AWS Free Tier usage dashboard*

## 🔧 AWS Tools and Interfaces

### 1. AWS Management Console
- **Web-based interface**
- Point-and-click management
- Visual dashboards and monitoring
- Mobile app available

### 2. AWS Command Line Interface (CLI)
- **Command-line tool**
- Automate AWS services
- Scripting and automation
- Cross-platform support

### 3. AWS Software Development Kits (SDKs)
- **Programming language support**
- Java, Python, .NET, Node.js, etc.
- Application integration
- API access

### 4. AWS CloudFormation
- **Infrastructure as Code**
- Template-based provisioning
- Version control for infrastructure
- Repeatable deployments

## 📊 AWS Well-Architected Framework

### 6 Pillars
1. **Operational Excellence**: Run and monitor systems
2. **Security**: Protect information and systems
3. **Reliability**: Recover from failures
4. **Performance Efficiency**: Use resources efficiently
5. **Cost Optimization**: Avoid unnecessary costs
6. **Sustainability**: Minimize environmental impact

## 🔒 AWS Shared Responsibility Model

### AWS Responsibility (Security OF the Cloud)
- Physical security of data centers
- Hardware and software infrastructure
- Network infrastructure
- Virtualization infrastructure

### Customer Responsibility (Security IN the Cloud)
- Operating system updates and security patches
- Network and firewall configuration
- Application-level security
- Identity and access management
- Data encryption

## 📚 Key AWS Concepts

### 1. Elasticity
- **Auto-scaling**: Automatically adjust resources
- **On-demand**: Scale up or down as needed
- **Cost-effective**: Pay only for what you use

### 2. High Availability
- **Multiple AZs**: Deploy across availability zones
- **Fault tolerance**: Continue operating during failures
- **Disaster recovery**: Quick recovery from disasters

### 3. Security
- **Defense in depth**: Multiple layers of security
- **Encryption**: Data at rest and in transit
- **Compliance**: Meet regulatory requirements

## 🎯 Best Practices for Getting Started

### 1. Security First
- Enable MFA on root account
- Create IAM users (don't use root)
- Follow principle of least privilege
- Enable CloudTrail logging

### 2. Cost Management
- Set up billing alerts
- Use AWS Cost Explorer
- Implement tagging strategy
- Regular cost reviews

### 3. Architecture
- Design for failure
- Use multiple AZs
- Implement monitoring
- Plan for scalability

## 📝 Common Beginner Mistakes to Avoid

1. **Using root account for daily tasks**
2. **Not setting up billing alerts**
3. **Ignoring security best practices**
4. **Not understanding the shared responsibility model**
5. **Deploying in single AZ**
6. **Not implementing proper monitoring**
7. **Forgetting to clean up resources**

## 🔗 Additional Resources

- [AWS Getting Started Guide](https://aws.amazon.com/getting-started/)
- [AWS Architecture Center](https://aws.amazon.com/architecture/)
- [AWS Well-Architected Tool](https://aws.amazon.com/well-architected-tool/)
- [AWS Training and Certification](https://aws.amazon.com/training/)
- [AWS Documentation](https://docs.aws.amazon.com/)

## 📸 Screenshots Section
*Document your progress with these key screenshots:*

### Screenshot 1: AWS Account Dashboard
![Account Dashboard](screenshots/02-account-dashboard.png)
*Caption: AWS account dashboard after successful setup*

### Screenshot 2: Service Categories
![Service Categories](screenshots/02-service-categories.png)
*Caption: AWS services organized by categories*

### Screenshot 3: Region Selection
![Region Selection](screenshots/02-region-selection.png)
*Caption: Available AWS regions and their services*

### Screenshot 4: Billing Dashboard
![Billing Dashboard](screenshots/02-billing-dashboard.png)
*Caption: AWS billing and cost management dashboard*

### Screenshot 5: Free Tier Monitoring
![Free Tier Monitoring](screenshots/02-free-tier-monitoring.png)
*Caption: Free tier usage tracking and alerts*

---

## ✅ Section Completion Checklist
- [ ] Created AWS Free Tier account
- [ ] Explored AWS Management Console
- [ ] Understood AWS global infrastructure
- [ ] Set up billing alerts and monitoring
- [ ] Configured account security (MFA)
- [ ] Reviewed AWS service categories
- [ ] Understood shared responsibility model
- [ ] Explored different AWS regions

## 🎯 Next Steps
Move to **Section 3: IAM and AWS CLI** to learn about identity management and command-line tools.

---

*Last Updated: January 2025*
*Course Version: 2025.1*