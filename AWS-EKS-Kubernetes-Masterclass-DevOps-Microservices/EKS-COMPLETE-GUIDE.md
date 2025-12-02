# AWS EKS Kubernetes Masterclass - Complete Training Guide

## Course Overview
This comprehensive course covers AWS EKS (Elastic Kubernetes Service) from fundamentals to advanced DevOps and microservices deployment patterns.

## Course Structure

### 📚 **Section 1: Introduction**
- **Location**: `01-Introduction/`
- **Topics**: Course overview, prerequisites, learning objectives
- **Duration**: 30 minutes

### 🐳 **Section 2: EKS Cluster Creation**
- **Location**: `02-EKS-Create-Cluster-eksctl/`
- **Infrastructure**: Complete EKS cluster with Terraform
- **Topics**: eksctl, Terraform, VPC setup, node groups
- **Labs**: 3 hands-on labs
- **Duration**: 2 hours

### 🐋 **Section 3: Docker Fundamentals**
- **Location**: `03-Docker-Fundamentals/`
- **Infrastructure**: Docker host on EC2
- **Topics**: Containers, images, Dockerfile, Docker Compose
- **Labs**: 3 progressive labs
- **Duration**: 3 hours

### ⚙️ **Section 4: Kubernetes Fundamentals (Imperative)**
- **Location**: `04-Kubernetes-Fundamentals-Imperative/`
- **Infrastructure**: Self-managed K8s cluster
- **Topics**: Pods, deployments, services, kubectl commands
- **Labs**: 3 hands-on labs
- **Duration**: 4 hours

### 📝 **Section 5: Kubernetes Fundamentals (Declarative)**
- **Location**: `05-Kubernetes-Fundamentals-Declarative-YAML/`
- **Infrastructure**: YAML manifests and GitOps
- **Topics**: YAML syntax, manifests, best practices
- **Labs**: 3 declarative labs
- **Duration**: 3 hours

### 🔐 **Section 6: EKS Pod Identity**
- **Location**: `06-EKS-Pod-Identity/`
- **Infrastructure**: IAM roles and OIDC
- **Topics**: Pod identity, IRSA, security
- **Labs**: 3 security labs
- **Duration**: 2 hours

### 💾 **Section 7: EKS Storage (AWS EBS)**
- **Location**: `07-EKS-Storage-AWS-EBS/`
- **Infrastructure**: EBS CSI driver, storage classes
- **Topics**: Persistent volumes, storage classes, CSI
- **Labs**: 3 storage labs
- **Duration**: 2.5 hours

### 🔒 **Section 8: Kubernetes Secrets & Probes**
- **Location**: `08-Kubernetes-Secrets-InitContainers-Probes/`
- **Infrastructure**: Security and health monitoring
- **Topics**: Secrets, ConfigMaps, health checks
- **Labs**: 3 security labs
- **Duration**: 2 hours

### 🗄️ **Section 9: EKS Storage (AWS RDS)**
- **Location**: `09-EKS-Storage-AWS-RDS/`
- **Infrastructure**: RDS integration with EKS
- **Topics**: Database connectivity, secrets management
- **Labs**: 3 database labs
- **Duration**: 3 hours

### ⚖️ **Section 10: EKS Load Balancers (CLB/NLB)**
- **Location**: `10-EKS-LoadBalancers-CLB-NLB/`
- **Infrastructure**: Load balancers and services
- **Topics**: CLB, NLB, service types
- **Labs**: 4 load balancer labs
- **Duration**: 2.5 hours

### 🚀 **Section 11: ALB Ingress Controller**
- **Location**: `11-ALB-Ingress-Controller-Install/`
- **Infrastructure**: ALB controller setup
- **Topics**: Ingress, ALB controller, installation
- **Labs**: 3 ingress labs
- **Duration**: 2 hours

### 🌐 **Section 12: ALB Ingress Basics**
- **Location**: `12-ALB-Ingress-Basics/`
- **Infrastructure**: Basic ingress configurations
- **Topics**: Ingress rules, path-based routing
- **Labs**: 3 basic ingress labs
- **Duration**: 2 hours

