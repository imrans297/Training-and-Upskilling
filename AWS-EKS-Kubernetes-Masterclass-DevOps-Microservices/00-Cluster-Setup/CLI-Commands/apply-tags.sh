#!/bin/bash

CLUSTER_NAME="eksdemo1-imran"
REGION="ap-south-1"

echo "🏷️  Applying tags to cluster resources..."

# Tag EKS Cluster
echo "Tagging EKS cluster..."
aws eks tag-resource --resource-arn $(aws eks describe-cluster --name $CLUSTER_NAME --region $REGION --query 'cluster.arn' --output text) --tags Owner=imran.shaikh@einfochips.com,Project=InternalPOC,DM=ShahidRaza,Department=PES-Digital,Environment=training,ENDDate=30-11-2025,ManagedBy=eksctl --region $REGION
echo "✅ Tagged EKS cluster"

# Tag Node Group
echo "Tagging node group..."
for NG in $(aws eks list-nodegroups --cluster-name $CLUSTER_NAME --region $REGION --query 'nodegroups' --output text); do
  aws eks tag-resource --resource-arn $(aws eks describe-nodegroup --cluster-name $CLUSTER_NAME --nodegroup-name $NG --region $REGION --query 'nodegroup.nodegroupArn' --output text) --tags Owner=imran.shaikh@einfochips.com,Department=PES-Digital,Environment=training,ENDDate=30-11-2025 --region $REGION
  echo "✅ Tagged node group: $NG"
done

# Tag EC2 Instances
for INSTANCE in $(aws ec2 describe-instances --region $REGION --filters "Name=tag:eks:cluster-name,Values=$CLUSTER_NAME" "Name=instance-state-name,Values=running" --query 'Reservations[*].Instances[*].InstanceId' --output text); do
  aws ec2 create-tags --resources $INSTANCE --tags Key=Owner,Value=imran.shaikh@einfochips.com Key=Project,Value=InternalPOC Key=DM,Value=ShahidRaza Key=Department,Value=PES-Digital Key=Environment,Value=training Key=ENDDate,Value=30-11-2025 Key=ManagedBy,Value=eksctl --region $REGION
  echo "✅ Tagged instance: $INSTANCE"
done

# Tag EBS Volumes
for VOLUME in $(aws ec2 describe-volumes --region $REGION --filters "Name=tag:eks:cluster-name,Values=$CLUSTER_NAME" --query 'Volumes[*].VolumeId' --output text); do
  aws ec2 create-tags --resources $VOLUME --tags Key=Owner,Value=imran.shaikh@einfochips.com Key=Department,Value=PES-Digital Key=Environment,Value=training Key=ENDDate,Value=30-11-2025 --region $REGION
  echo "✅ Tagged volume: $VOLUME"
done

# Tag Security Groups
for SG in $(aws ec2 describe-security-groups --region $REGION --filters "Name=tag:eks:cluster-name,Values=$CLUSTER_NAME" --query 'SecurityGroups[*].GroupId' --output text); do
  aws ec2 create-tags --resources $SG --tags Key=Owner,Value=imran.shaikh@einfochips.com Key=Department,Value=PES-Digital Key=Environment,Value=training --region $REGION
  echo "✅ Tagged security group: $SG"
# done

# # Tag VPC
# VPC_ID=$(aws eks describe-cluster --name $CLUSTER_NAME --region $REGION --query 'cluster.resourcesVpcConfig.vpcId' --output text)
# aws ec2 create-tags --resources $VPC_ID --tags Key=Owner,Value=imran.shaikh@einfochips.com Key=Department,Value=PES-Digital Key=ManagedBy,Value=eksctl --region $REGION 2>/dev/null
# echo "✅ Tagged VPC: $VPC_ID"

# # Tag Subnets
# for SUBNET in $(aws eks describe-cluster --name $CLUSTER_NAME --region $REGION --query 'cluster.resourcesVpcConfig.subnetIds' --output text); do
#   aws ec2 create-tags --resources $SUBNET --tags Key=Owner,Value=imran.shaikh@einfochips.com Key=Department,Value=PES-Digital --region $REGION
#   echo "✅ Tagged subnet: $SUBNET"
done

# Tag Cluster Security Group
CLUSTER_SG=$(aws eks describe-cluster --name $CLUSTER_NAME --region $REGION --query 'cluster.resourcesVpcConfig.clusterSecurityGroupId' --output text)
aws ec2 create-tags --resources $CLUSTER_SG --tags Key=Owner,Value=imran.shaikh@einfochips.com Key=Department,Value=PES-Digital Key=Environment,Value=training --region $REGION
echo "✅ Tagged cluster security group: $CLUSTER_SG"

echo "✅ All tags applied!"
