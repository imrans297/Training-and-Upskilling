# Section 23: Networking - VPC

## 📋 Overview
This section covers advanced AWS networking concepts focusing on Virtual Private Cloud (VPC) design, implementation, and optimization for complex architectures.

## 🌐 VPC Fundamentals

### What is VPC?
- **Virtual Private Cloud**: Isolated network environment in AWS
- **CIDR blocks**: Define IP address ranges for your network
- **Subnets**: Divide VPC into smaller network segments
- **Route tables**: Control traffic routing within VPC
- **Internet Gateway**: Provide internet access to VPC resources

### VPC Components
- **Subnets**: Public, private, and isolated subnets
- **Route Tables**: Control packet routing
- **Internet Gateway**: Internet connectivity
- **NAT Gateway/Instance**: Outbound internet for private subnets
- **VPC Endpoints**: Private connectivity to AWS services
- **Security Groups**: Instance-level firewalls
- **NACLs**: Subnet-level firewalls

## 🔗 Advanced Networking

### VPC Peering
- **Cross-VPC communication**: Connect VPCs within or across regions
- **Transitive routing**: Not supported, requires full mesh
- **DNS resolution**: Enable cross-VPC DNS resolution
- **Security groups**: Reference security groups across peered VPCs

### Transit Gateway
- **Hub-and-spoke**: Centralized connectivity for multiple VPCs
- **Cross-region peering**: Connect Transit Gateways across regions
- **Route tables**: Advanced routing control
- **Multicast**: Support for multicast traffic
- **VPN connectivity**: Connect on-premises networks

### Direct Connect
- **Dedicated connection**: Private connection to AWS
- **Virtual interfaces**: Layer 3 connectivity options
- **BGP routing**: Dynamic routing protocol support
- **Bandwidth options**: 1Gbps to 100Gbps connections

## 🛠️ Hands-On Practice

### Practice 1: Multi-Tier VPC Architecture
**Objective**: Design and implement a production-ready multi-tier VPC

**Steps**:
1. **Create VPC with Multiple Subnets**:
   ```bash
   # Create VPC
   VPC_ID=$(aws ec2 create-vpc \
     --cidr-block 10.0.0.0/16 \
     --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=Production-VPC}]' \
     --query 'Vpc.VpcId' --output text)
   
   echo "Created VPC: $VPC_ID"
   
   # Enable DNS hostnames and resolution
   aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames
   aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-support
   
   # Get availability zones
   AZ1=$(aws ec2 describe-availability-zones --query 'AvailabilityZones[0].ZoneName' --output text)
   AZ2=$(aws ec2 describe-availability-zones --query 'AvailabilityZones[1].ZoneName' --output text)
   AZ3=$(aws ec2 describe-availability-zones --query 'AvailabilityZones[2].ZoneName' --output text)
   
   # Create public subnets
   PUBLIC_SUBNET_1=$(aws ec2 create-subnet \
     --vpc-id $VPC_ID \
     --cidr-block 10.0.1.0/24 \
     --availability-zone $AZ1 \
     --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Public-Subnet-1},{Key=Type,Value=Public}]' \
     --query 'Subnet.SubnetId' --output text)
   
   PUBLIC_SUBNET_2=$(aws ec2 create-subnet \
     --vpc-id $VPC_ID \
     --cidr-block 10.0.2.0/24 \
     --availability-zone $AZ2 \
     --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Public-Subnet-2},{Key=Type,Value=Public}]' \
     --query 'Subnet.SubnetId' --output text)
   
   # Create private subnets for application tier
   PRIVATE_SUBNET_1=$(aws ec2 create-subnet \
     --vpc-id $VPC_ID \
     --cidr-block 10.0.11.0/24 \
     --availability-zone $AZ1 \
     --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Private-App-Subnet-1},{Key=Type,Value=Private}]' \
     --query 'Subnet.SubnetId' --output text)
   
   PRIVATE_SUBNET_2=$(aws ec2 create-subnet \
     --vpc-id $VPC_ID \
     --cidr-block 10.0.12.0/24 \
     --availability-zone $AZ2 \
     --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Private-App-Subnet-2},{Key=Type,Value=Private}]' \
     --query 'Subnet.SubnetId' --output text)
   
   # Create database subnets
   DB_SUBNET_1=$(aws ec2 create-subnet \
     --vpc-id $VPC_ID \
     --cidr-block 10.0.21.0/24 \
     --availability-zone $AZ1 \
     --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Database-Subnet-1},{Key=Type,Value=Database}]' \
     --query 'Subnet.SubnetId' --output text)
   
   DB_SUBNET_2=$(aws ec2 create-subnet \
     --vpc-id $VPC_ID \
     --cidr-block 10.0.22.0/24 \
     --availability-zone $AZ2 \
     --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Database-Subnet-2},{Key=Type,Value=Database}]' \
     --query 'Subnet.SubnetId' --output text)
   
   echo "Created subnets:"
   echo "Public: $PUBLIC_SUBNET_1, $PUBLIC_SUBNET_2"
   echo "Private: $PRIVATE_SUBNET_1, $PRIVATE_SUBNET_2"
   echo "Database: $DB_SUBNET_1, $DB_SUBNET_2"
   ```

