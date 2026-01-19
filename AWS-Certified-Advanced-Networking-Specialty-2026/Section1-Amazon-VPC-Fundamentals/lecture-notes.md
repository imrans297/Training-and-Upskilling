# Section 1: Amazon VPC Fundamentals - Lecture Notes

**Course:** AWS Certified Advanced Networking Specialty 2026

---

## Lecture 1: Section Introduction

### Overview
- Introduction to VPC fundamentals
- Core networking concepts in AWS
- Foundation for advanced networking topics

---

## Lecture 2: What is Amazon VPC?

### Definition
- **VPC** = Virtual Private Cloud
- Logically isolated virtual network in AWS Cloud
- Complete control over networking environment

### Key Points
- Launch AWS resources in a virtual network you define
- Resembles traditional network in your data center
- Benefits of AWS scalable infrastructure
- Regional service (spans all AZs in a region)

### VPC Characteristics
- **Isolation**: Logically isolated from other VPCs
- **Control**: Full control over IP addressing, subnets, routing
- **Security**: Multiple layers of security (SG, NACL)
- **Connectivity**: Connect to internet, on-premises, other VPCs

---

## Lecture 3: Scope of VPC with respect to AWS Account, Region & AZ 

### VPC Scope Hierarchy

```
AWS Account
  └── Region (e.g., us-east-1)
      └── VPC (Regional resource)
          └── Availability Zones (AZ)
              └── Subnets (AZ-specific)
```

### Key Concepts

**Account Level:**
- Default limit: 5 VPCs per region
- Can request increase
- VPCs are isolated per account

**Region Level:**
- VPC is a regional construct
- Spans all AZs in that region
- Cannot span multiple regions
- Each region has independent VPCs

**Availability Zone Level:**
- Subnets are AZ-specific
- One subnet = One AZ
- Can have multiple subnets in same AZ
- Resources in subnet are in that AZ

### Example
```
Account: 123456789012
  Region: us-east-1
    VPC: vpc-abc123 (10.0.0.0/16)
      AZ: us-east-1a
        Subnet: subnet-111 (10.0.1.0/24) - Public
        Subnet: subnet-222 (10.0.10.0/24) - Private
      AZ: us-east-1b
        Subnet: subnet-333 (10.0.2.0/24) - Public
        Subnet: subnet-444 (10.0.11.0/24) - Private
```

---

## Lecture 4: VPC Building Blocks - Core Components 

### Core Components

1. **VPC (Virtual Private Cloud)**
   - Container for all networking resources
   - Defined by CIDR block

2. **Subnets**
   - Subdivision of VPC
   - Tied to specific AZ
   - Public or Private

3. **Route Tables**
   - Control traffic routing
   - Associated with subnets

4. **Internet Gateway (IGW)**
   - Gateway to internet
   - One per VPC

5. **NAT Gateway/Instance**
   - Outbound internet for private subnets
   - Deployed in public subnet

6. **Security Groups**
   - Virtual firewall for instances
   - Stateful

7. **Network ACLs**
   - Firewall for subnets
   - Stateless

8. **VPC Endpoints**
   - Private connection to AWS services
   - No internet required

### Component Relationships
```
VPC
├── Subnets (multiple)
│   ├── Route Table (associated)
│   ├── NACL (associated)
│   └── Instances
│       └── Security Groups (attached)
├── Internet Gateway (attached)
└── NAT Gateway (in public subnet)
```

---

## Lecture 5: VPC Addressing (CIDR)

### CIDR Notation
- **Format**: IP/prefix (e.g., 10.0.0.0/16)
- **Prefix**: Number of network bits
- **Host bits**: Remaining bits for hosts

### CIDR Calculation

**Example: 10.0.0.0/16**
- Network bits: 16
- Host bits: 32 - 16 = 16
- Total IPs: 2^16 = 65,536
- Range: 10.0.0.0 - 10.0.255.255

