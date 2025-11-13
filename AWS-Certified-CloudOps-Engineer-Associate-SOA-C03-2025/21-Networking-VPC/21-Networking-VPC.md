# 21. Networking - VPC

## Lab 1: VPC Creation and Configuration

### Create VPC with CLI
```bash
# Create VPC
aws ec2 create-vpc \
  --cidr-block 10.0.0.0/16 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=CloudOps-VPC}]'

# Enable DNS hostnames
aws ec2 modify-vpc-attribute \
  --vpc-id vpc-xxxxxxxxx \
  --enable-dns-hostnames

# Enable DNS support
aws ec2 modify-vpc-attribute \
  --vpc-id vpc-xxxxxxxxx \
  --enable-dns-support
```

### Create Subnets
```bash
# Create public subnet
aws ec2 create-subnet \
  --vpc-id vpc-xxxxxxxxx \
  --cidr-block 10.0.1.0/24 \
  --availability-zone us-east-1a \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Public-Subnet-1a}]'

# Create private subnet
aws ec2 create-subnet \
  --vpc-id vpc-xxxxxxxxx \
  --cidr-block 10.0.2.0/24 \
  --availability-zone us-east-1a \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Private-Subnet-1a}]'

# Enable auto-assign public IP for public subnet
aws ec2 modify-subnet-attribute \
  --subnet-id subnet-xxxxxxxxx \
  --map-public-ip-on-launch
```

## Terraform VPC Configuration

```hcl
# vpc.tf
resource "aws_vpc" "cloudops_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "CloudOps-VPC"
  }
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Public subnets
resource "aws_subnet" "public" {
  count = 2
  
  vpc_id                  = aws_vpc.cloudops_vpc.id
  cidr_block              = "10.0.${count.index + 1}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  
  tags = {
    Name = "Public-Subnet-${count.index + 1}"
    Type = "Public"
  }
}

# Private subnets
resource "aws_subnet" "private" {
  count = 2
  
  vpc_id            = aws_vpc.cloudops_vpc.id
  cidr_block        = "10.0.${count.index + 10}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
  
  tags = {
    Name = "Private-Subnet-${count.index + 1}"
    Type = "Private"
  }
}

# Database subnets
resource "aws_subnet" "database" {
  count = 2
  
  vpc_id            = aws_vpc.cloudops_vpc.id
  cidr_block        = "10.0.${count.index + 20}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
  
  tags = {
    Name = "Database-Subnet-${count.index + 1}"
    Type = "Database"
  }
}
```

## Lab 2: Internet Gateway and NAT Gateway

### Create Internet Gateway
```bash
# Create Internet Gateway
aws ec2 create-internet-gateway \
  --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=CloudOps-IGW}]'

# Attach Internet Gateway to VPC
aws ec2 attach-internet-gateway \
  --internet-gateway-id igw-xxxxxxxxx \
  --vpc-id vpc-xxxxxxxxx
```

### Create NAT Gateway
```bash
# Allocate Elastic IP
aws ec2 allocate-address \
  --domain vpc \
  --tag-specifications 'ResourceType=elastic-ip,Tags=[{Key=Name,Value=CloudOps-NAT-EIP}]'

# Create NAT Gateway
aws ec2 create-nat-gateway \
  --subnet-id subnet-xxxxxxxxx \
  --allocation-id eipalloc-xxxxxxxxx \
  --tag-specifications 'ResourceType=nat-gateway,Tags=[{Key=Name,Value=CloudOps-NAT}]'
```

### Terraform Gateway Configuration
```hcl
# gateways.tf
resource "aws_internet_gateway" "cloudops_igw" {
  vpc_id = aws_vpc.cloudops_vpc.id
  
  tags = {
    Name = "CloudOps-IGW"
  }
}

resource "aws_eip" "nat_eip" {
  count = 2
  
  domain = "vpc"
  
  tags = {
    Name = "CloudOps-NAT-EIP-${count.index + 1}"
  }
  
  depends_on = [aws_internet_gateway.cloudops_igw]
}

resource "aws_nat_gateway" "cloudops_nat" {
  count = 2
  
  allocation_id = aws_eip.nat_eip[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  
  tags = {
    Name = "CloudOps-NAT-${count.index + 1}"
  }
  
  depends_on = [aws_internet_gateway.cloudops_igw]
}
```

## Lab 3: Route Tables