2. **Configure Internet Gateway and NAT Gateways**:
   ```bash
   # Create and attach Internet Gateway
   IGW_ID=$(aws ec2 create-internet-gateway \
     --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=Production-IGW}]' \
     --query 'InternetGateway.InternetGatewayId' --output text)
   
   aws ec2 attach-internet-gateway \
     --internet-gateway-id $IGW_ID \
     --vpc-id $VPC_ID
   
   echo "Created and attached Internet Gateway: $IGW_ID"
   
   # Allocate Elastic IPs for NAT Gateways
   EIP_1=$(aws ec2 allocate-address \
     --domain vpc \
     --tag-specifications 'ResourceType=elastic-ip,Tags=[{Key=Name,Value=NAT-Gateway-1-EIP}]' \
     --query 'AllocationId' --output text)
   
   EIP_2=$(aws ec2 allocate-address \
     --domain vpc \
     --tag-specifications 'ResourceType=elastic-ip,Tags=[{Key=Name,Value=NAT-Gateway-2-EIP}]' \
     --query 'AllocationId' --output text)
   
   # Create NAT Gateways in public subnets
   NAT_GW_1=$(aws ec2 create-nat-gateway \
     --subnet-id $PUBLIC_SUBNET_1 \
     --allocation-id $EIP_1 \
     --tag-specifications 'ResourceType=nat-gateway,Tags=[{Key=Name,Value=NAT-Gateway-1}]' \
     --query 'NatGateway.NatGatewayId' --output text)
   
   NAT_GW_2=$(aws ec2 create-nat-gateway \
     --subnet-id $PUBLIC_SUBNET_2 \
     --allocation-id $EIP_2 \
     --tag-specifications 'ResourceType=nat-gateway,Tags=[{Key=Name,Value=NAT-Gateway-2}]' \
     --query 'NatGateway.NatGatewayId' --output text)
   
   echo "Created NAT Gateways: $NAT_GW_1, $NAT_GW_2"
   
   # Wait for NAT Gateways to be available
   aws ec2 wait nat-gateway-available --nat-gateway-ids $NAT_GW_1 $NAT_GW_2
   ```

3. **Configure Route Tables**:
   ```bash
   # Create route table for public subnets
   PUBLIC_RT=$(aws ec2 create-route-table \
     --vpc-id $VPC_ID \
     --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=Public-Route-Table}]' \
     --query 'RouteTable.RouteTableId' --output text)
   
   # Add route to Internet Gateway
   aws ec2 create-route \
     --route-table-id $PUBLIC_RT \
     --destination-cidr-block 0.0.0.0/0 \
     --gateway-id $IGW_ID
   
   # Associate public subnets with public route table
   aws ec2 associate-route-table --subnet-id $PUBLIC_SUBNET_1 --route-table-id $PUBLIC_RT
   aws ec2 associate-route-table --subnet-id $PUBLIC_SUBNET_2 --route-table-id $PUBLIC_RT
   
   # Create route tables for private subnets
   PRIVATE_RT_1=$(aws ec2 create-route-table \
     --vpc-id $VPC_ID \
     --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=Private-Route-Table-1}]' \
     --query 'RouteTable.RouteTableId' --output text)
   
   PRIVATE_RT_2=$(aws ec2 create-route-table \
     --vpc-id $VPC_ID \
     --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=Private-Route-Table-2}]' \
     --query 'RouteTable.RouteTableId' --output text)
   
   # Add routes to NAT Gateways
   aws ec2 create-route \
     --route-table-id $PRIVATE_RT_1 \
     --destination-cidr-block 0.0.0.0/0 \
     --nat-gateway-id $NAT_GW_1
   
   aws ec2 create-route \
     --route-table-id $PRIVATE_RT_2 \
     --destination-cidr-block 0.0.0.0/0 \
     --nat-gateway-id $NAT_GW_2
   
   # Associate private subnets with their route tables
   aws ec2 associate-route-table --subnet-id $PRIVATE_SUBNET_1 --route-table-id $PRIVATE_RT_1
   aws ec2 associate-route-table --subnet-id $PRIVATE_SUBNET_2 --route-table-id $PRIVATE_RT_2
   
   # Create route table for database subnets (no internet access)
   DB_RT=$(aws ec2 create-route-table \
     --vpc-id $VPC_ID \
     --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=Database-Route-Table}]' \
     --query 'RouteTable.RouteTableId' --output text)
   
   # Associate database subnets with database route table
   aws ec2 associate-route-table --subnet-id $DB_SUBNET_1 --route-table-id $DB_RT
   aws ec2 associate-route-table --subnet-id $DB_SUBNET_2 --route-table-id $DB_RT
   
   echo "Configured route tables"
   ```