**Example: 10.0.1.0/24**
- Network bits: 24
- Host bits: 32 - 24 = 8
- Total IPs: 2^8 = 256
- Range: 10.0.1.0 - 10.0.1.255

### VPC CIDR Rules

**Size Constraints:**
- Minimum: /28 (16 IPs)
- Maximum: /16 (65,536 IPs)
- Recommended: /16 for large VPCs, /24 for small

**RFC 1918 Private Ranges:**
- 10.0.0.0/8 (10.0.0.0 - 10.255.255.255)
- 172.16.0.0/12 (172.16.0.0 - 172.31.255.255)
- 192.168.0.0/16 (192.168.0.0 - 192.168.255.255)

**Secondary CIDR Blocks:**
- Can add up to 5 secondary CIDRs
- Must not overlap with primary
- Useful for VPC expansion

### Subnet CIDR

**AWS Reserved IPs (per subnet):**
- **.0**: Network address
- **.1**: VPC router
- **.2**: DNS server (Amazon-provided)
- **.3**: Reserved for future use
- **.255**: Broadcast address (reserved but not used)

**Example: 10.0.1.0/24**
- Total IPs: 256
- Reserved: 5
- Usable: 251

### CIDR Planning Best Practices
1. Plan for growth (use larger CIDR)
2. Avoid overlapping with on-premises networks
3. Leave room for additional subnets
4. Use consistent subnet sizing
5. Document IP allocation

---

## Lecture 6: VPC Route Tables

### Route Table Basics

**Components:**
- **Destination**: CIDR block
- **Target**: Where to send traffic
- **Local Route**: Always present for VPC CIDR

### Route Table Types

**1. Main Route Table**
- Default for all subnets
- Created automatically with VPC
- Best practice: Don't modify, create custom

**2. Custom Route Tables**
- Created by user
- Explicitly associated with subnets
- Recommended for production

### Route Priority

**Longest Prefix Match:**
- Most specific route wins
- Example:
  - 10.0.1.0/24 (more specific)
  - 10.0.0.0/16 (less specific)
  - Traffic to 10.0.1.5 uses first route

### Common Route Targets

| Target | Description | Use Case |
|--------|-------------|----------|
| local | VPC CIDR | Internal VPC traffic |
| igw-xxx | Internet Gateway | Internet access |
| nat-xxx | NAT Gateway | Private subnet internet |
| pcx-xxx | VPC Peering | VPC-to-VPC |
| vgw-xxx | Virtual Private Gateway | VPN connection |
| tgw-xxx | Transit Gateway | Multi-VPC routing |
| eni-xxx | Network Interface | Appliance routing |

### Route Table Examples

**Public Subnet Route Table:**
```
Destination       Target
10.0.0.0/16      local
0.0.0.0/0        igw-abc123
```

**Private Subnet Route Table:**
```
Destination       Target
10.0.0.0/16      local
0.0.0.0/0        nat-xyz789
```

### Route Propagation
- Automatic route addition
- Used with VPN connections
- Routes propagated from Virtual Private Gateway

---

## Lecture 11: IP Addresses - IPv4 vs IPv6, Private vs Public vs Elastic IP

### IPv4 vs IPv6

| Feature | IPv4 | IPv6 |
|---------|------|------|
| Address Length | 32 bits | 128 bits |
| Format | 192.168.1.1 | 2001:0db8::1 |
| Total Addresses | 4.3 billion | 340 undecillion |
| VPC Support | Default | Optional |
| Public IPs | Limited | Abundant |

### Private IP Addresses

**Characteristics:**
- Assigned from VPC CIDR
- Persistent (stays with instance)
- Used for internal communication
- Free

**Assignment:**
- Automatic (from subnet CIDR)
- Manual (specify IP)
- Primary + Secondary IPs

### Public IP Addresses

**Characteristics:**
- Assigned from AWS pool
- Changes on stop/start
- Released when instance stops
- Used for internet communication
- Free