### Create Route Tables
```bash
# Create public route table
aws ec2 create-route-table \
  --vpc-id vpc-xxxxxxxxx \
  --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=Public-Route-Table}]'

# Add route to Internet Gateway
aws ec2 create-route \
  --route-table-id rtb-xxxxxxxxx \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id igw-xxxxxxxxx

# Associate subnet with route table
aws ec2 associate-route-table \
  --subnet-id subnet-xxxxxxxxx \
  --route-table-id rtb-xxxxxxxxx

# Create private route table
aws ec2 create-route-table \
  --vpc-id vpc-xxxxxxxxx \
  --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=Private-Route-Table}]'

# Add route to NAT Gateway
aws ec2 create-route \
  --route-table-id rtb-yyyyyyyyy \
  --destination-cidr-block 0.0.0.0/0 \
  --nat-gateway-id nat-xxxxxxxxx
```

### Terraform Route Tables
```hcl
# route-tables.tf
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.cloudops_vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cloudops_igw.id
  }
  
  tags = {
    Name = "Public-Route-Table"
  }
}

resource "aws_route_table" "private" {
  count = 2
  
  vpc_id = aws_vpc.cloudops_vpc.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.cloudops_nat[count.index].id
  }
  
  tags = {
    Name = "Private-Route-Table-${count.index + 1}"
  }
}

resource "aws_route_table_association" "public" {
  count = 2
  
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count = 2
  
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
```

## Lab 4: Security Groups and NACLs

### Create Security Groups
```bash
# Create web security group
aws ec2 create-security-group \
  --group-name web-sg \
  --description "Security group for web servers" \
  --vpc-id vpc-xxxxxxxxx

# Add HTTP rule
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxxxxxx \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0

# Add HTTPS rule
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxxxxxx \
  --protocol tcp \
  --port 443 \
  --cidr 0.0.0.0/0

# Add SSH rule
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxxxxxx \
  --protocol tcp \
  --port 22 \
  --source-group sg-yyyyyyyyy
```

### Create Network ACLs
```bash
# Create custom NACL
aws ec2 create-network-acl \
  --vpc-id vpc-xxxxxxxxx \
  --tag-specifications 'ResourceType=network-acl,Tags=[{Key=Name,Value=Custom-NACL}]'

# Add inbound rule
aws ec2 create-network-acl-entry \
  --network-acl-id acl-xxxxxxxxx \
  --rule-number 100 \
  --protocol tcp \
  --rule-action allow \
  --port-range From=80,To=80 \
  --cidr-block 0.0.0.0/0

# Add outbound rule
aws ec2 create-network-acl-entry \
  --network-acl-id acl-xxxxxxxxx \
  --rule-number 100 \
  --protocol tcp \
  --rule-action allow \
  --port-range From=80,To=80 \
  --cidr-block 0.0.0.0/0 \
  --egress
```

### Terraform Security Configuration
```hcl
# security.tf
resource "aws_security_group" "web_sg" {
  name_prefix = "web-sg"
  vpc_id      = aws_vpc.cloudops_vpc.id
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "Web Security Group"
  }
}

resource "aws_security_group" "database_sg" {
  name_prefix = "database-sg"
  vpc_id      = aws_vpc.cloudops_vpc.id
  
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "Database Security Group"
  }
}

resource "aws_network_acl" "custom_nacl" {
  vpc_id = aws_vpc.cloudops_vpc.id
  
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }
  
  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }
  
  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }
  
  tags = {
    Name = "Custom NACL"
  }
}
```

## Lab 5: VPC Peering

### Create VPC Peering Connection
```bash
# Create peering connection
aws ec2 create-vpc-peering-connection \
  --vpc-id vpc-xxxxxxxxx \
  --peer-vpc-id vpc-yyyyyyyyy \
  --peer-region us-west-2

# Accept peering connection (from peer VPC region)
aws ec2 accept-vpc-peering-connection \
  --vpc-peering-connection-id pcx-xxxxxxxxx \
  --region us-west-2

# Add route for peering connection
aws ec2 create-route \
  --route-table-id rtb-xxxxxxxxx \
  --destination-cidr-block 10.1.0.0/16 \
  --vpc-peering-connection-id pcx-xxxxxxxxx
```

### Terraform VPC Peering
```hcl
# vpc-peering.tf
resource "aws_vpc_peering_connection" "cloudops_peering" {
  vpc_id      = aws_vpc.cloudops_vpc.id
  peer_vpc_id = aws_vpc.peer_vpc.id
  peer_region = "us-west-2"
  auto_accept = false
  
  tags = {
    Name = "CloudOps VPC Peering"
  }
}

resource "aws_vpc_peering_connection_accepter" "peer_accepter" {
  provider                  = aws.peer
  vpc_peering_connection_id = aws_vpc_peering_connection.cloudops_peering.id
  auto_accept               = true
  
  tags = {
    Name = "CloudOps Peering Accepter"
  }
}

resource "aws_route" "peering_route" {
  route_table_id            = aws_route_table.private[0].id
  destination_cidr_block    = "10.1.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.cloudops_peering.id
}
```