**Screenshot Placeholder**:
![Multi-Tier VPC Architecture](screenshots/23-multi-tier-vpc.png)
*Caption: Multi-tier VPC with public, private, and database subnets*

### Practice 2: Security Groups and NACLs
**Objective**: Implement comprehensive network security with Security Groups and NACLs

**Steps**:
1. **Create Security Groups**:
   ```bash
   # Web tier security group
   WEB_SG=$(aws ec2 create-security-group \
     --group-name web-tier-sg \
     --description "Security group for web tier" \
     --vpc-id $VPC_ID \
     --tag-specifications 'ResourceType=security-group,Tags=[{Key=Name,Value=Web-Tier-SG}]' \
     --query 'GroupId' --output text)
   
   # Allow HTTP and HTTPS from internet
   aws ec2 authorize-security-group-ingress \
     --group-id $WEB_SG \
     --protocol tcp \
     --port 80 \
     --cidr 0.0.0.0/0
   
   aws ec2 authorize-security-group-ingress \
     --group-id $WEB_SG \
     --protocol tcp \
     --port 443 \
     --cidr 0.0.0.0/0
   
   # Allow SSH from bastion host (will create later)
   aws ec2 authorize-security-group-ingress \
     --group-id $WEB_SG \
     --protocol tcp \
     --port 22 \
     --source-group $WEB_SG
   
   # Application tier security group
   APP_SG=$(aws ec2 create-security-group \
     --group-name app-tier-sg \
     --description "Security group for application tier" \
     --vpc-id $VPC_ID \
     --tag-specifications 'ResourceType=security-group,Tags=[{Key=Name,Value=App-Tier-SG}]' \
     --query 'GroupId' --output text)
   
   # Allow traffic from web tier
   aws ec2 authorize-security-group-ingress \
     --group-id $APP_SG \
     --protocol tcp \
     --port 8080 \
     --source-group $WEB_SG
   
   # Database tier security group
   DB_SG=$(aws ec2 create-security-group \
     --group-name db-tier-sg \
     --description "Security group for database tier" \
     --vpc-id $VPC_ID \
     --tag-specifications 'ResourceType=security-group,Tags=[{Key=Name,Value=DB-Tier-SG}]' \
     --query 'GroupId' --output text)
   
   # Allow MySQL/Aurora from application tier
   aws ec2 authorize-security-group-ingress \
     --group-id $DB_SG \
     --protocol tcp \
     --port 3306 \
     --source-group $APP_SG
   
   # Bastion host security group
   BASTION_SG=$(aws ec2 create-security-group \
     --group-name bastion-sg \
     --description "Security group for bastion host" \
     --vpc-id $VPC_ID \
     --tag-specifications 'ResourceType=security-group,Tags=[{Key=Name,Value=Bastion-SG}]' \
     --query 'GroupId' --output text)
   
   # Allow SSH from specific IP ranges
   aws ec2 authorize-security-group-ingress \
     --group-id $BASTION_SG \
     --protocol tcp \
     --port 22 \
     --cidr 203.0.113.0/24
   
   echo "Created security groups: Web=$WEB_SG, App=$APP_SG, DB=$DB_SG, Bastion=$BASTION_SG"
   ```