### 🛣️ **Section 13: ALB Context Path Routing**
- **Location**: `13-ALB-Ingress-Context-Path-Routing/`
- **Infrastructure**: Advanced routing patterns
- **Topics**: Path-based routing, URL rewriting
- **Labs**: 3 routing labs
- **Duration**: 2 hours

### 🏷️ **Section 14: ALB Host Header Routing**
- **Location**: `14-ALB-Ingress-Host-Header-Routing/`
- **Infrastructure**: Host-based routing
- **Topics**: Virtual hosts, domain routing
- **Labs**: 3 host routing labs
- **Duration**: 2 hours

### 👥 **Section 15: ALB Ingress Groups**
- **Location**: `15-ALB-Ingress-Groups/`
- **Infrastructure**: Shared ALB configurations
- **Topics**: Ingress groups, cost optimization
- **Labs**: 3 group labs
- **Duration**: 1.5 hours

### 🎯 **Section 16: ALB Target Type IP**
- **Location**: `16-ALB-Ingress-Target-Type-IP/`
- **Infrastructure**: IP-based targeting
- **Topics**: Target types, networking modes
- **Labs**: 3 targeting labs
- **Duration**: 1.5 hours

### 🔒 **Section 17: Internal ALB**
- **Location**: `17-ALB-Ingress-Internal-ALB/`
- **Infrastructure**: Private load balancers
- **Topics**: Internal ALB, private networking
- **Labs**: 3 internal labs
- **Duration**: 2 hours

### 📦 **Section 18: EKS ECR Integration**
- **Location**: `18-EKS-ECR-Integration/`
- **Infrastructure**: Container registry integration
- **Topics**: ECR, image management, CI/CD
- **Labs**: 3 registry labs
- **Duration**: 2 hours

### 🏗️ **Section 19: Microservices Deployment**
- **Location**: `19-Microservices-Deployment-EKS/`
- **Infrastructure**: Complete microservices stack
- **Topics**: Service mesh, inter-service communication
- **Labs**: 3 microservices labs
- **Duration**: 4 hours

### 📈 **Section 20: Horizontal Pod Autoscaler**
- **Location**: `20-EKS-HPA-Horizontal-Pod-Autoscaler/`
- **Infrastructure**: HPA with metrics server
- **Topics**: Auto-scaling, metrics, performance
- **Labs**: 3 scaling labs
- **Duration**: 2 hours

### 📊 **Section 21: Vertical Pod Autoscaler**
- **Location**: `21-EKS-VPA-Vertical-Pod-Autoscaler/`
- **Infrastructure**: VPA configuration
- **Topics**: Resource optimization, right-sizing
- **Labs**: 3 VPA labs
- **Duration**: 2 hours

### 🔄 **Section 22: Cluster Autoscaler**
- **Location**: `22-EKS-Cluster-Autoscaler/`
- **Infrastructure**: Node auto-scaling
- **Topics**: Cluster scaling, cost optimization
- **Labs**: 3 cluster scaling labs
- **Duration**: 2 hours

### 📊 **Section 23: CloudWatch Container Insights**
- **Location**: `23-CloudWatch-Container-Insights/`
- **Infrastructure**: Monitoring and observability
- **Topics**: Metrics, logs, dashboards, alerting
- **Labs**: 3 monitoring labs
- **Duration**: 2.5 hours

## 🚀 Getting Started

### Prerequisites
- AWS Account with appropriate permissions
- AWS CLI configured
- Terraform installed (v1.0+)
- kubectl installed
- Docker installed (for local development)
- Git configured

### Initial Setup
```bash
# Clone the repository
git clone <repository-url>
cd AWS-EKS-Kubernetes-Masterclass-DevOps-Microservices

# Configure AWS CLI
aws configure

# Verify prerequisites
terraform --version
kubectl version --client
docker --version
```

### Course Progression
1. **Start with Section 1**: Introduction and overview
2. **Follow Sequential Order**: Each section builds on previous knowledge
3. **Complete All Labs**: Hands-on practice is essential
4. **Use Both Approaches**: Terraform for infrastructure, manual steps for learning

## 📁 Directory Structure