## Lab 6: VPC Endpoints

### Create VPC Endpoints
```bash
# Create S3 VPC endpoint (Gateway)
aws ec2 create-vpc-endpoint \
  --vpc-id vpc-xxxxxxxxx \
  --service-name com.amazonaws.us-east-1.s3 \
  --vpc-endpoint-type Gateway \
  --route-table-ids rtb-xxxxxxxxx

# Create EC2 VPC endpoint (Interface)
aws ec2 create-vpc-endpoint \
  --vpc-id vpc-xxxxxxxxx \
  --service-name com.amazonaws.us-east-1.ec2 \
  --vpc-endpoint-type Interface \
  --subnet-ids subnet-xxxxxxxxx \
  --security-group-ids sg-xxxxxxxxx
```

### Terraform VPC Endpoints
```hcl
# vpc-endpoints.tf
resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id            = aws_vpc.cloudops_vpc.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private[0].id]
  
  tags = {
    Name = "S3 VPC Endpoint"
  }
}

resource "aws_vpc_endpoint" "ec2_endpoint" {
  vpc_id              = aws_vpc.cloudops_vpc.id
  service_name        = "com.amazonaws.${var.aws_region}.ec2"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private[0].id]
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]
  private_dns_enabled = true
  
  tags = {
    Name = "EC2 VPC Endpoint"
  }
}

resource "aws_security_group" "vpc_endpoint_sg" {
  name_prefix = "vpc-endpoint-sg"
  vpc_id      = aws_vpc.cloudops_vpc.id
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.cloudops_vpc.cidr_block]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "VPC Endpoint Security Group"
  }
}
```

## Lab 7: Flow Logs

### Enable VPC Flow Logs
```bash
# Create IAM role for Flow Logs
aws iam create-role \
  --role-name flowlogsRole \
  --assume-role-policy-document file://flowlogs-trust-policy.json

# Create Flow Logs
aws ec2 create-flow-logs \
  --resource-type VPC \
  --resource-ids vpc-xxxxxxxxx \
  --traffic-type ALL \
  --log-destination-type cloud-watch-logs \
  --log-group-name VPCFlowLogs \
  --deliver-logs-permission-arn arn:aws:iam::123456789012:role/flowlogsRole
```

### Terraform Flow Logs
```hcl
# flow-logs.tf
resource "aws_flow_log" "vpc_flow_log" {
  iam_role_arn    = aws_iam_role.flow_log_role.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_log.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.cloudops_vpc.id
  
  tags = {
    Name = "VPC Flow Logs"
  }
}

resource "aws_cloudwatch_log_group" "vpc_flow_log" {
  name              = "VPCFlowLogs"
  retention_in_days = 14
}

resource "aws_iam_role" "flow_log_role" {
  name = "flowlogsRole"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })
}
```

## Best Practices

1. **Use multiple AZs** for high availability
2. **Implement proper subnet design** (public, private, database)
3. **Use security groups** as stateful firewalls
4. **Implement NACLs** for additional security layer
5. **Enable VPC Flow Logs** for monitoring
6. **Use VPC endpoints** to reduce NAT Gateway costs
7. **Plan CIDR blocks** carefully to avoid conflicts

## Troubleshooting

```bash
# Check route tables
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=vpc-xxxxxxxxx"

# Check security group rules
aws ec2 describe-security-groups --group-ids sg-xxxxxxxxx

# Check VPC peering status
aws ec2 describe-vpc-peering-connections

# Analyze flow logs
aws logs filter-log-events \
  --log-group-name VPCFlowLogs \
  --filter-pattern "[srcaddr, dstaddr, srcport, dstport, protocol, packets, bytes, windowstart, windowend, action=\"REJECT\"]"
```

## Cleanup

```bash
# Delete VPC (will delete associated resources)
aws ec2 delete-vpc --vpc-id vpc-xxxxxxxxx

# Delete NAT Gateway
aws ec2 delete-nat-gateway --nat-gateway-id nat-xxxxxxxxx

# Release Elastic IP
aws ec2 release-address --allocation-id eipalloc-xxxxxxxxx
```