# Quick Reference Guide

## 🚀 Quick Start Commands

### Initial Setup
```bash
# 1. Create Terraform backend
aws s3 mb s3://devops-platform-terraform-state
aws dynamodb create-table --table-name terraform-state-lock \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST

# 2. Deploy infrastructure
cd terraform-infra/environments/prod
terraform init
terraform apply -var="key_name=your-key" -auto-approve

# 3. Configure kubectl
aws eks update-kubeconfig --region us-east-1 --name devops-platform-prod

# 4. Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

# 5. Get credentials
terraform output
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

## 📋 Common Commands

### Terraform
```bash
# Initialize
terraform init

# Plan
terraform plan -var="key_name=your-key"

# Apply
terraform apply -var="key_name=your-key" -auto-approve

# Destroy
terraform destroy -var="key_name=your-key" -auto-approve

# Show outputs
terraform output

# Format code
terraform fmt -recursive
```

### Kubernetes
```bash
# Get pods
kubectl get pods -n prod

# Get services
kubectl get svc -n prod

# Get deployments
kubectl get deployments -n prod

# Describe pod
kubectl describe pod <pod-name> -n prod

# Logs
kubectl logs <pod-name> -n prod -f

# Execute command
kubectl exec -it <pod-name> -n prod -- /bin/bash

# Rollout status
kubectl rollout status deployment/devops-platform -n prod

# Rollback
kubectl rollout undo deployment/devops-platform -n prod

# Scale
kubectl scale deployment/devops-platform --replicas=10 -n prod
```

### ArgoCD
```bash
# Login
argocd login <argocd-url> --username admin --insecure

# List apps
argocd app list

# Get app details
argocd app get devops-platform-prod

# Sync app
argocd app sync devops-platform-prod

# Rollback
argocd app rollback devops-platform-prod

# Delete app
argocd app delete devops-platform-prod
```

### AWS CLI
```bash
# ECR login
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com

# List ECR images
aws ecr list-images --repository-name devops-platform-app

# CloudWatch logs
aws logs tail /aws/lambda/ai-remediation-prod --follow

# Describe alarm
aws cloudwatch describe-alarms --alarm-names devops-platform-prod-pod-failures

# SNS publish
aws sns publish --topic-arn <topic-arn> --message "Test message"
```

### Docker
```bash
# Build
docker build -t devops-platform-app:latest .

# Run locally
docker run -p 5000:5000 devops-platform-app:latest

# Tag
docker tag devops-platform-app:latest <ecr-url>:latest

# Push
docker push <ecr-url>:latest

# Clean up
docker system prune -a
```

### Jenkins
```bash
# Get initial password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

# Restart Jenkins
sudo systemctl restart jenkins

# View logs
sudo journalctl -u jenkins -f

# Check status
sudo systemctl status jenkins
```

## 🔍 Troubleshooting Commands

### Check EKS Cluster
```bash
aws eks describe-cluster --name devops-platform-prod
kubectl cluster-info
kubectl get nodes
kubectl get namespaces
```

### Check Pod Issues
```bash
kubectl get pods -n prod
kubectl describe pod <pod-name> -n prod
kubectl logs <pod-name> -n prod --previous
kubectl get events -n prod --sort-by='.lastTimestamp'
```

### Check ArgoCD Sync Issues
```bash
argocd app get devops-platform-prod
kubectl logs -n argocd deployment/argocd-application-controller
kubectl logs -n argocd deployment/argocd-server
```

### Check Lambda Issues
```bash
aws lambda get-function --function-name ai-remediation-prod
aws logs tail /aws/lambda/ai-remediation-prod --follow
aws lambda invoke --function-name ai-remediation-prod output.json
```

### Check Jenkins Issues
```bash
# SSH to Jenkins
ssh -i your-key.pem ec2-user@<jenkins-ip>

# Check Docker
sudo systemctl status docker
docker ps

# Check kubectl
kubectl get nodes

# Check AWS CLI
aws sts get-caller-identity
```

## 📊 Monitoring Commands

### CloudWatch
```bash
# Get metrics
aws cloudwatch get-metric-statistics \
    --namespace ContainerInsights \
    --metric-name pod_restart_count \
    --dimensions Name=ClusterName,Value=devops-platform-prod \
    --start-time 2024-01-01T00:00:00Z \
    --end-time 2024-01-02T00:00:00Z \
    --period 3600 \
    --statistics Sum

# List alarms
aws cloudwatch describe-alarms

