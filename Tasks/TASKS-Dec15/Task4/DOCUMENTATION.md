# Task 4: Production-Ready EKS Cluster with Private Nodes + Public ALB

**Purpose:** Deploy EKS cluster with private worker nodes and public Application Load Balancer

## Architecture Overview

This implementation creates a production-ready EKS cluster with the following architecture:

- **VPC**: Custom VPC (10.0.0.0/16) with DNS support
- **Public Subnets**: For ALB only (10.0.1.0/24, 10.0.2.0/24)
- **Private Subnets**: For EKS worker nodes (10.0.10.0/24, 10.0.11.0/24)
- **Pod Subnets**: For VPC CNI custom networking (10.0.50.0/24, 10.0.51.0/24)
- **NAT Gateway**: Provides internet access for private subnets
- **EKS Cluster**: Kubernetes 1.28 with private endpoint access
- **Worker Nodes**: t3.medium instances with no public IPs
- **VPC CNI Custom Networking**: Pods use separate subnets from nodes
- **ALB Ingress Controller**: Manages Application Load Balancer
- **NGINX App**: Sample application with Ingress

**📋 Detailed Architecture:** See [ARCHITECTURE.md](ARCHITECTURE.md) for complete diagram and component details

## Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform >= 1.0 installed
- kubectl installed
- Existing EC2 key pair (jayimrankey)

## Implementation Steps

### Step 1: Initialize Terraform

```bash
cd /home/einfochips/TrainingPlanNew/Tasks/TASKS-Dec15/Task4
terraform init
```

![Terraform Init](screenshots/02-terraform-init.png)

### Step 2: Review Terraform Plan

```bash
terraform plan
```

![Terraform Plan](screenshots/03-terraform-plan.png)

### Step 3: Deploy Infrastructure

```bash
terraform apply -auto-approve
```

![Terraform Apply](screenshots/04-terraform-apply.png)

### Step 4: Verify VPC Creation

Navigate to AWS Console → VPC → Your VPCs

![VPC Creation](screenshots/05-vpc-created.png)

### Step 5: Verify Subnets Configuration

Check public and private subnets with proper tags

![Subnets Configuration](screenshots/06-all-subnets-config.png)

Public Subnet:
![Subnets Configuration](screenshots/06-Public-subnets-config.png)

Private Subnet:
![Subnets Configuration](screenshots/06-Private-subnets-config.png)

Pod Subnet:
![Subnets Configuration](screenshots/06-Pod-subnets-config.png)

### Step 6: Verify NAT Gateway

Confirm NAT Gateway is created in public subnet

![NAT Gateway](screenshots/07-nat-gateway.png)

### Step 7: Verify EKS Cluster

Navigate to AWS Console → EKS → Clusters

![EKS Cluster](screenshots/08-eks-cluster.png)

### Step 8: Verify Node Groups

Check worker nodes are in private subnets with no public IPs

![Node Groups](screenshots/09-node-groups.png)

### Step 9: Configure kubectl
Update kubeconfig to connect to EKS cluster:

```bash
aws eks update-kubeconfig --region us-east-1 --name imran-eks-cluster
```

![kubectl Setup](screenshots/10-kubectl-setup.png)

### Step 10: Verify Cluster Access

```bash
kubectl get nodes
kubectl get pods -A
```

![Cluster Access](screenshots/11-cluster-access.png)

### Step 11: Create IAM Policy for ALB Controller

Download and create the official AWS Load Balancer Controller IAM policy:

```bash
# Download official IAM policy
curl -o iam_policy.json \
https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json

# Create IAM policy
aws iam create-policy \
  --policy-name AWSLoadBalancerControllerIAMPolicy \
  --policy-document file://iam_policy.json
```

![IAM Policy Creation](screenshots/11-iam-policy-creation.png)

### Step 12: Create IAM Service Account

Create IAM service account with proper permissions:

```bash
# Create service account with IAM role
eksctl create iamserviceaccount \
  --cluster=imran-eks-cluster \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=arn:aws:iam::860839673297:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve --override-existing-serviceaccounts
```

![Service Account Creation](screenshots/12-service-account-creation.png)

### Step 13: Install AWS Load Balancer Controller

Install AWS Load Balancer Controller using Helm:

```bash
# Add EKS chart repo
helm repo add eks https://aws.github.io/eks-charts
helm repo update

# Install ALB controller
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=imran-eks-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

![ALB Controller Installation](screenshots/13-alb-controller-install.png)

### Step 14: Verify ALB Controller

Verify ALB controller is running:

```bash
kubectl get pods -n kube-system | grep aws-load-balancer
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

![ALB Controller Verification](screenshots/13-alb-controller-verify.png)

### Step 15: Deploy NGINX Application

```bash
kubectl apply -f manifests/nginx-deployment.yaml
```

![NGINX Deployment](screenshots/15-nginx-deployment.png)

### Step 16: Deploy NGINX Ingress

```bash
kubectl apply -f manifests/nginx-ingress.yaml
```

![NGINX Ingress](screenshots/15-nginx-ingress.png)

### Step 17: Verify ALB Creation

Navigate to AWS Console → EC2 → Load Balancers

![ALB Creation](screenshots/16-alb-creation.png)

### Step 18: Get ALB DNS Name