```
AWS-EKS-Kubernetes-Masterclass-DevOps-Microservices/
├── 01-Introduction/
├── 02-EKS-Create-Cluster-eksctl/
│   ├── terraform/          # Infrastructure as Code
│   ├── cli-labs/           # eksctl labs
│   └── manual-steps/       # Console steps
├── 03-Docker-Fundamentals/
│   ├── terraform/          # Docker host infrastructure
│   ├── labs/               # Progressive labs
│   └── manual-steps/       # Step-by-step guide
├── [04-23 sections follow same pattern]
└── README.md
```

## 🛠️ Infrastructure Deployment

### Option 1: Terraform (Recommended)
```bash
# Navigate to any section
cd 02-EKS-Create-Cluster-eksctl/terraform

# Initialize and deploy
terraform init
terraform plan
terraform apply
```

### Option 2: Manual Steps
```bash
# Follow manual steps in each section
cd 02-EKS-Create-Cluster-eksctl/manual-steps
cat Console-Manual-Steps.md
```

## 🧪 Lab Structure

Each section contains progressive labs:
- **Lab 1**: Basic concepts and setup
- **Lab 2**: Intermediate configurations
- **Lab 3**: Advanced scenarios and troubleshooting

### Lab Execution
```bash
# Navigate to lab directory
cd 03-Docker-Fundamentals/labs/lab1

# Follow README instructions
cat README.md

# Execute lab steps
./lab-setup.sh  # if provided
```

## 📊 Learning Path

### Beginner Track (Sections 1-8)
- **Duration**: ~20 hours
- **Focus**: Fundamentals, basic operations
- **Outcome**: Comfortable with Kubernetes basics

### Intermediate Track (Sections 9-16)
- **Duration**: ~18 hours
- **Focus**: Advanced networking, storage, ingress
- **Outcome**: Production-ready knowledge

### Advanced Track (Sections 17-23)
- **Duration**: ~16 hours
- **Focus**: Microservices, scaling, monitoring
- **Outcome**: Expert-level skills

## 🔧 Common Commands

### EKS Management
```bash
# Update kubeconfig
aws eks update-kubeconfig --region us-west-2 --name cluster-name

# Check cluster status
kubectl cluster-info
kubectl get nodes

# Check all resources
kubectl get all --all-namespaces
```

### Terraform Management
```bash
# Initialize
terraform init

# Plan changes
terraform plan

# Apply changes
terraform apply

# Destroy resources
terraform destroy
```

### Troubleshooting
```bash
# Check pod logs
kubectl logs <pod-name> -n <namespace>

# Describe resources
kubectl describe pod <pod-name>
kubectl describe service <service-name>

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp
```

## 🎯 Learning Objectives

By completing this course, you will:

1. **Master EKS Fundamentals**
   - Create and manage EKS clusters
   - Understand EKS architecture and components
   - Configure networking and security

2. **Excel in Container Technologies**
   - Build and manage Docker containers
   - Create efficient Dockerfiles
   - Use Docker Compose for multi-container apps

3. **Become Kubernetes Expert**
   - Deploy applications using various methods
   - Manage storage, networking, and security
   - Implement auto-scaling and monitoring

4. **Implement DevOps Practices**
   - Infrastructure as Code with Terraform
   - CI/CD pipelines with containers
   - Monitoring and observability

5. **Deploy Production Microservices**
   - Design scalable architectures
   - Implement service mesh patterns
   - Optimize performance and costs

## 📈 Assessment and Certification

### Section Assessments
- Hands-on labs completion
- Troubleshooting exercises
- Best practices implementation

### Final Project
- Deploy a complete microservices application
- Implement monitoring and alerting
- Document architecture and decisions

## 🆘 Support and Resources

### Documentation
- Each section has comprehensive README files
- Troubleshooting guides included
- Best practices documented

### Community
- Discussion forums for each section
- Peer learning opportunities
- Expert mentorship available

### Additional Resources
- AWS EKS Documentation
- Kubernetes Official Docs
- Terraform AWS Provider Docs
- Docker Documentation

## 🔄 Updates and Maintenance

This course is regularly updated to reflect:
- Latest AWS EKS features
- Kubernetes version updates
- Security best practices
- Industry trends and patterns

## 📝 Feedback and Contributions

We welcome feedback and contributions:
- Report issues or bugs
- Suggest improvements
- Share additional labs or examples
- Contribute to documentation

---

**Happy Learning! 🚀**

Start your journey to becoming an AWS EKS and Kubernetes expert!