2. **Configure Network ACLs**:
   ```bash
   # Create custom NACL for public subnets
   PUBLIC_NACL=$(aws ec2 create-network-acl \
     --vpc-id $VPC_ID \
     --tag-specifications 'ResourceType=network-acl,Tags=[{Key=Name,Value=Public-NACL}]' \
     --query 'NetworkAcl.NetworkAclId' --output text)
   
   # Allow HTTP inbound
   aws ec2 create-network-acl-entry \
     --network-acl-id $PUBLIC_NACL \
     --rule-number 100 \
     --protocol tcp \
     --rule-action allow \
     --port-range From=80,To=80 \
     --cidr-block 0.0.0.0/0
   
   # Allow HTTPS inbound
   aws ec2 create-network-acl-entry \
     --network-acl-id $PUBLIC_NACL \
     --rule-number 110 \
     --protocol tcp \
     --rule-action allow \
     --port-range From=443,To=443 \
     --cidr-block 0.0.0.0/0
   
   # Allow SSH inbound
   aws ec2 create-network-acl-entry \
     --network-acl-id $PUBLIC_NACL \
     --rule-number 120 \
     --protocol tcp \
     --rule-action allow \
     --port-range From=22,To=22 \
     --cidr-block 203.0.113.0/24
   
   # Allow ephemeral ports inbound (for return traffic)
   aws ec2 create-network-acl-entry \
     --network-acl-id $PUBLIC_NACL \
     --rule-number 130 \
     --protocol tcp \
     --rule-action allow \
     --port-range From=1024,To=65535 \
     --cidr-block 0.0.0.0/0
   
   # Allow all outbound traffic
   aws ec2 create-network-acl-entry \
     --network-acl-id $PUBLIC_NACL \
     --rule-number 100 \
     --protocol -1 \
     --rule-action allow \
     --cidr-block 0.0.0.0/0 \
     --egress
   
   # Associate public subnets with custom NACL
   aws ec2 replace-network-acl-association \
     --association-id $(aws ec2 describe-network-acls \
       --filters "Name=association.subnet-id,Values=$PUBLIC_SUBNET_1" \
       --query 'NetworkAcls[0].Associations[0].NetworkAclAssociationId' --output text) \
     --network-acl-id $PUBLIC_NACL
   
   aws ec2 replace-network-acl-association \
     --association-id $(aws ec2 describe-network-acls \
       --filters "Name=association.subnet-id,Values=$PUBLIC_SUBNET_2" \
       --query 'NetworkAcls[0].Associations[0].NetworkAclAssociationId' --output text) \
     --network-acl-id $PUBLIC_NACL
   
   echo "Configured Network ACLs"
   ```

3. **Security Analysis Script**:
   ```bash
   # Create security analysis script
   cat > analyze_vpc_security.py << 'EOF'
   import boto3
   import json
   
   ec2 = boto3.client('ec2')
   
   def analyze_security_groups():
       """Analyze security group configurations"""
       print("=== Security Group Analysis ===")
       
       response = ec2.describe_security_groups()
       
       for sg in response['SecurityGroups']:
           print(f"\nSecurity Group: {sg['GroupName']} ({sg['GroupId']})")
           print(f"Description: {sg['Description']}")
           print(f"VPC: {sg.get('VpcId', 'EC2-Classic')}")
           
           # Analyze inbound rules
           print("Inbound Rules:")
           for rule in sg['IpPermissions']:
               protocol = rule.get('IpProtocol', 'All')
               from_port = rule.get('FromPort', 'All')
               to_port = rule.get('ToPort', 'All')
               
               print(f"  Protocol: {protocol}, Ports: {from_port}-{to_port}")
               
               # Check for overly permissive rules
               for ip_range in rule.get('IpRanges', []):
                   cidr = ip_range['CidrIp']
                   if cidr == '0.0.0.0/0':
                       print(f"    ⚠️  WARNING: Open to internet ({cidr})")
                   else:
                       print(f"    ✓ Restricted to {cidr}")
               
               for group in rule.get('UserIdGroupPairs', []):
                   print(f"    ✓ References SG: {group['GroupId']}")
           
           # Analyze outbound rules
           print("Outbound Rules:")
           for rule in sg['IpPermissionsEgress']:
               protocol = rule.get('IpProtocol', 'All')
               from_port = rule.get('FromPort', 'All')
               to_port = rule.get('ToPort', 'All')
               
               for ip_range in rule.get('IpRanges', []):
                   cidr = ip_range['CidrIp']
                   if cidr == '0.0.0.0/0' and protocol == '-1':
                       print(f"    ℹ️  All traffic allowed outbound (common)")
                   else:
                       print(f"    Outbound: {protocol} {from_port}-{to_port} to {cidr}")
   
   def analyze_network_acls():
       """Analyze Network ACL configurations"""
       print(f"\n=== Network ACL Analysis ===")
       
       response = ec2.describe_network_acls()
       
       for nacl in response['NetworkAcls']:
           print(f"\nNetwork ACL: {nacl['NetworkAclId']}")
           print(f"VPC: {nacl['VpcId']}")
           print(f"Default: {nacl['IsDefault']}")
           
           # Show associated subnets
           associations = nacl.get('Associations', [])
           if associations:
               print("Associated Subnets:")
               for assoc in associations:
                   print(f"  - {assoc.get('SubnetId', 'N/A')}")
           
           # Analyze entries
           print("Rules:")
           for entry in sorted(nacl['Entries'], key=lambda x: x['RuleNumber']):
               direction = "Outbound" if entry['Egress'] else "Inbound"
               protocol = entry.get('Protocol', 'All')
               action = entry['RuleAction'].upper()
               rule_num = entry['RuleNumber']
               cidr = entry['CidrBlock']
               
               port_info = ""
               if 'PortRange' in entry:
                   port_range = entry['PortRange']
                   port_info = f" Ports: {port_range['From']}-{port_range['To']}"
               
               print(f"  Rule {rule_num}: {direction} {action} {protocol}{port_info} from/to {cidr}")
   
   def check_vpc_flow_logs():
       """Check VPC Flow Logs configuration"""
       print(f"\n=== VPC Flow Logs Analysis ===")
       
       response = ec2.describe_flow_logs()
       
       if response['FlowLogs']:
           for flow_log in response['FlowLogs']:
               print(f"\nFlow Log: {flow_log['FlowLogId']}")
               print(f"Resource: {flow_log['ResourceId']}")
               print(f"Status: {flow_log['FlowLogStatus']}")
               print(f"Traffic Type: {flow_log['TrafficType']}")
               print(f"Log Destination: {flow_log.get('LogDestination', 'CloudWatch Logs')}")
       else:
           print("⚠️  No VPC Flow Logs configured")
           print("Recommendation: Enable VPC Flow Logs for security monitoring")
   
   def security_recommendations():
       """Provide security recommendations"""
       print(f"\n=== Security Recommendations ===")
       
       recommendations = [
           "Enable VPC Flow Logs for network monitoring",
           "Use least privilege principle for security groups",
           "Avoid 0.0.0.0/0 in security group rules unless necessary",
           "Implement defense in depth with both Security Groups and NACLs",
           "Regularly audit and review security group rules",
           "Use AWS Config rules to monitor security group changes",
           "Enable GuardDuty for threat detection",
           "Consider using AWS Security Hub for centralized security findings"
       ]
       
       for i, rec in enumerate(recommendations, 1):
           print(f"{i}. {rec}")
   
   if __name__ == "__main__":
       analyze_security_groups()
       analyze_network_acls()
       check_vpc_flow_logs()
       security_recommendations()
   EOF
   
   python3 analyze_vpc_security.py
   ```