**Auto-assign:**
- Enabled at subnet level
- Can override at instance launch

### Elastic IP (EIP)

**Characteristics:**
- Static public IPv4 address
- Persists across stop/start
- Can reassign to different instances
- Charged when not associated
- Limited to 5 per region (default)

**Use Cases:**
- NAT Gateways
- Instances requiring static IP
- Failover scenarios
- DNS pointing to fixed IP

**Best Practices:**
- Use EIP only when necessary
- Release unused EIPs
- Consider using DNS instead
- Use Load Balancers for web apps

### IPv6 in VPC

**Characteristics:**
- All IPv6 addresses are public
- No NAT required
- Free
- Dual-stack support (IPv4 + IPv6)

**Configuration:**
- Associate IPv6 CIDR with VPC
- Assign IPv6 to subnets
- Enable IPv6 on instances
- Update route tables and security groups

---

## Lecture 12: VPC Firewall - Security Group

### Security Group Basics

**Characteristics:**
- Virtual firewall for instances
- Operates at instance/ENI level
- Stateful (return traffic automatic)
- Allow rules only (no deny)
- Evaluates all rules before deciding

### Rule Components

**Inbound Rules:**
- Type (SSH, HTTP, Custom)
- Protocol (TCP, UDP, ICMP)
- Port Range
- Source (IP, CIDR, SG)

**Outbound Rules:**
- Type
- Protocol
- Port Range
- Destination (IP, CIDR, SG)

### Default Behavior

**New Security Group:**
- All inbound: DENIED
- All outbound: ALLOWED

**Default Security Group:**
- Inbound: Allow from same SG
- Outbound: Allow all

### Security Group Features

**1. Stateful Nature:**
```
Inbound: Allow SSH (22) from 1.2.3.4
→ Return traffic automatically allowed
No need for outbound rule
```

**2. Multiple Security Groups:**
- Up to 5 SGs per instance (default)
- Rules are aggregated (OR logic)
- More SGs = more rules evaluated

**3. Referencing Security Groups:**
```
SG-Web: Allow HTTP from 0.0.0.0/0
SG-App: Allow 8080 from SG-Web
SG-DB: Allow 3306 from SG-App
```

### Best Practices
1. Use descriptive names
2. Principle of least privilege
3. Reference SGs instead of IPs
4. Separate SGs per tier (web, app, db)
5. Document rules with descriptions
6. Regular audit and cleanup

---

## Lecture 13: VPC Firewall - Network Access Control List (NACL)

### NACL Basics

**Characteristics:**
- Firewall at subnet level
- Stateless (must allow return traffic)
- Allow and Deny rules
- Rules processed in number order
- Applies to all instances in subnet

### Rule Components

**Rule Number:**
- 1-32766
- Lower number = higher priority
- Processed in order
- First match wins

**Rule Fields:**
- Rule number
- Type (SSH, HTTP, Custom)
- Protocol
- Port range
- Source/Destination
- Allow/Deny

### Default NACL

**Behavior:**
- Allows all inbound traffic
- Allows all outbound traffic
- Cannot be deleted
- Can be modified

### Custom NACL

**Default Behavior:**
- Denies all inbound traffic
- Denies all outbound traffic
- Must explicitly allow traffic

### NACL Example

**Inbound Rules:**
```
Rule #  Type        Protocol  Port    Source          Allow/Deny
100     HTTP        TCP       80      0.0.0.0/0       ALLOW
110     HTTPS       TCP       443     0.0.0.0/0       ALLOW
120     SSH         TCP       22      1.2.3.4/32      ALLOW
*       All         All       All     0.0.0.0/0       DENY
```

**Outbound Rules:**
```
Rule #  Type        Protocol  Port        Destination     Allow/Deny
100     HTTP        TCP       80          0.0.0.0/0       ALLOW
110     HTTPS       TCP       443         0.0.0.0/0       ALLOW
120     Ephemeral   TCP       1024-65535  0.0.0.0/0       ALLOW
*       All         All       All         0.0.0.0/0       DENY
```

