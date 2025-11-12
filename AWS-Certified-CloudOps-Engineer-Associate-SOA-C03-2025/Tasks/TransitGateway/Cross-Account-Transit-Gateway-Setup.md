# 🌐 Cross-Account Transit Gateway Setup

## **Account Details**
- **Your Account**: `535537926657` (Owner/Sharer)
- **Friend's Account**: `375039967967` (Peer/Accepter)

---

## **Step 1: Create Transit Gateway (Your Account)**

### **Script: create-transit-gateway.sh**
```bash
#!/bin/bash

# Create Transit Gateway in your account (535537926657)
TGW_ID=$(aws ec2 create-transit-gateway \
  --description "Cross-account Transit Gateway" \
  --options DefaultRouteTableAssociation=enable,DefaultRouteTablePropagation=enable \
  --tag-specifications 'ResourceType=transit-gateway,Tags=[{Key=Name,Value=CrossAccount-TGW}]' \
  --query 'TransitGateway.TransitGatewayId' --output text)

echo "Transit Gateway created: $TGW_ID"

# Create VPC and attach to TGW
VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query 'Vpc.VpcId' --output text)
aws ec2 create-tags --resources $VPC_ID --tags Key=Name,Value=TGW-VPC

# Create subnet
SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.1.0/24 --query 'Subnet.SubnetId' --output text)

# Attach VPC to TGW
TGW_ATTACHMENT_ID=$(aws ec2 create-transit-gateway-vpc-attachment \
  --transit-gateway-id $TGW_ID \
  --vpc-id $VPC_ID \
  --subnet-ids $SUBNET_ID \
  --query 'TransitGatewayVpcAttachment.TransitGatewayAttachmentId' --output text)

echo "VPC attached to TGW: $TGW_ATTACHMENT_ID"
echo "TGW ID: $TGW_ID"
```

---

## **Step 2: Share Transit Gateway (Your Account)**

### **Script: share-transit-gateway.sh**
```bash
#!/bin/bash

TGW_ID=$1
PEER_ACCOUNT_ID="375039967967"

if [ -z "$TGW_ID" ]; then
    echo "Usage: $0 <transit-gateway-id>"
    exit 1
fi

# Share Transit Gateway with peer account using Resource Access Manager
RESOURCE_SHARE_ARN=$(aws ram create-resource-share \
  --name "TGW-CrossAccount-Share" \
  --resource-arns "arn:aws:ec2:us-east-1:535537926657:transit-gateway/$TGW_ID" \
  --principals $PEER_ACCOUNT_ID \
  --query 'resourceShare.resourceShareArn' --output text)

echo "Transit Gateway shared: $RESOURCE_SHARE_ARN"
echo "Peer account ($PEER_ACCOUNT_ID) can now accept the share"
```

---

## **Step 3: Accept Share (Friend's Account)**

### **Script: accept-tgw-share.sh**
```bash
#!/bin/bash

# Accept Transit Gateway share in peer account (375039967967)
# Get pending resource share invitations
INVITATION_ARN=$(aws ram get-resource-share-invitations \
  --resource-share-arns \
  --query 'resourceShareInvitations[?status==`PENDING`].resourceShareInvitationArn' \
  --output text)

if [ -n "$INVITATION_ARN" ]; then
    # Accept the invitation
    aws ram accept-resource-share-invitation \
      --resource-share-invitation-arn $INVITATION_ARN
    
    echo "Transit Gateway share accepted"
else
    echo "No pending invitations found"
fi
```

---

## **Step 4: Attach Peer VPC (Friend's Account)**

### **Script: attach-peer-vpc-to-tgw.sh**
```bash
#!/bin/bash

# Run in peer account (375039967967) after accepting share
TGW_ID=$1

if [ -z "$TGW_ID" ]; then
    echo "Usage: $0 <shared-transit-gateway-id>"
    exit 1
fi

# Create VPC in peer account
PEER_VPC_ID=$(aws ec2 create-vpc --cidr-block 10.1.0.0/16 --query 'Vpc.VpcId' --output text)
aws ec2 create-tags --resources $PEER_VPC_ID --tags Key=Name,Value=Peer-TGW-VPC

# Create subnet
PEER_SUBNET_ID=$(aws ec2 create-subnet --vpc-id $PEER_VPC_ID --cidr-block 10.1.1.0/24 --query 'Subnet.SubnetId' --output text)

# Attach peer VPC to shared TGW
PEER_ATTACHMENT_ID=$(aws ec2 create-transit-gateway-vpc-attachment \
  --transit-gateway-id $TGW_ID \
  --vpc-id $PEER_VPC_ID \
  --subnet-ids $PEER_SUBNET_ID \
  --query 'TransitGatewayVpcAttachment.TransitGatewayAttachmentId' --output text)

echo "Peer VPC attached to shared TGW: $PEER_ATTACHMENT_ID"
```