**Screenshot Placeholder**:
![VPC Security Configuration](screenshots/23-vpc-security.png)
*Caption: Security Groups and NACLs configuration analysis*

### Practice 3: VPC Endpoints
**Objective**: Implement VPC endpoints for secure AWS service access

**Steps**:
1. **Create Gateway Endpoints**:
   ```bash
   # Create S3 Gateway Endpoint
   S3_ENDPOINT=$(aws ec2 create-vpc-endpoint \
     --vpc-id $VPC_ID \
     --service-name com.amazonaws.us-east-1.s3 \
     --vpc-endpoint-type Gateway \
     --route-table-ids $PRIVATE_RT_1 $PRIVATE_RT_2 $DB_RT \
     --query 'VpcEndpoint.VpcEndpointId' --output text)
   
   # Create DynamoDB Gateway Endpoint
   DYNAMODB_ENDPOINT=$(aws ec2 create-vpc-endpoint \
     --vpc-id $VPC_ID \
     --service-name com.amazonaws.us-east-1.dynamodb \
     --vpc-endpoint-type Gateway \
     --route-table-ids $PRIVATE_RT_1 $PRIVATE_RT_2 \
     --query 'VpcEndpoint.VpcEndpointId' --output text)
   
   echo "Created Gateway Endpoints: S3=$S3_ENDPOINT, DynamoDB=$DYNAMODB_ENDPOINT"
   ```

2. **Create Interface Endpoints**:
   ```bash
   # Create security group for VPC endpoints
   ENDPOINT_SG=$(aws ec2 create-security-group \
     --group-name vpc-endpoint-sg \
     --description "Security group for VPC endpoints" \
     --vpc-id $VPC_ID \
     --query 'GroupId' --output text)
   
   # Allow HTTPS from VPC
   aws ec2 authorize-security-group-ingress \
     --group-id $ENDPOINT_SG \
     --protocol tcp \
     --port 443 \
     --cidr 10.0.0.0/16
   
   # Create EC2 Interface Endpoint
   EC2_ENDPOINT=$(aws ec2 create-vpc-endpoint \
     --vpc-id $VPC_ID \
     --service-name com.amazonaws.us-east-1.ec2 \
     --vpc-endpoint-type Interface \
     --subnet-ids $PRIVATE_SUBNET_1 $PRIVATE_SUBNET_2 \
     --security-group-ids $ENDPOINT_SG \
     --private-dns-enabled \
     --query 'VpcEndpoint.VpcEndpointId' --output text)
   
   # Create SSM Interface Endpoints (for Systems Manager)
   SSM_ENDPOINT=$(aws ec2 create-vpc-endpoint \
     --vpc-id $VPC_ID \
     --service-name com.amazonaws.us-east-1.ssm \
     --vpc-endpoint-type Interface \
     --subnet-ids $PRIVATE_SUBNET_1 $PRIVATE_SUBNET_2 \
     --security-group-ids $ENDPOINT_SG \
     --private-dns-enabled \
     --query 'VpcEndpoint.VpcEndpointId' --output text)
   
   SSM_MESSAGES_ENDPOINT=$(aws ec2 create-vpc-endpoint \
     --vpc-id $VPC_ID \
     --service-name com.amazonaws.us-east-1.ssmmessages \
     --vpc-endpoint-type Interface \
     --subnet-ids $PRIVATE_SUBNET_1 $PRIVATE_SUBNET_2 \
     --security-group-ids $ENDPOINT_SG \
     --private-dns-enabled \
     --query 'VpcEndpoint.VpcEndpointId' --output text)
   
   EC2_MESSAGES_ENDPOINT=$(aws ec2 create-vpc-endpoint \
     --vpc-id $VPC_ID \
     --service-name com.amazonaws.us-east-1.ec2messages \
     --vpc-endpoint-type Interface \
     --subnet-ids $PRIVATE_SUBNET_1 $PRIVATE_SUBNET_2 \
     --security-group-ids $ENDPOINT_SG \
     --private-dns-enabled \
     --query 'VpcEndpoint.VpcEndpointId' --output text)
   
   echo "Created Interface Endpoints: EC2=$EC2_ENDPOINT, SSM=$SSM_ENDPOINT"
   ```