### Ephemeral Ports

**Purpose:**
- Return traffic for outbound connections
- Client-side temporary ports

**Port Ranges:**
- Linux: 32768-60999
- Windows: 49152-65535
- NAT Gateway: 1024-65535

**NACL Requirement:**
- Must allow ephemeral ports for return traffic
- Stateless nature requires explicit rules

### Security Group vs NACL

| Feature | Security Group | NACL |
|---------|----------------|------|
| Level | Instance | Subnet |
| State | Stateful | Stateless |
| Rules | Allow only | Allow & Deny |
| Processing | All rules | Numbered order |
| Return Traffic | Automatic | Manual |
| Default | Deny inbound | Allow all |
| Use Case | Primary defense | Additional layer |

---

## Lecture 14: Default VPC

### Default VPC Characteristics

**Automatically Created:**
- One per region
- Created when AWS account is created
- CIDR: 172.31.0.0/16

**Components:**
- Internet Gateway (attached)
- Main route table (0.0.0.0/0 → IGW)
- Default security group
- Default NACL (allow all)
- Default DHCP option set

**Subnets:**
- One default subnet per AZ
- All are public subnets
- Auto-assign public IPv4 enabled
- CIDR: 172.31.0.0/20, 172.31.16.0/20, etc.

### Default VPC Benefits

**Quick Start:**
- Launch instances immediately
- No VPC configuration needed
- Internet access by default

**Use Cases:**
- Testing and development
- Learning AWS
- Quick prototypes
- Non-production workloads

### Default VPC Limitations

**Security:**
- All subnets are public
- Less control over network design
- Not suitable for production

**Customization:**
- Cannot change CIDR
- Limited subnet design
- Shared across all resources

### Best Practices

**Production:**
- Create custom VPC
- Design proper subnet architecture
- Implement security layers

**Default VPC:**
- Use for testing only
- Can be deleted and recreated
- Don't rely on for production

---

## Lecture 15: AWS Console UI Update

### UI Changes
- AWS Console interface updates
- New VPC creation wizard
- Improved navigation
- Enhanced visualization

### Key Updates
- Simplified VPC creation
- Resource map view
- Better subnet management
- Integrated security group editor

---

## Lecture 16-17: Hands On - Creating VPC with Public and Private Subnets

### Lab Objectives
- Create custom VPC
- Create public subnet
- Create private subnet
- Configure Internet Gateway
- Set up route tables
- Launch instances

### Steps Covered
1. VPC creation with CIDR
2. Subnet creation in multiple AZs
3. IGW attachment
4. Route table configuration
5. Security group setup
6. Instance launch and testing

---

## Lecture 18: NAT Gateway

### Purpose
- Enable private subnet instances to access internet
- Prevent inbound connections from internet
- Managed AWS service

### Characteristics

**Managed Service:**
- AWS handles availability
- Automatic scaling
- No maintenance required

**Performance:**
- Starts at 5 Gbps
- Scales up to 45 Gbps automatically
- Supports burst up to 100 Gbps

**Availability:**
- Deployed in specific AZ
- Redundant within AZ
- For HA, deploy in each AZ

### Requirements

**Prerequisites:**
- Must be in public subnet
- Requires Elastic IP
- Public subnet needs IGW route

**Configuration:**
- Create in public subnet
- Allocate Elastic IP
- Update private subnet route table

### Pricing
- Hourly charge (~$0.045/hour)
- Data processing charge (~$0.045/GB)
- Elastic IP (free when attached)

---

## Lecture 19: Hands On - Create NAT Gateway 

### Lab Steps
1. Allocate Elastic IP
2. Create NAT Gateway in public subnet
3. Update private subnet route table
4. Test internet access from private instance

---

## Lecture 20: NAT Gateway High Availability

