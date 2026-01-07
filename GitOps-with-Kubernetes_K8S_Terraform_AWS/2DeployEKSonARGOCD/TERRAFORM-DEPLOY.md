# ArgoCD Deployment via Terraform
 
**Method:** Terraform with null_resource

---

## Overview

This Terraform configuration automatically:
1. Configures kubectl for EKS cluster
2. Installs ArgoCD on EKS
3. Patches ArgoCD service to LoadBalancer

## Prerequisites

- EKS cluster running (from 1EKS-infra-setup)
- AWS CLI configured
- kubectl installed
- Terraform >= 1.0

## Files

- `main.tf` - Terraform configuration with null_resource
- `argocd-service-patch.yaml` - LoadBalancer service configuration

## Deployment Steps

### 1. Initialize Terraform
```bash
cd 2DeployEKSonARGOCD
terraform init
```

### 2. Review Plan
```bash
terraform plan
```

### 3. Deploy ArgoCD
```bash
terraform apply -auto-approve
```

This will:
- Install ArgoCD
- Expose via LoadBalancer
- Deploy Mario game
- Show admin password

### 4. Get ArgoCD URL
```bash
kubectl get svc argocd-server -n argocd
```

### 5. Access ArgoCD
```bash
# Get LoadBalancer URL
ARGOCD_URL=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "ArgoCD URL: http://$ARGOCD_URL"

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

## Verify Deployment

### Check ArgoCD Pods
```bash
kubectl get pods -n argocd
```

## Cleanup

```bash
terraform destroy -auto-approve
```

---

## Advantages of Terraform Approach

✅ **Automated** - One command deployment  
✅ **Repeatable** - Consistent installations  
✅ **Version Controlled** - Track changes in Git  
✅ **Idempotent** - Safe to run multiple times  

---

**Status:** Ready to deploy!
