# GitOps with Kubernetes (EKS), Terraform, and AWS

**Student:** Imran Shaikh  
**Date:** December 2024  
**Cloud Platform:** AWS

---

## Project Overview

This project implements a complete GitOps workflow on AWS using:
- **EKS (Elastic Kubernetes Service)** for container orchestration
- **ArgoCD** for GitOps continuous delivery
- **SonarQube** for code quality and security analysis
- **Terraform** for infrastructure as code

## Project Structure

```
GitOps-with-Kubernetes_(K8S)_Terraform_AWS/
├── 1EKS_repo_infra/              # EKS cluster infrastructure
├── 2DeployEKSonARGOCDrepo/       # ArgoCD deployment on EKS
└── 3aws_terraform_SonarQube/     # SonarQube setup with Terraform
```

---

## 1. EKS Infrastructure (1EKS_repo_infra)

### Purpose
- Provision AWS EKS cluster using Terraform
- Set up VPC, subnets, and networking
- Configure node groups and IAM roles

### Key Components
- EKS Cluster
- Worker Nodes
- VPC and Networking
- IAM Roles and Policies

### Deployment Steps
```bash
cd 1EKS_repo_infra
terraform init
terraform plan
terraform apply
```

---

## 2. ArgoCD on EKS (2DeployEKSonARGOCDrepo)

### Purpose
- Deploy ArgoCD on EKS cluster
- Configure GitOps workflows
- Automate application deployments

### Key Components
- ArgoCD Server
- ArgoCD Application Controller
- Git Repository Integration
- Application Manifests

### Deployment Steps
```bash
cd 2DeployEKSonARGOCDrepo
kubectl apply -f argocd-install.yaml
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

### Access ArgoCD
- URL: https://localhost:8080
- Username: admin
- Password: Get from `kubectl -n argocd get secret argocd-initial-admin-secret`

---

## 3. SonarQube Setup (3aws_terraform_SonarQube)

### Purpose
- Deploy SonarQube for code quality analysis
- Integrate with CI/CD pipeline
- Automated security scanning

### Key Components
- EC2 Instance (t2.medium or larger)
- Docker
- SonarQube 9.9 Community Edition
- Java 17 (Amazon Corretto)

### Deployment Steps
```bash
cd 3aws_terraform_SonarQube/gitops-aws-ec2-terraform-repo
terraform init
terraform plan
terraform apply
```

### Access SonarQube
- URL: http://<EC2-PUBLIC-IP>:9000
- Default Username: admin
- Default Password: admin (change on first login)

### Installation Script
The `install_sonarqube.sh` script installs:
- Java 17 (Amazon Corretto)
- Git
- Node.js & npm
- Docker
- SonarQube container

---

## GitOps Workflow

### 1. Infrastructure Provisioning
```
Developer → Git Push → Terraform → AWS EKS Cluster
```

### 2. Application Deployment
```
Developer → Git Push → ArgoCD → EKS Cluster → Running Pods
```

### 3. Code Quality Check
```
Developer → Git Push → CI Pipeline → SonarQube Analysis → Quality Gate
```

---

## Prerequisites

### Tools Required
- AWS CLI configured
- kubectl installed
- Terraform >= 1.0
- Git
- Docker (for local testing)

### AWS Resources
- AWS Account with appropriate permissions
- VPC with public/private subnets
- EC2 Key Pair
- IAM roles for EKS

---

## Deployment Order

1. **Deploy EKS Infrastructure**
   ```bash
   cd 1EKS_repo_infra
   terraform apply
   ```

2. **Configure kubectl**
   ```bash
   aws eks update-kubeconfig --name <cluster-name> --region us-east-1
   ```

3. **Deploy ArgoCD**
   ```bash
   cd 2DeployEKSonARGOCDrepo
   kubectl apply -f argocd/
   ```

4. **Deploy SonarQube**
   ```bash
   cd 3aws_terraform_SonarQube
   terraform apply
   ```

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│                      AWS Cloud                          │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │              EKS Cluster                         │  │
│  │                                                  │  │
│  │  ┌────────────┐      ┌──────────────────────┐  │  │
│  │  │  ArgoCD    │──────│  Application Pods    │  │  │
│  │  │  Server    │      │  (Deployed via       │  │  │
│  │  └────────────┘      │   GitOps)            │  │  │
│  │                      └──────────────────────┘  │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │         EC2 Instance (SonarQube)                 │  │
│  │                                                  │  │
│  │  ┌────────────────────────────────────────────┐ │  │
│  │  │  Docker Container                          │ │  │
│  │  │  ┌──────────────────────────────────────┐ │ │  │
│  │  │  │  SonarQube 9.9 Community            │ │ │  │
│  │  │  │  Port: 9000                         │ │ │  │
│  │  │  └──────────────────────────────────────┘ │ │  │
│  │  └────────────────────────────────────────────┘ │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │              Git Repository                      │  │
│  │  - Infrastructure Code (Terraform)               │  │
│  │  - Application Manifests (K8S YAML)              │  │
│  │  - ArgoCD Applications                           │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

---

## Key Features

### GitOps Benefits
- ✅ **Version Control** - All changes tracked in Git
- ✅ **Automated Deployment** - ArgoCD syncs automatically
- ✅ **Rollback Capability** - Easy revert to previous versions
- ✅ **Audit Trail** - Complete history of changes
- ✅ **Declarative** - Desired state defined in Git

### Infrastructure as Code
- ✅ **Reproducible** - Consistent environments
- ✅ **Scalable** - Easy to replicate
- ✅ **Documented** - Code serves as documentation
- ✅ **Testable** - Validate before deployment

### Code Quality
- ✅ **Automated Scanning** - SonarQube integration
- ✅ **Security Analysis** - Vulnerability detection
- ✅ **Quality Gates** - Enforce standards
- ✅ **Technical Debt** - Track and manage

---

## Troubleshooting

### EKS Cluster Issues
```bash
# Check cluster status
aws eks describe-cluster --name <cluster-name>