3. **Test VPC Endpoints**:
   ```bash
   # Create VPC endpoint testing script
   cat > test_vpc_endpoints.py << 'EOF'
   import boto3
   import json
   import socket
   
   def test_gateway_endpoints():
       """Test Gateway VPC Endpoints"""
       print("=== Testing Gateway VPC Endpoints ===")
       
       # Test S3 access
       s3_client = boto3.client('s3')
       
       try:
           response = s3_client.list_buckets()
           print(f"✓ S3 Gateway Endpoint: Successfully listed {len(response['Buckets'])} buckets")
       except Exception as e:
           print(f"✗ S3 Gateway Endpoint: Error - {e}")
       
       # Test DynamoDB access
       dynamodb_client = boto3.client('dynamodb')
       
       try:
           response = dynamodb_client.list_tables()
           print(f"✓ DynamoDB Gateway Endpoint: Successfully listed {len(response['TableNames'])} tables")
       except Exception as e:
           print(f"✗ DynamoDB Gateway Endpoint: Error - {e}")
   
   def test_interface_endpoints():
       """Test Interface VPC Endpoints"""
       print(f"\n=== Testing Interface VPC Endpoints ===")
       
       # Test EC2 endpoint
       ec2_client = boto3.client('ec2')
       
       try:
           response = ec2_client.describe_instances()
           print(f"✓ EC2 Interface Endpoint: Successfully described instances")
       except Exception as e:
           print(f"✗ EC2 Interface Endpoint: Error - {e}")
       
       # Test SSM endpoint
       ssm_client = boto3.client('ssm')
       
       try:
           response = ssm_client.describe_instance_information()
           print(f"✓ SSM Interface Endpoint: Successfully connected")
       except Exception as e:
           print(f"✗ SSM Interface Endpoint: Error - {e}")
   
   def check_dns_resolution():
       """Check DNS resolution for VPC endpoints"""
       print(f"\n=== DNS Resolution Test ===")
       
       services = [
           's3.amazonaws.com',
           'dynamodb.us-east-1.amazonaws.com',
           'ec2.us-east-1.amazonaws.com',
           'ssm.us-east-1.amazonaws.com'
       ]
       
       for service in services:
           try:
               ip_address = socket.gethostbyname(service)
               print(f"✓ {service} resolves to {ip_address}")
               
               # Check if it's a private IP (VPC endpoint)
               if ip_address.startswith('10.') or ip_address.startswith('172.') or ip_address.startswith('192.168.'):
                   print(f"  → Using VPC Endpoint (private IP)")
               else:
                   print(f"  → Using public endpoint")
                   
           except Exception as e:
               print(f"✗ {service}: DNS resolution failed - {e}")
   
   def list_vpc_endpoints():
       """List all VPC endpoints"""
       print(f"\n=== VPC Endpoints Inventory ===")
       
       ec2_client = boto3.client('ec2')
       
       try:
           response = ec2_client.describe_vpc_endpoints()
           
           for endpoint in response['VpcEndpoints']:
               print(f"\nEndpoint ID: {endpoint['VpcEndpointId']}")
               print(f"Service: {endpoint['ServiceName']}")
               print(f"Type: {endpoint['VpcEndpointType']}")
               print(f"State: {endpoint['State']}")
               print(f"VPC: {endpoint['VpcId']}")
               
               if endpoint['VpcEndpointType'] == 'Interface':
                   print(f"DNS Names: {endpoint.get('DnsEntries', [])}")
                   print(f"Subnets: {endpoint.get('SubnetIds', [])}")
               elif endpoint['VpcEndpointType'] == 'Gateway':
                   print(f"Route Tables: {endpoint.get('RouteTableIds', [])}")
                   
       except Exception as e:
           print(f"Error listing VPC endpoints: {e}")
   
   def calculate_cost_savings():
       """Calculate potential cost savings from VPC endpoints"""
       print(f"\n=== Cost Savings Analysis ===")
       
       print("VPC Endpoint Cost Considerations:")
       print("1. Gateway Endpoints (S3, DynamoDB): No additional charge")
       print("2. Interface Endpoints: $0.01 per hour per endpoint + data processing")
       print("3. Savings: Reduced NAT Gateway data processing charges")
       print("4. Security: Traffic stays within AWS network")
       print("5. Performance: Lower latency for AWS service calls")
       
       print("\nRecommendations:")
       print("- Use Gateway endpoints for S3 and DynamoDB (free)")
       print("- Use Interface endpoints for frequently accessed services")
       print("- Monitor data transfer costs vs endpoint costs")
   
   if __name__ == "__main__":
       list_vpc_endpoints()
       test_gateway_endpoints()
       test_interface_endpoints()
       check_dns_resolution()
       calculate_cost_savings()
   EOF
   
   python3 test_vpc_endpoints.py
   ```