# Get alarm history
aws cloudwatch describe-alarm-history --alarm-name devops-platform-prod-pod-failures
```

### Application Health
```bash
# Get LoadBalancer URL
LB_URL=$(kubectl get svc devops-platform -n prod -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Test endpoints
curl http://$LB_URL/
curl http://$LB_URL/health
curl http://$LB_URL/api/users
curl http://$LB_URL/api/metrics
```

## 🔐 Security Commands

### Secrets Management
```bash
# Create secret in AWS Secrets Manager
aws secretsmanager create-secret \
    --name prod/db-password \
    --secret-string '{"password":"your-password"}'

# Get secret
aws secretsmanager get-secret-value --secret-id prod/db-password

# Create Kubernetes secret
kubectl create secret generic app-secrets \
    --from-literal=db-password=your-password \
    -n prod
```

### IAM
```bash
# Get role
aws iam get-role --role-name jenkins-prod

# List role policies
aws iam list-role-policies --role-name jenkins-prod

# Get policy
aws iam get-role-policy --role-name jenkins-prod --policy-name jenkins-prod-policy
```

## 🧪 Testing Commands

### Run Tests Locally
```bash
cd app-repo

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run tests
pytest tests/ -v

# Run with coverage
pytest tests/ --cov=src --cov-report=html

# Open coverage report
open htmlcov/index.html
```

### Test Docker Build
```bash
cd app-repo

# Build
docker build -t devops-platform-app:test .

# Run
docker run -p 5000:5000 devops-platform-app:test

# Test
curl http://localhost:5000/health
```

### Simulate Failures
```bash
# Kill pod
kubectl exec -n prod <pod-name> -- kill 1

# Delete pod
kubectl delete pod <pod-name> -n prod

# Cause OOM
kubectl exec -n prod <pod-name> -- stress --vm 1 --vm-bytes 1G --timeout 60s
```

## 📦 Backup & Restore

### Backup
```bash
# Backup Terraform state
aws s3 cp s3://devops-platform-terraform-state/prod/terraform.tfstate ./backup/

# Backup Kubernetes resources
kubectl get all -n prod -o yaml > backup/prod-resources.yaml

# Backup ArgoCD applications
kubectl get applications -n argocd -o yaml > backup/argocd-apps.yaml
```

### Restore
```bash
# Restore Terraform state
aws s3 cp ./backup/terraform.tfstate s3://devops-platform-terraform-state/prod/

# Restore Kubernetes resources
kubectl apply -f backup/prod-resources.yaml

# Restore ArgoCD applications
kubectl apply -f backup/argocd-apps.yaml
```

## 🔄 Update Commands

### Update Application
```bash
# Update image in GitOps repo
cd gitops-repo
sed -i 's|image: .*|image: <ecr-url>:new-tag|g' apps/prod/deployment.yaml
git add .
git commit -m "Update to new-tag"
git push origin main

# ArgoCD will auto-sync
```

### Update Infrastructure
```bash
cd terraform-infra/environments/prod

# Make changes to main.tf
# Then apply
terraform plan
terraform apply
```

### Update Jenkins Pipeline
```bash
cd app-repo

# Edit Jenkinsfile
# Commit and push
git add Jenkinsfile
git commit -m "Update pipeline"
git push origin main
```

## 📈 Performance Commands

### Resource Usage
```bash
# Top pods
kubectl top pods -n prod

# Top nodes
kubectl top nodes

# Describe HPA
kubectl describe hpa devops-platform-hpa -n prod
```

### Load Testing
```bash
# Install hey
go install github.com/rakyll/hey@latest

# Run load test
hey -n 10000 -c 100 http://<lb-url>/
```

## 🎯 Quick Fixes

### Pod Not Starting
```bash
kubectl describe pod <pod-name> -n prod
kubectl logs <pod-name> -n prod
kubectl delete pod <pod-name> -n prod  # Let it recreate
```

### ArgoCD Out of Sync
```bash
argocd app sync devops-platform-prod --force
argocd app refresh devops-platform-prod
```

### Jenkins Build Failing
```bash
# Check Jenkins logs
ssh ec2-user@<jenkins-ip>
sudo journalctl -u jenkins -f

# Restart Jenkins
sudo systemctl restart jenkins
```

### Lambda Not Triggering
```bash
# Check EventBridge rule
aws events list-rules

# Check Lambda permissions
aws lambda get-policy --function-name ai-remediation-prod

# Test Lambda manually
aws lambda invoke --function-name ai-remediation-prod output.json
```

## 📞 Emergency Contacts

### Rollback Everything
```bash
# Rollback application
argocd app rollback devops-platform-prod

# Or via kubectl
kubectl rollout undo deployment/devops-platform -n prod

# Rollback infrastructure
cd terraform-infra/environments/prod
git revert HEAD
terraform apply
```

### Complete Cleanup
```bash
# Delete all ArgoCD apps
argocd app delete devops-platform-dev --cascade
argocd app delete devops-platform-staging --cascade
argocd app delete devops-platform-prod --cascade

# Destroy all infrastructure
cd terraform-infra/environments/prod && terraform destroy -auto-approve
cd ../staging && terraform destroy -auto-approve
cd ../dev && terraform destroy -auto-approve
```

---

**Keep this guide handy for quick reference during implementation and operations!**
