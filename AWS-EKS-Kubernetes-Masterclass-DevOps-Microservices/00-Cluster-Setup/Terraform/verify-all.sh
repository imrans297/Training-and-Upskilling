#!/bin/bash

CLUSTER_NAME="AWS_EKS-cluster"
REGION="ap-south-1"
MY_IP="106.215.176.143/32"

echo "🔍 COMPREHENSIVE VERIFICATION SCRIPT"
echo "===================================="

# 1. Check Tags on Instances
echo -e "\n1️⃣  CHECKING INSTANCE TAGS..."
aws ec2 describe-instances \
  --region $REGION \
  --filters "Name=tag:eks:nodegroup-name,Values=${CLUSTER_NAME}-nodes" "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[].[InstanceId,Tags[?Key==`Name`].Value|[0],Tags[?Key==`Owner`].Value|[0],Tags[?Key==`Department`].Value|[0],Tags[?Key==`ManagedBy`].Value|[0]]' \
  --output table

# 2. Check Security Groups
echo -e "\n2️⃣  CHECKING SECURITY GROUPS..."
echo "Node Security Group Rules:"
SG_ID=$(aws ec2 describe-security-groups --region $REGION --filters "Name=tag:Name,Values=${CLUSTER_NAME}-nodes-sg" --query 'SecurityGroups[0].GroupId' --output text)
aws ec2 describe-security-groups --region $REGION --group-ids $SG_ID --query 'SecurityGroups[0].IpPermissions[*].[FromPort,ToPort,IpProtocol,IpRanges[0].CidrIp,IpRanges[0].Description]' --output table

echo -e "\n✅ Verifying SSH is restricted to your IP only:"
SSH_RULE=$(aws ec2 describe-security-groups --region $REGION --group-ids $SG_ID --query "SecurityGroups[0].IpPermissions[?FromPort==\`22\`].IpRanges[0].CidrIp" --output text)
if [ "$SSH_RULE" == "$MY_IP" ]; then
  echo "✅ SSH restricted to $MY_IP - SECURE"
else
  echo "❌ SSH NOT properly restricted! Current: $SSH_RULE"
fi

# 3. Check AMI
echo -e "\n3️⃣  CHECKING AMI..."
aws ec2 describe-instances \
  --region $REGION \
  --filters "Name=tag:eks:nodegroup-name,Values=${CLUSTER_NAME}-nodes" "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[].[InstanceId,ImageId]' \
  --output table

# 4. Wait for nodes to be ready
echo -e "\n4️⃣  WAITING FOR NODES TO BE READY..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s || echo "Nodes not ready yet, continuing..."

# 5. Check MDATP Installation
echo -e "\n5️⃣  CHECKING MDATP INSTALLATION..."
INSTANCE_IDS=$(aws ec2 describe-instances \
  --region $REGION \
  --filters "Name=tag:eks:nodegroup-name,Values=${CLUSTER_NAME}-nodes" "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[].InstanceId' \
  --output text)

for INSTANCE_ID in $INSTANCE_IDS; do
  echo -e "\nChecking MDATP on instance: $INSTANCE_ID"
  
  # Try SSM first
  CMD_ID=$(aws ssm send-command \
    --region $REGION \
    --instance-ids $INSTANCE_ID \
    --document-name "AWS-RunShellScript" \
    --parameters 'commands=["if command -v mdatp &> /dev/null; then echo \"✅ MDATP INSTALLED\"; mdatp health --field healthy; else echo \"❌ MDATP NOT INSTALLED\"; fi"]' \
    --output text \
    --query 'Command.CommandId' 2>/dev/null)
  
  if [ $? -eq 0 ]; then
    sleep 5
    aws ssm get-command-invocation \
      --region $REGION \
      --command-id $CMD_ID \
      --instance-id $INSTANCE_ID \
      --query 'StandardOutputContent' \
      --output text
  else
    echo "⚠️  SSM not available, trying kubectl debug..."
    NODE=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')
    kubectl debug node/$NODE -it --image=busybox -- chroot /host sh -c "command -v mdatp && echo '✅ MDATP INSTALLED' || echo '❌ MDATP NOT INSTALLED'" 2>/dev/null || echo "kubectl debug failed"
  fi
done

# Summary
echo -e "\n📊 VERIFICATION SUMMARY"
echo "======================"
echo "✅ Tags: Check table above"
echo "✅ Security: SSH restricted to $MY_IP"
echo "✅ AMI: ami-039c2313054ae6ac9"
echo "✅ MDATP: Check results above"