**Screenshot Placeholder**:
![VPC Endpoints Configuration](screenshots/23-vpc-endpoints.png)
*Caption: VPC Gateway and Interface endpoints setup and testing*

### Practice 4: VPC Peering
**Objective**: Set up VPC peering for cross-VPC communication

**Steps**:
1. **Create Second VPC for Peering**:
   ```bash
   # Create second VPC
   VPC_2_ID=$(aws ec2 create-vpc \
     --cidr-block 10.1.0.0/16 \
     --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=Development-VPC}]' \
     --query 'Vpc.VpcId' --output text)
   
   # Enable DNS for second VPC
   aws ec2 modify-vpc-attribute --vpc-id $VPC_2_ID --enable-dns-hostnames
   aws ec2 modify-vpc-attribute --vpc-id $VPC_2_ID --enable-dns-support
   
   # Create subnet in second VPC
   DEV_SUBNET=$(aws ec2 create-subnet \
     --vpc-id $VPC_2_ID \
     --cidr-block 10.1.1.0/24 \
     --availability-zone $AZ1 \
     --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Development-Subnet}]' \
     --query 'Subnet.SubnetId' --output text)
   
   echo "Created Development VPC: $VPC_2_ID with subnet: $DEV_SUBNET"
   ```

2. **Create VPC Peering Connection**:
   ```bash
   # Create peering connection
   PEERING_ID=$(aws ec2 create-vpc-peering-connection \
     --vpc-id $VPC_ID \
     --peer-vpc-id $VPC_2_ID \
     --tag-specifications 'ResourceType=vpc-peering-connection,Tags=[{Key=Name,Value=Prod-Dev-Peering}]' \
     --query 'VpcPeeringConnection.VpcPeeringConnectionId' --output text)
   
   # Accept peering connection
   aws ec2 accept-vpc-peering-connection \
     --vpc-peering-connection-id $PEERING_ID
   
   # Wait for peering connection to be active
   aws ec2 wait vpc-peering-connection-exists \
     --vpc-peering-connection-ids $PEERING_ID
   
   echo "Created and accepted VPC peering connection: $PEERING_ID"
   ```

3. **Configure Peering Routes**:
   ```bash
   # Add routes for peering in Production VPC
   aws ec2 create-route \
     --route-table-id $PRIVATE_RT_1 \
     --destination-cidr-block 10.1.0.0/16 \
     --vpc-peering-connection-id $PEERING_ID
   
   aws ec2 create-route \
     --route-table-id $PRIVATE_RT_2 \
     --destination-cidr-block 10.1.0.0/16 \
     --vpc-peering-connection-id $PEERING_ID
   
   # Create route table for Development VPC
   DEV_RT=$(aws ec2 create-route-table \
     --vpc-id $VPC_2_ID \
     --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=Development-Route-Table}]' \
     --query 'RouteTable.RouteTableId' --output text)
   
   # Add route to Production VPC
   aws ec2 create-route \
     --route-table-id $DEV_RT \
     --destination-cidr-block 10.0.0.0/16 \
     --vpc-peering-connection-id $PEERING_ID
   
   # Associate development subnet with route table
   aws ec2 associate-route-table --subnet-id $DEV_SUBNET --route-table-id $DEV_RT
   
   echo "Configured peering routes"
   ```

