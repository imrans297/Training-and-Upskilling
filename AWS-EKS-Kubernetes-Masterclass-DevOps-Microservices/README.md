# AWS EKS Kubernetes Masterclass - DevOps & Microservices

## 🎯 Training Overview
Comprehensive hands-on training for AWS EKS, Kubernetes, and DevOps practices using a shared cluster approach for cost-effective learning.

## 🏗️ Architecture Approach
**Shared Cluster Strategy**: One EKS cluster serves all 23 training sections using namespace isolation.

```
Training Cluster (training-cluster)
├── 00-Cluster-Setup/          # Shared infrastructure
├── 03-Docker-Fundamentals/    # Namespace: docker-fundamentals
├── 04-K8s-Imperative/         # Namespace: k8s-imperative
├── 05-K8s-Declarative/        # Namespace: k8s-declarative
├── 06-Pod-Identity/           # Namespace: pod-identity
├── ... (all sections)
└── 23-Container-Insights/     # Namespace: container-insights
```

## 💰 Cost Benefits
- **Traditional Approach**: 23 clusters × $130 = $2,990/month
- **Shared Approach**: 1 cluster = $130/month
- **Savings**: 95% cost reduction ($2,860/month saved)

## 📚 Section Structure

### Infrastructure Sections (Full Setup)
- **00-Cluster-Setup/**: Complete cluster infrastructure
  - CLI-Commands/ (eksctl setup)
  - Terraform/ (IaC approach)
- **04-Kubernetes-Fundamentals-Imperative/**: Reference implementation
  - CLI-Commands/ (kubectl reference)
  - Terraform/ (learning cluster)
  - Labs/ (comprehensive exercises)

### Training Sections (Labs-Focused)
All other sections (03, 05-23) follow this structure:
```
XX-Section-Name/
├── Labs/                  # Progressive hands-on exercises
│   ├── Lab1/             # Basic concepts and setup
│   ├── Lab2/             # Intermediate scenarios
│   ├── Lab3/             # Advanced use cases
│   └── Lab4-5/           # Specialized scenarios
└── README.md             # Section overview and learning path
```

## 🚀 Quick Start

### 1. One-Time Cluster Setup
```bash
# Create shared training cluster
cd 00-Cluster-Setup/Terraform
terraform init && terraform apply

# Verify setup
kubectl get nodes
kubectl get namespaces
```

### 2. Section Usage Pattern
```bash
# Switch to section namespace
kubectl config set-context --current --namespace=k8s-imperative

# Follow section labs
cd 04-Kubernetes-Fundamentals-Imperative/Labs/Lab1
cat README.md

# Clean up section (keep cluster)
kubectl delete all --all -n k8s-imperative
```

### 3. End of Training
```bash
# Delete entire cluster
eksctl delete cluster --name training-cluster --region ap-south-1
```

## 📋 Training Sections

### Foundation (Sections 00-04)
- **00-Cluster-Setup**: Shared EKS cluster infrastructure
- **01-Introduction**: Course overview and prerequisites  
- **02-EKS-Create-Cluster-eksctl**: Alternative cluster creation
- **03-Docker-Fundamentals**: Container basics and ECR
- **04-Kubernetes-Fundamentals-Imperative**: kubectl commands

### Core Kubernetes (Sections 05-08)
- **05-Kubernetes-Fundamentals-Declarative-YAML**: YAML manifests
- **06-EKS-Pod-Identity**: AWS service integration
- **07-EKS-Storage-AWS-EBS**: Persistent storage
- **08-Kubernetes-Secrets-InitContainers-Probes**: Advanced concepts

### Storage & Databases (Section 09)
- **09-EKS-Storage-AWS-RDS**: Database integration

### Load Balancing & Ingress (Sections 10-17)
- **10-EKS-LoadBalancers-CLB-NLB**: Classic and Network LBs
- **11-ALB-Ingress-Controller-Install**: ALB controller setup
- **12-ALB-Ingress-Basics**: Basic ingress patterns
- **13-ALB-Ingress-Context-Path-Routing**: Path-based routing
- **14-ALB-Ingress-Host-Header-Routing**: Host-based routing
- **15-ALB-Ingress-Groups**: Ingress grouping
- **16-ALB-Ingress-Target-Type-IP**: IP target mode
- **17-ALB-Ingress-Internal-ALB**: Internal load balancers

### DevOps & CI/CD (Sections 18-19)
- **18-EKS-ECR-Integration**: Container registry
- **19-Microservices-Deployment-EKS**: Microservices patterns

### Scaling & Optimization (Sections 20-22)
- **20-EKS-HPA-Horizontal-Pod-Autoscaler**: Pod scaling
- **21-EKS-VPA-Vertical-Pod-Autoscaler**: Resource optimization
- **22-EKS-Cluster-Autoscaler**: Node scaling

### Monitoring (Section 23)
- **23-CloudWatch-Container-Insights**: Observability

## 🎓 Learning Path Recommendations

### Beginner Path (Weeks 1-2)
1. 00-Cluster-Setup → 03-Docker-Fundamentals
2. 04-Kubernetes-Fundamentals-Imperative
3. 05-Kubernetes-Fundamentals-Declarative-YAML

### Intermediate Path (Weeks 3-4)
1. 06-EKS-Pod-Identity → 07-EKS-Storage-AWS-EBS
2. 08-Kubernetes-Secrets-InitContainers-Probes
3. 10-EKS-LoadBalancers-CLB-NLB

### Advanced Path (Weeks 5-6)
1. 11-17: Complete ALB Ingress series
2. 18-19: DevOps and microservices
3. 20-23: Scaling and monitoring

## 🔧 Prerequisites
- AWS account with admin permissions
- AWS CLI configured
- kubectl installed
- Terraform installed (for infrastructure)
- eksctl installed (for cluster management)
- Helm installed (for package management)

## 📊 Completion Status
- **Infrastructure Ready**: 2/2 sections (00, 04)
- **Labs Created**: 15+ comprehensive lab exercises
- **Sections Structured**: 23/23 sections organized
- **Ready for Training**: ✅ Immediate start possible

## 🎯 Key Features
- **Cost-Effective**: Shared cluster approach
- **Production-Ready**: Real-world scenarios
- **Progressive Learning**: Beginner to advanced
- **Hands-On Focus**: Practical lab exercises
- **Comprehensive Coverage**: Full EKS ecosystem
- **Best Practices**: Security and optimization included

## 📞 Support
- **Owner**: imran.shaikh@einfochips.com
- **Project**: Internal POC
- **Department**: PES-Digital
- **End Date**: 30-11-2025