---

## **Step 5: Configure Routes (Your Account)**

### **Script: configure-tgw-routes.sh**
```bash
#!/bin/bash

TGW_ID=$1

if [ -z "$TGW_ID" ]; then
    echo "Usage: $0 <transit-gateway-id>"
    exit 1
fi

# Get TGW route table ID
TGW_RT_ID=$(aws ec2 describe-transit-gateways \
  --transit-gateway-ids $TGW_ID \
  --query 'TransitGateways[0].Options.DefaultRouteTableId' --output text)

# Get VPC route tables and add TGW routes
VPC_RT_ID=$(aws ec2 describe-route-tables \
  --filters "Name=tag:Name,Values=TGW-VPC" \
  --query 'RouteTables[0].RouteTableId' --output text)

# Add route to peer VPC CIDR
aws ec2 create-route \
  --route-table-id $VPC_RT_ID \
  --destination-cidr-block 10.1.0.0/16 \
  --transit-gateway-id $TGW_ID

echo "Routes configured for cross-account connectivity"
```

---

## **Execution Order**

### **In Your Account (535537926657):**
```bash
# Step 1: Create TGW
./create-transit-gateway.sh

# Step 2: Share TGW (use TGW ID from step 1)
./share-transit-gateway.sh tgw-xxxxxxxxx
```

### **In Friend's Account (375039967967):**
```bash
# Step 3: Accept share
./accept-tgw-share.sh

# Step 4: Attach VPC (use same TGW ID)
./attach-peer-vpc-to-tgw.sh tgw-xxxxxxxxx
```

### **Back in Your Account:**
```bash
# Step 5: Configure routing
./configure-tgw-routes.sh tgw-xxxxxxxxx
```

---

## **Network Architecture**

```
Account 535537926657          Account 375039967967
┌─────────────────┐          ┌─────────────────┐
│   VPC-1         │          │   VPC-2         │
│   10.0.0.0/16   │          │   10.1.0.0/16   │
│                 │          │                 │
│   ┌─────────┐   │          │   ┌─────────┐   │
│   │Subnet   │   │          │   │Subnet   │   │
│   │10.0.1.0/│   │          │   │10.1.1.0/│   │
│   │24       │   │          │   │24       │   │
│   └─────────┘   │          │   └─────────┘   │
└─────────────────┘          └─────────────────┘
         │                            │
         └──────────┬───────────────────┘
                    │
            ┌───────────────┐
            │ Transit       │
            │ Gateway       │
            │ (Shared)      │
            └───────────────┘
```

---

## **Verification Commands**

### **Check TGW Status:**
```bash
aws ec2 describe-transit-gateways --transit-gateway-ids tgw-xxxxxxxxx
```

### **Check Attachments:**
```bash
aws ec2 describe-transit-gateway-vpc-attachments --filters "Name=transit-gateway-id,Values=tgw-xxxxxxxxx"
```

### **Check Resource Shares:**
```bash
aws ram get-resource-shares --resource-owner SELF
```

### **Test Connectivity:**
```bash
# From instance in VPC-1 to VPC-2
ping 10.1.1.x
```

---

## **Cleanup**

### **Delete Attachments:**
```bash
aws ec2 delete-transit-gateway-vpc-attachment --transit-gateway-attachment-id tgw-attach-xxxxxxxxx
```

### **Delete Resource Share:**
```bash
aws ram delete-resource-share --resource-share-arn arn:aws:ram:us-east-1:535537926657:resource-share/xxxxxxxxx
```

### **Delete Transit Gateway:**
```bash
aws ec2 delete-transit-gateway --transit-gateway-id tgw-xxxxxxxxx
```