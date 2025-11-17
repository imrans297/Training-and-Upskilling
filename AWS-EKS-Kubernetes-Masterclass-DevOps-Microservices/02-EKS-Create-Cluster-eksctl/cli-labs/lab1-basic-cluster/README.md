# Lab 1: Create Basic EKS Cluster with eksctl

## Purpose
Learn to create a simple EKS cluster using eksctl CLI tool.

## What We're Going to Perform
- Install eksctl tool
- Create a basic 2-node EKS cluster
- Configure kubectl access
- Deploy a test application

## What is Required
- AWS CLI configured
- kubectl installed
- eksctl installed

## What We'll Achieve
- Working EKS cluster
- kubectl configured
- Understanding of eksctl commands

## Step-by-Step Commands

### Step 1: Install eksctl
```bash
# Download eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp

# Move to bin
sudo mv /tmp/eksctl /usr/local/bin

# Verify installation
eksctl version
# Output: 0.150.0
```

**What this does**: Downloads and installs eksctl CLI tool for managing EKS clusters.

### Step 2: Create Cluster
```bash
# Create cluster with minimal configuration
eksctl create cluster \
  --name my-basic-cluster \
  --region us-east-1 \
  --nodes 2 \
  --node-type t3.medium \
  --managed

# Wait 15-20 minutes for completion
```

**What this does**:
- Creates VPC with subnets
- Launches EKS control plane
- Creates 2 managed worker nodes
- Configures kubectl automatically

### Step 3: Verify Cluster
```bash
# Check cluster status
eksctl get cluster --name my-basic-cluster --region us-east-1

# Verify nodes
kubectl get nodes

# Expected output:
# NAME                         STATUS   ROLES    AGE   VERSION
# ip-192-168-1-10.ec2.internal Ready    <none>   5m    v1.28.0
# ip-192-168-2-20.ec2.internal Ready    <none>   5m    v1.28.0
```

**What this does**: Confirms cluster is running and nodes are ready.

### Step 4: Deploy Test Application
```bash
# Create nginx deployment
kubectl create deployment nginx --image=nginx:latest

# Verify deployment
kubectl get deployments

# Check pods
kubectl get pods

# Expected output:
# NAME                     READY   STATUS    RESTARTS   AGE
# nginx-7854ff8877-xxxxx   1/1     Running   0          30s
```

**What this does**: Deploys a simple nginx web server to test cluster functionality.

### Step 5: Expose Application
```bash
# Create LoadBalancer service
kubectl expose deployment nginx --port=80 --type=LoadBalancer

# Get service details
kubectl get svc nginx

# Wait for EXTERNAL-IP (2-3 minutes)
kubectl get svc nginx -w
```

**What this does**: Creates AWS LoadBalancer to expose nginx externally.

### Step 6: Test Application
```bash
# Get LoadBalancer URL
export LB_URL=$(kubectl get svc nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Test application
curl http://$LB_URL

# Expected: Nginx welcome page HTML
```

**What this does**: Verifies application is accessible from internet.

### Step 7: View Cluster Info
```bash
# Get cluster details
kubectl cluster-info

# View all resources
kubectl get all --all-namespaces

# Check node details
kubectl describe nodes
```

**What this does**: Shows comprehensive cluster information.

## Cleanup Commands

```bash
# Delete test application
kubectl delete deployment nginx
kubectl delete service nginx

# Wait for LoadBalancer to be deleted (check AWS console)
# This is important to avoid orphaned resources

# Delete cluster
eksctl delete cluster --name my-basic-cluster --region us-east-1

# This will take 10-15 minutes
```

**What this does**: Removes all resources to avoid charges.

## Verification Checklist
- [ ] eksctl installed successfully
- [ ] Cluster created without errors
- [ ] 2 nodes in Ready state
- [ ] nginx deployment running
- [ ] LoadBalancer service accessible
- [ ] Application responds to curl

## Common Issues

**Issue**: Cluster creation fails
```bash
# Check AWS credentials
aws sts get-caller-identity

# Check CloudFormation stacks
aws cloudformation list-stacks --region us-east-1
```

**Issue**: kubectl cannot connect
```bash
# Update kubeconfig
eksctl utils write-kubeconfig --cluster my-basic-cluster --region us-east-1

# Verify config
kubectl config current-context
```

## What You Learned
- How to install and use eksctl
- Creating EKS clusters with simple commands
- Basic kubectl operations
- Deploying and exposing applications
- Proper cleanup procedures