```bash
kubectl get ingress nginx-ingress
```

![ALB DNS Name](screenshots/15-nginx-ingress.png)

### Step 19: Test Application Access

Access the application using ALB DNS name in browser

![Application Access](screenshots/18-application-access.png)

### Step 20: Verify Private Node IPs

Confirm worker nodes have only private IPs

```bash
kubectl get nodes -o wide
```

![Private Node IPs](screenshots/21-private-node-ips.png)

### Step 21: Verify Network Flow

Check that traffic flows: Internet → ALB → Private Nodes

![Network Flow](screenshots/20-network-flow.png)

### Step 22: Test Scaling

Scale NGINX deployment to verify load balancing

```bash
kubectl scale deployment nginx-app --replicas=5
```

![Scaling Test](screenshots/23-scaling-test.png)

### Step 23: Verify Target Groups

Check ALB target groups in AWS Console

![Target Groups](screenshots/22-target-groups.png)

### Step 24: Security Group Verification

Verify security groups allow proper traffic flow

![Security Groups](screenshots/25-security-groups.png)

### Step 25: Enable VPC CNI Custom Networking

Configure VPC CNI to use separate subnets for pods:

```bash
# Enable custom networking
kubectl set env daemonset aws-node -n kube-system AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG=true

# Set ENI config annotation
kubectl set env daemonset aws-node -n kube-system ENI_CONFIG_ANNOTATION_DEF=k8s.amazonaws.com/eniConfig
```

![Enable Custom Networking](screenshots/25-enable-custom-networking.png)

### Step 26: Create Pod Subnets

Add dedicated subnets for pod networking (already created via Terraform):

- **Pod Subnet 1**: `10.0.50.0/24` (us-east-1a)
- **Pod Subnet 2**: `10.0.51.0/24` (us-east-1b)

![Pod Subnets](screenshots/26-pod-subnets.png)

### Step 27: Create ENIConfig Resources

Create ENIConfig for each availability zone:

```bash
# Create ENIConfig manifest
cat > eniconfig.yaml << EOF
apiVersion: crd.k8s.amazonaws.com/v1alpha1
kind: ENIConfig
metadata:
  name: us-east-1a
spec:
  securityGroups:
    - sg-00c8ad24f8fbc68f5
  subnet: subnet-03d87302afd04ff8a
---
apiVersion: crd.k8s.amazonaws.com/v1alpha1
kind: ENIConfig
metadata:
  name: us-east-1b
spec:
  securityGroups:
    - sg-00c8ad24f8fbc68f5
  subnet: subnet-0d99325a7d23ef369
EOF

# Apply ENIConfig
kubectl apply -f eniconfig.yaml
```

![ENIConfig Creation](screenshots/27-eniconfig-creation.png)

### Step 28: Annotate Nodes for Custom Networking

Annotate nodes to use ENIConfig based on their availability zone:

```bash
# Annotate nodes with ENIConfig
kubectl annotate node --all k8s.amazonaws.com/eniConfig=us-east-1b --overwrite

# Restart aws-node daemonset
kubectl rollout restart daemonset/aws-node -n kube-system
```

![Node Annotation](screenshots/28-node-annotation.png)

### Step 29: Verify Custom Networking

Confirm pods get IPs from pod subnets (10.0.50.x/10.0.51.x):

```bash
# Check pod IPs after custom networking
kubectl get pods -o wide

# Verify VPC CNI configuration
kubectl get daemonset aws-node -n kube-system -o yaml | grep -A 5 "AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG"
```

![Custom Networking Verification](screenshots/29-custom-networking-verification.png)


## Key Achievements

 **EKS cluster deployed in private subnets only**  
 **Public subnets dedicated for ALB**  
 **Worker nodes have no public IP addresses**  
 **ALB Ingress Controller successfully installed**  
 **NGINX application accessible only through ALB**  
 **VPC CNI custom networking enabled with separate pod subnets**  
 **Pod IPs from dedicated subnets (10.0.50.x/10.0.51.x)**  
 **Node IPs from worker subnets (10.0.10.x/10.0.11.x)**  
 **Production-ready security configuration**

## Resource Summary

| Resource Type | Count | Purpose |
|---------------|-------|---------|
| VPC | 1 | Network isolation |
| Public Subnets | 2 | ALB placement |
| Private Subnets | 2 | EKS worker nodes |
| Pod Subnets | 2 | Custom networking for pods |
| NAT Gateway | 1 | Internet access for private subnets |
| EKS Cluster | 1 | Kubernetes control plane |
| Node Group | 1 | Worker nodes (1-4 instances) |
| ALB | 1 | Application load balancer |
| ENIConfig | 2 | Custom networking configuration |
| Security Groups | 1 | Network security |


### Useful Commands:

```bash
# Check cluster status
kubectl cluster-info

# View ALB controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# Check node status
kubectl describe nodes

# View ingress details
kubectl describe ingress nginx
```
![BasicInfo](screenshots/28-info-commands.png)

![BasicInfo](screenshots/28-info-commands-1.png)

![BasicInfo](screenshots/28-info-describe-ingress-1.png)

---

**Note**: This implementation demonstrates production-ready EKS deployment with proper network segmentation and security best practices. All worker nodes remain private while maintaining internet connectivity through NAT Gateway and external access through Application Load Balancer.