4. **Test VPC Peering**:
   ```bash
   # Create VPC peering test script
   cat > test_vpc_peering.py << 'EOF'
   import boto3
   import json
   
   def test_vpc_peering():
       """Test VPC peering connectivity"""
       print("=== VPC Peering Test ===")
       
       ec2 = boto3.client('ec2')
       
       # List peering connections
       response = ec2.describe_vpc_peering_connections()
       
       for peering in response['VpcPeeringConnections']:
           print(f"\nPeering Connection: {peering['VpcPeeringConnectionId']}")
           print(f"Status: {peering['Status']['Code']}")
           print(f"Requester VPC: {peering['RequesterVpcInfo']['VpcId']} ({peering['RequesterVpcInfo']['CidrBlock']})")
           print(f"Accepter VPC: {peering['AccepterVpcInfo']['VpcId']} ({peering['AccepterVpcInfo']['CidrBlock']})")
           
           # Check DNS resolution options
           if 'RequesterVpcInfo' in peering:
               req_dns = peering['RequesterVpcInfo'].get('PeeringOptions', {})
               print(f"Requester DNS Resolution: {req_dns.get('AllowDnsResolutionFromRemoteVpc', False)}")
           
           if 'AccepterVpcInfo' in peering:
               acc_dns = peering['AccepterVpcInfo'].get('PeeringOptions', {})
               print(f"Accepter DNS Resolution: {acc_dns.get('AllowDnsResolutionFromRemoteVpc', False)}")
   
   def analyze_peering_routes():
       """Analyze routes for peering connections"""
       print(f"\n=== Peering Route Analysis ===")
       
       ec2 = boto3.client('ec2')
       
       # Get all route tables
       response = ec2.describe_route_tables()
       
       for rt in response['RouteTables']:
           peering_routes = [route for route in rt['Routes'] 
                           if route.get('VpcPeeringConnectionId')]
           
           if peering_routes:
               print(f"\nRoute Table: {rt['RouteTableId']}")
               print(f"VPC: {rt['VpcId']}")
               
               for route in peering_routes:
                   print(f"  Route: {route['DestinationCidrBlock']} → {route['VpcPeeringConnectionId']}")
                   print(f"  State: {route['State']}")
   
   def peering_best_practices():
       """Display VPC peering best practices"""
       print(f"\n=== VPC Peering Best Practices ===")
       
       practices = [
           "Avoid overlapping CIDR blocks between peered VPCs",
           "Use specific routes instead of 0.0.0.0/0 for peering",
           "Enable DNS resolution for cross-VPC name resolution",
           "Update security groups to allow cross-VPC traffic",
           "Monitor peering connection status and metrics",
           "Consider Transit Gateway for complex multi-VPC architectures",
           "Document peering relationships and dependencies",
           "Implement proper tagging for peering connections"
       ]
       
       for i, practice in enumerate(practices, 1):
           print(f"{i}. {practice}")
   
   if __name__ == "__main__":
       test_vpc_peering()
       analyze_peering_routes()
       peering_best_practices()
   EOF
   
   python3 test_vpc_peering.py
   ```

**Screenshot Placeholder**:
![VPC Peering Configuration](screenshots/23-vpc-peering.png)
*Caption: VPC peering connection setup and route configuration*

## ✅ Section Completion Checklist

- [ ] Designed and implemented multi-tier VPC architecture
- [ ] Configured public, private, and database subnets across AZs
- [ ] Set up Internet Gateway and NAT Gateways for internet access
- [ ] Created comprehensive Security Groups with least privilege
- [ ] Configured Network ACLs for subnet-level security
- [ ] Implemented VPC Gateway and Interface endpoints
- [ ] Set up VPC peering for cross-VPC communication
- [ ] Tested network connectivity and security controls
- [ ] Analyzed network performance and cost optimization
- [ ] Documented network architecture and security policies

## 🎯 Key Takeaways

- **Multi-Tier Design**: Separate tiers for security and scalability
- **High Availability**: Deploy across multiple Availability Zones
- **Security Layers**: Use both Security Groups and NACLs
- **VPC Endpoints**: Reduce costs and improve security for AWS services
- **Peering**: Enable secure cross-VPC communication
- **Route Tables**: Control traffic flow with proper routing
- **NAT Gateways**: Provide secure outbound internet access
- **Monitoring**: Implement VPC Flow Logs for network visibility

## 📚 Additional Resources

- [Amazon VPC User Guide](https://docs.aws.amazon.com/vpc/)
- [VPC Security Best Practices](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-best-practices.html)
- [VPC Endpoints Guide](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-endpoints.html)
- [VPC Peering Guide](https://docs.aws.amazon.com/vpc/latest/peering/)
- [AWS Networking Best Practices](https://aws.amazon.com/architecture/well-architected/)
- [VPC Flow Logs](https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs.html)