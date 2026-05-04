# Complete Setup Guide - Production DevOps Platform

## Prerequisites

### Required Tools
- AWS CLI configured with admin access
- Terraform >= 1.0
- kubectl
- Git
- Docker (for local testing)
- Python 3.9+

### AWS Requirements
- AWS Account with admin access
- AWS Bedrock access (Claude 3 Sonnet model enabled)
- SSH key pair created in AWS EC2

### GitHub Requirements
- 3 GitHub repositories created:
  - `app-repo` (application code)
  - `gitops-repo` (Kubernetes manifests)
  - `terraform-infra` (infrastructure code)

## Phase 1: Infrastructure Setup (60 minutes)

### Step 1.1: Prepare Terraform Backend

```bash
# Create S3 bucket for Terraform state
aws s3 mb s3://devops-platform-terraform-state --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
    --bucket devops-platform-terraform-state \
    --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
    --bucket devops-platform-terraform-state \
    --server-side-encryption-configuration '{
        "Rules": [{
            "ApplyServerSideEncryptionByDefault": {
                "SSEAlgorithm": "AES256"
            }
        }]
    }'

# Create DynamoDB table for state locking
aws dynamodb create-table \
    --table-name terraform-state-lock \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region us-east-1
```

### Step 1.2: Package Lambda Function

```bash
cd terraform-infra/modules/lambda

# Install dependencies
pip install boto3 -t .

# Create zip file
zip -r lambda_function.zip lambda_function.py

cd ../../..
```

### Step 1.3: Deploy Production Infrastructure

```bash
cd terraform-infra/environments/prod

# Initialize Terraform
terraform init

# Review plan
terraform plan -var="key_name=your-ssh-key-name"

# Apply (this takes ~30-40 minutes)
terraform apply -var="key_name=your-ssh-key-name" -auto-approve

# Save outputs
terraform output > outputs.txt
cat outputs.txt
```

**Expected Outputs:**
```
jenkins_url = "http://54.123.45.67:8080"
sonarqube_url = "http://54.123.45.68:9000"
eks_cluster_name = "devops-platform-prod"
ecr_repository_url = "123456789012.dkr.ecr.us-east-1.amazonaws.com/devops-platform-app"
```

### Step 1.4: Configure kubectl

```bash
# Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name devops-platform-prod

# Verify connection
kubectl get nodes
kubectl get namespaces
```

## Phase 2: Jenkins Configuration (30 minutes)

### Step 2.1: Access Jenkins

```bash
# Get Jenkins URL from Terraform output
JENKINS_URL=$(terraform output -raw jenkins_url)
echo "Jenkins URL: $JENKINS_URL"

# SSH to Jenkins server
JENKINS_IP=$(terraform output -raw jenkins_public_ip)
ssh -i your-key.pem ec2-user@$JENKINS_IP

# Get initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### Step 2.2: Initial Setup

1. Open Jenkins URL in browser
2. Enter initial admin password
3. Select "Install suggested plugins"
4. Create admin user
5. Confirm Jenkins URL

### Step 2.3: Install Additional Plugins

Navigate to: **Manage Jenkins → Plugins → Available**

Install:
- Docker Pipeline
- Kubernetes CLI
- AWS Steps
- SonarQube Scanner
- GitHub Integration
- Pipeline
- Blue Ocean (optional, for better UI)

Restart Jenkins after installation.

### Step 2.4: Configure Credentials

**Manage Jenkins → Credentials → System → Global credentials**

**Add AWS Credentials:**
- Kind: AWS Credentials
- ID: `aws-credentials`
- Access Key ID: (from IAM user or use IAM role)
- Secret Access Key: (from IAM user)

**Add GitHub SSH Key:**
- Kind: SSH Username with private key
- ID: `github-ssh-key`
- Username: `git`
- Private Key: (paste your GitHub SSH private key)

**Add SonarQube Token:**
- Kind: Secret text
- ID: `sonarqube-token`
- Secret: (will get from SonarQube in next phase)

### Step 2.5: Configure SonarQube Server

**Manage Jenkins → System → SonarQube servers**

- Name: `SonarQube`
- Server URL: (from Terraform output)
- Server authentication token: `sonarqube-token` (credential ID)

### Step 2.6: Configure Global Tools

**Manage Jenkins → Tools**

**SonarQube Scanner:**
- Name: `SonarScanner`
- Install automatically: Yes
- Version: Latest

**Docker:**
- Name: `docker`
- Install automatically: Yes

### Step 2.7: Create Pipeline Job

1. **New Item → Pipeline**
2. Name: `devops-platform-ci-cd`
3. **Pipeline:**
   - Definition: Pipeline script from SCM
   - SCM: Git
   - Repository URL: `https://github.com/your-org/app-repo.git`
   - Credentials: (if private repo)
   - Branch: `*/main`
   - Script Path: `Jenkinsfile`
4. **Build Triggers:**
   - GitHub hook trigger for GITScm polling: ✓
5. **Save**

## Phase 3: SonarQube Configuration (15 minutes)