### HA Architecture

**Single AZ (Not HA):**
```
AZ-A: NAT Gateway
AZ-B: Uses NAT in AZ-A (cross-AZ traffic)
```

**Multi-AZ (HA):**
```
AZ-A: NAT Gateway A → Private Subnet A
AZ-B: NAT Gateway B → Private Subnet B
```

### Implementation
1. Create NAT Gateway in each AZ
2. Create route table per AZ
3. Associate route table with private subnet in same AZ
4. Each AZ uses its own NAT Gateway

### Benefits
- No single point of failure
- No cross-AZ data transfer charges
- Better performance
- AZ independence

---

## Lecture 21: NAT Instance (EC2 based NAT)

### Overview
- EC2 instance configured as NAT
- Manual setup and management
- Legacy approach (NAT Gateway preferred)

### Configuration Steps
1. Launch EC2 in public subnet
2. Disable source/destination check
3. Configure security groups
4. Update route tables
5. Configure instance for NAT

### NAT Instance vs NAT Gateway

| Feature | NAT Instance | NAT Gateway |
|---------|--------------|-------------|
| Availability | Manual failover | Highly available |
| Bandwidth | Instance type dependent | Up to 45 Gbps |
| Maintenance | You manage | AWS manages |
| Cost | Instance cost | Per hour + data |
| Performance | Limited | High |
| Security Groups | Supported | Not supported |
| Bastion | Can be used | Cannot |
| Port Forwarding | Supported | Not supported |

### When to Use NAT Instance
- Need bastion host functionality
- Require port forwarding
- Very low traffic (cost savings)
- Need security group on NAT
- Legacy compatibility

---

## Lecture 22: Regional NAT Gateway (Re:invent 2025)

### New Feature
- Announced at AWS re:Invent 2025
- Regional scope (not AZ-specific)
- Automatic high availability

### Benefits
- Simplified HA setup
- No need for multiple NAT Gateways
- Automatic failover
- Reduced management overhead

### Considerations
- Pricing model
- Migration from existing NAT Gateways
- Regional vs AZ-specific use cases

---

## Lecture 23: Exam Essentials

### Key Exam Topics

**VPC Basics:**
- VPC is regional, subnets are AZ-specific
- CIDR planning and calculations
- 5 reserved IPs per subnet

**Routing:**
- Route table associations
- Longest prefix match
- Local routes cannot be deleted

**Internet Connectivity:**
- IGW for public subnets
- NAT Gateway for private subnets
- One IGW per VPC

**Security:**
- Security Groups: Stateful, allow only
- NACLs: Stateless, allow and deny
- Ephemeral ports for return traffic

**High Availability:**
- Multi-AZ deployment
- NAT Gateway per AZ
- Route tables per AZ

### Common Exam Scenarios

**Scenario 1: Instance cannot access internet**
- Check: IGW, route table, public IP, SG, NACL

**Scenario 2: Private instance needs internet**
- Solution: NAT Gateway in public subnet

**Scenario 3: HA for NAT**
- Solution: NAT Gateway in each AZ

**Scenario 4: Cost optimization**
- Consider: VPC Endpoints, NAT Instance for low traffic

---

## Quiz 2: VPC Fundamentals

### Practice Questions

**Q1: What is the maximum size of a VPC CIDR block?**
- A) /8
- B) /16
- C) /24
- D) /28

**Answer: B) /16**

**Q2: How many IP addresses are reserved by AWS in each subnet?**
- A) 3
- B) 4
- C) 5
- D) 6

**Answer: C) 5**

**Q3: Which is true about Security Groups?**
- A) Stateless
- B) Subnet level
- C) Supports deny rules
- D) Stateful

**Answer: D) Stateful**

**Q4: For HA, where should NAT Gateways be deployed?**
- A) One per region
- B) One per VPC
- C) One per AZ
- D) One per subnet

**Answer: C) One per AZ**

---

