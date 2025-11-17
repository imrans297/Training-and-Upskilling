# Lab 2: EKS Cluster with Multiple Node Groups

## Purpose
Learn to create EKS cluster with multiple node groups for different workload types.

## What We're Going to Perform
- Create cluster with configuration file
- Add multiple node groups (on-demand and spot)
- Configure node labels and taints
- Deploy workloads to specific node groups

## What is Required
- Completed Lab 1
- Understanding of node groups
- Basic YAML knowledge

## What We'll Achieve
- Cluster with multiple node groups
- Cost optimization with spot instances
- Workload segregation
- Advanced eksctl configuration

## Step-by-Step Commands

### Step 1: Create Cluster Configuration File

```bash
# Create cluster-config.yaml
cat > cluster-config.yaml << 'EOF'
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: multi-nodegroup-cluster
  region: us-east-1
  version: "1.28"

managedNodeGroups:
  - name: general-workload
    instanceType: t3.medium
    minSize: 2
    maxSize: 4
    desiredCapacity: 2
    labels:
      role: general
    tags:
      nodegroup-type: general

  - name: spot-workload
    instanceTypes: ["t3.medium", "t3a.medium"]
    minSize: 1
    maxSize: 3
    desiredCapacity: 1
    spot: true
    labels:
      role: spot
    taints:
      - key: spot
        value: "true"
        effect: NoSchedule
    tags:
      nodegroup-type: spot
EOF
```

**What this does**: Creates configuration file defining two node groups - one on-demand and one spot.

### Step 2: Create Cluster
```bash
# Create cluster from config file
eksctl create cluster -f cluster-config.yaml

# This takes 15-20 minutes
```

**What this does**: Creates cluster with both node groups simultaneously.

### Step 3: Verify Node Groups
```bash
# List node groups
eksctl get nodegroup --cluster multi-nodegroup-cluster

# Check nodes with labels
kubectl get nodes --show-labels

# Filter by node group
kubectl get nodes -l role=general
kubectl get nodes -l role=spot
```

**What this does**: Confirms both node groups are created with correct labels.

### Step 4: Deploy to General Node Group

```bash
# Create deployment for general nodes
cat > general-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-general
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx-general
  template:
    metadata:
      labels:
        app: nginx-general
    spec:
      nodeSelector:
        role: general
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
EOF

# Apply deployment
kubectl apply -f general-deployment.yaml

# Verify pods are on general nodes
kubectl get pods -o wide
```

**What this does**: Deploys application specifically to general (on-demand) nodes.

### Step 5: Deploy to Spot Node Group

```bash
# Create deployment for spot nodes
cat > spot-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: batch-job
spec:
  replicas: 1
  selector:
    matchLabels:
      app: batch-job
  template:
    metadata:
      labels:
        app: batch-job
    spec:
      nodeSelector:
        role: spot
      tolerations:
      - key: spot
        operator: Equal
        value: "true"
        effect: NoSchedule
      containers:
      - name: busybox
        image: busybox
        command: ["sh", "-c", "while true; do echo 'Processing...'; sleep 30; done"]
EOF

# Apply deployment
kubectl apply -f spot-deployment.yaml

# Verify pods are on spot nodes
kubectl get pods -o wide
```

**What this does**: Deploys batch workload to spot instances with toleration for taint.

### Step 6: Scale Node Groups
```bash
# Scale general node group
eksctl scale nodegroup \
  --cluster multi-nodegroup-cluster \
  --name general-workload \
  --nodes 3

# Verify scaling
kubectl get nodes -l role=general

# Scale spot node group
eksctl scale nodegroup \
  --cluster multi-nodegroup-cluster \
  --name spot-workload \
  --nodes 2

# Verify
kubectl get nodes -l role=spot
```

**What this does**: Demonstrates dynamic scaling of node groups.

### Step 7: View Node Group Details
```bash
# Get detailed node group info
eksctl get nodegroup \
  --cluster multi-nodegroup-cluster \
  --name general-workload

# Check Auto Scaling Group
aws autoscaling describe-auto-scaling-groups \
  --query "AutoScalingGroups[?contains(Tags[?Key=='eks:nodegroup-name'].Value, 'general-workload')]"
```

**What this does**: Shows node group configuration and AWS Auto Scaling Group details.

## Cleanup Commands

```bash
# Delete deployments
kubectl delete -f general-deployment.yaml
kubectl delete -f spot-deployment.yaml

# Delete cluster (deletes all node groups)
eksctl delete cluster --name multi-nodegroup-cluster --region us-east-1

# Verify deletion
eksctl get cluster --region us-east-1
```

**What this does**: Removes all resources cleanly.

## Verification Checklist
- [ ] Cluster created with 2 node groups
- [ ] General nodes are on-demand instances
- [ ] Spot nodes are spot instances
- [ ] Labels applied correctly
- [ ] Taints working on spot nodes
- [ ] Deployments scheduled to correct nodes
- [ ] Scaling works for both node groups

## Cost Comparison

**On-Demand (t3.medium)**:
- 2 nodes × $0.0416/hour = $0.0832/hour
- Monthly: ~$60

**Spot (t3.medium)**:
- 1 node × ~$0.0125/hour = $0.0125/hour
- Monthly: ~$9
- Savings: ~85%

## What You Learned
- Creating multiple node groups
- Using spot instances for cost savings
- Node selectors and taints/tolerations
- Workload segregation strategies
- Scaling individual node groups
- eksctl configuration files