# Verify nodes
kubectl get nodes

# Check pods
kubectl get pods -A
```

### ArgoCD Issues
```bash
# Check ArgoCD pods
kubectl get pods -n argocd

# View ArgoCD logs
kubectl logs -n argocd deployment/argocd-server

# Sync application manually
argocd app sync <app-name>
```

### SonarQube Issues
```bash
# Check Docker container
sudo docker ps

# View SonarQube logs
sudo docker logs sonarqube

# Restart SonarQube
sudo docker restart sonarqube
```

---

## Best Practices

1. **Use separate Git repositories** for infrastructure and applications
2. **Implement branch protection** on main/master branches
3. **Enable ArgoCD auto-sync** with caution (use manual sync for production)
4. **Regular SonarQube scans** before merging code
5. **Tag releases** in Git for easy rollback
6. **Monitor ArgoCD sync status** regularly
7. **Backup EKS cluster** configurations
8. **Use Terraform workspaces** for multiple environments

---

## Cost Optimization

### EKS Cluster
- Use Spot Instances for non-critical workloads
- Right-size node groups
- Enable cluster autoscaler

### SonarQube
- Use t2.medium for small teams
- Stop instance when not in use
- Consider SonarCloud for small projects

### General
- Delete unused resources
- Use AWS Cost Explorer
- Set up billing alerts

---

## Next Steps

1. [ ] Set up CI/CD pipeline integration
2. [ ] Configure ArgoCD notifications
3. [ ] Implement monitoring with Prometheus/Grafana
4. [ ] Add Helm charts for applications
5. [ ] Set up multi-environment deployments (dev/staging/prod)
6. [ ] Implement secrets management (AWS Secrets Manager)
7. [ ] Add automated testing in pipeline
8. [ ] Configure backup and disaster recovery

---

## Resources

- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [SonarQube Documentation](https://docs.sonarqube.org/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/)

---

**Project Status:** In Progress  
**Last Updated:** December 2024