### Step 3.1: Access SonarQube

```bash
# Get SonarQube URL
SONARQUBE_URL=$(terraform output -raw sonarqube_url)
echo "SonarQube URL: $SONARQUBE_URL"
```

Open in browser:
- Default credentials: `admin` / `admin`
- Change password on first login

### Step 3.2: Create Project

1. **Create new project**
2. Project key: `devops-platform`
3. Display name: `Production DevOps Platform`
4. Main branch: `main`

### Step 3.3: Generate Token

1. **My Account → Security → Generate Tokens**
2. Name: `jenkins`
3. Type: Global Analysis Token
4. Generate
5. **Copy token** (you won't see it again)
6. Add to Jenkins credentials as `sonarqube-token`

### Step 3.4: Configure Quality Gate

1. **Quality Gates → Create**
2. Name: `Production Gate`
3. Add conditions:
   - Coverage < 80% → Failed
   - Duplicated Lines (%) > 3% → Failed
   - Maintainability Rating worse than A → Failed
   - Reliability Rating worse than A → Failed
   - Security Rating worse than A → Failed
   - Security Hotspots Reviewed < 100% → Failed
4. **Set as Default**

## Phase 4: ArgoCD Installation (20 minutes)

### Step 4.1: Install ArgoCD

```bash
# Create namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for pods to be ready
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
```

### Step 4.2: Expose ArgoCD Server

```bash
# Patch service to LoadBalancer
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

# Get LoadBalancer URL
kubectl get svc argocd-server -n argocd
```

### Step 4.3: Get Admin Password

```bash
# Get initial admin password
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "ArgoCD Password: $ARGOCD_PASSWORD"

# Get ArgoCD URL
ARGOCD_URL=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "ArgoCD URL: http://$ARGOCD_URL"
```

### Step 4.4: Install ArgoCD CLI

```bash
# Download ArgoCD CLI
curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x /usr/local/bin/argocd

# Login
argocd login $ARGOCD_URL --username admin --password $ARGOCD_PASSWORD --insecure

# Change password
argocd account update-password
```

### Step 4.5: Add Git Repository

```bash
# Add gitops repository
argocd repo add https://github.com/your-org/gitops-repo.git \
    --username your-github-username \
    --password your-github-token
```

### Step 4.6: Deploy Applications

```bash
# Clone gitops repo
git clone https://github.com/your-org/gitops-repo.git
cd gitops-repo

# Update AWS account ID in manifests
find apps -name "*.yaml" -exec sed -i 's/<AWS_ACCOUNT_ID>/123456789012/g' {} \;

# Commit changes
git add .
git commit -m "Update AWS account ID"
git push origin main

# Deploy ArgoCD applications
kubectl apply -f argocd/dev-application.yaml
kubectl apply -f argocd/staging-application.yaml
kubectl apply -f argocd/prod-application.yaml

# Verify
argocd app list
argocd app get devops-platform-dev
```

## Phase 5: GitHub Configuration (10 minutes)

### Step 5.1: Configure Webhook for app-repo

1. Go to `app-repo` on GitHub
2. **Settings → Webhooks → Add webhook**
3. Payload URL: `http://<JENKINS_IP>:8080/github-webhook/`
4. Content type: `application/json`
5. Events: **Pull requests** and **Pushes**
6. Active: ✓
7. Add webhook

### Step 5.2: Configure Branch Protection for app-repo

1. **Settings → Branches → Add rule**
2. Branch name pattern: `main`
3. Require pull request reviews before merging: ✓
4. Require status checks to pass: ✓
   - Add: `continuous-integration/jenkins/pr-merge`
5. Require branches to be up to date: ✓
6. Include administrators: ✓
7. Create

### Step 5.3: Setup SSH Key for Jenkins

```bash
# On Jenkins server
ssh-keygen -t rsa -b 4096 -C "jenkins@devops-platform"

# Copy public key
cat ~/.ssh/id_rsa.pub

# Add to GitHub:
# Settings → SSH and GPG keys → New SSH key
# Paste public key

# Test connection
ssh -T git@github.com
```

## Phase 6: Enable AWS Bedrock (5 minutes)

### Step 6.1: Request Model Access

1. AWS Console → Bedrock
2. **Model access** (left sidebar)
3. **Manage model access**
4. Select: **Claude 3 Sonnet**
5. **Request model access**
6. Wait for approval (usually instant)

### Step 6.2: Verify Access

```bash
aws bedrock list-foundation-models --region us-east-1 | grep claude-3-sonnet
```

## Phase 7: Testing (30 minutes)

### Test 1: CI Pipeline

```bash
# Clone app repo
git clone https://github.com/your-org/app-repo.git
cd app-repo

# Create feature branch
git checkout -b feature/test-ci

# Make a change
echo "# Test CI" >> README.md

# Commit and push
git add .
git commit -m "Test CI pipeline"
git push origin feature/test-ci

# Create PR on GitHub
# Watch Jenkins build
# Verify SonarQube scan
# Verify quality gate passes
```

### Test 2: CD Pipeline

```bash
# Merge PR to main
# Watch Jenkins CD pipeline
# Verify image pushed to ECR
# Verify GitOps repo updated
# Watch ArgoCD sync

# Check deployment
kubectl get pods -n dev
kubectl get pods -n staging
kubectl get pods -n prod
```

### Test 3: Application Access

```bash
# Get LoadBalancer URLs
kubectl get svc -n dev
kubectl get svc -n staging
kubectl get svc -n prod

# Test endpoints
curl http://<dev-lb-url>/
curl http://<dev-lb-url>/health
curl http://<dev-lb-url>/api/users
```

### Test 4: AI Remediation

```bash
# Simulate pod failure
kubectl exec -n prod $(kubectl get pod -n prod -l app=devops-platform -o jsonpath='{.items[0].metadata.name}') -- kill 1

# Watch pod restart
kubectl get pods -n prod --watch

# Check CloudWatch alarm
aws cloudwatch describe-alarms --alarm-names devops-platform-prod-pod-failures

# Check Lambda logs
aws logs tail /aws/lambda/ai-remediation-prod --follow

# Verify remediation
kubectl get events -n prod --sort-by='.lastTimestamp'
```

## Phase 8: Monitoring Setup (15 minutes)

### Step 8.1: Create CloudWatch Dashboard

```bash
aws cloudwatch put-dashboard --dashboard-name devops-platform-prod --dashboard-body file://dashboard.json
```

**dashboard.json:**
```json
{
  "widgets": [
    {
      "type": "metric",
      "properties": {
        "metrics": [
          ["ContainerInsights", "pod_restart_count", {"stat": "Sum"}]
        ],
        "period": 300,
        "stat": "Sum",
        "region": "us-east-1",
        "title": "Pod Restarts"
      }
    }
  ]
}
```

### Step 8.2: Configure SNS Notifications

```bash
# Create SNS topic
aws sns create-topic --name devops-platform-alerts

# Subscribe email
aws sns subscribe \
    --topic-arn arn:aws:sns:us-east-1:123456789012:devops-platform-alerts \
    --protocol email \
    --notification-endpoint your-email@example.com

# Confirm subscription via email
```

## Troubleshooting

### Jenkins Can't Access EKS

```bash
# SSH to Jenkins server
ssh -i your-key.pem ec2-user@<JENKINS_IP>

# Configure kubectl
aws eks update-kubeconfig --region us-east-1 --name devops-platform-prod

# Test
kubectl get nodes

# If fails, check IAM role permissions
```

### ArgoCD Can't Sync

```bash
# Check application status
argocd app get devops-platform-prod

# Check logs
kubectl logs -n argocd deployment/argocd-application-controller

# Force sync
argocd app sync devops-platform-prod --force
```

### SonarQube Quality Gate Fails

```bash
# Check SonarQube logs
ssh -i your-key.pem ubuntu@<SONARQUBE_IP>
sudo journalctl -u sonarqube -f

# Check Jenkins console output
# Look for SonarQube scanner errors
```

### Lambda Can't Invoke Bedrock

```bash
# Check IAM role permissions
aws iam get-role-policy --role-name ai-remediation-prod-role --policy-name ai-remediation-prod-policy

# Check Bedrock access
aws bedrock list-foundation-models --region us-east-1

# Check Lambda logs
aws logs tail /aws/lambda/ai-remediation-prod --follow
```

## Maintenance

### Daily Tasks
- Monitor CloudWatch dashboards
- Review failed builds
- Check ArgoCD sync status

### Weekly Tasks
- Review SonarQube quality trends
- Update dependencies
- Review cost reports

### Monthly Tasks
- Rotate secrets
- Update Terraform modules
- Review and optimize resources
- Backup verification

## Cleanup

```bash
# Delete ArgoCD applications
argocd app delete devops-platform-dev --cascade
argocd app delete devops-platform-staging --cascade
argocd app delete devops-platform-prod --cascade

# Destroy infrastructure
cd terraform-infra/environments/prod
terraform destroy -var="key_name=your-ssh-key-name" -auto-approve

cd ../staging
terraform destroy -auto-approve

cd ../dev
terraform destroy -auto-approve

# Delete S3 bucket
aws s3 rb s3://devops-platform-terraform-state --force

# Delete DynamoDB table
aws dynamodb delete-table --table-name terraform-state-lock
```

## Next Steps

1. **Add HTTPS**: Configure ALB with ACM certificate
2. **Add Monitoring**: Install Prometheus + Grafana
3. **Add Tracing**: Implement Jaeger
4. **Add Service Mesh**: Deploy Istio
5. **Add Policy Enforcement**: Install OPA Gatekeeper
6. **Add Cost Management**: Deploy Kubecost
7. **Add Chaos Engineering**: Install Chaos Mesh

## Support

For issues or questions:
1. Check troubleshooting section
2. Review logs (Jenkins, ArgoCD, CloudWatch)
3. Verify IAM permissions
4. Check security groups
5. Validate network connectivity
