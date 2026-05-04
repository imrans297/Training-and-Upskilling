# Architecture Deep Dive

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         DEVELOPER WORKFLOW                           │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                    ┌─────────────▼──────────────┐
                    │   GitHub (app-repo)        │
                    │   - Feature branches       │
                    │   - Pull Requests          │
                    └─────────────┬──────────────┘
                                  │
                    ┌─────────────▼──────────────┐
                    │   Jenkins CI Pipeline      │
                    │   - Unit Tests             │
                    │   - SonarQube Scan         │
                    │   - Security Scan          │
                    │   - Docker Build           │
                    └─────────────┬──────────────┘
                                  │
                    ┌─────────────▼──────────────┐
                    │   AWS ECR                  │
                    │   - Image Storage          │
                    │   - Vulnerability Scan     │
                    └─────────────┬──────────────┘
                                  │
                    ┌─────────────▼──────────────┐
                    │   GitHub (gitops-repo)     │
                    │   - K8s Manifests          │
                    │   - Image Tag Updates      │
                    └─────────────┬──────────────┘
                                  │
                    ┌─────────────▼──────────────┐
                    │   ArgoCD                   │
                    │   - Auto Sync (dev/stg)    │
                    │   - Manual Sync (prod)     │
                    └─────────────┬──────────────┘
                                  │
        ┌─────────────────────────┼─────────────────────────┐
        │                         │                         │
┌───────▼────────┐      ┌─────────▼────────┐      ┌───────▼────────┐
│  EKS Dev       │      │  EKS Staging     │      │  EKS Prod      │
│  - 2 replicas  │      │  - 3 replicas    │      │  - 5 replicas  │
│  - Spot        │      │  - On-Demand     │      │  - On-Demand   │
└───────┬────────┘      └─────────┬────────┘      └───────┬────────┘
        │                         │                         │
        └─────────────────────────┼─────────────────────────┘
                                  │
                    ┌─────────────▼──────────────┐
                    │   CloudWatch               │
                    │   - Logs                   │
                    │   - Metrics                │
                    │   - Alarms                 │
                    └─────────────┬──────────────┘
                                  │
                    ┌─────────────▼──────────────┐
                    │   EventBridge              │
                    │   - Alarm Trigger          │
                    └─────────────┬──────────────┘
                                  │
                    ┌─────────────▼──────────────┐
                    │   Lambda Function          │
                    │   - Fetch Logs             │
                    │   - AI Analysis            │
                    │   - Execute Remediation    │
                    └─────────────┬──────────────┘
                                  │
                    ┌─────────────▼──────────────┐
                    │   AWS Bedrock (Claude 3)   │
                    │   - Log Analysis           │
                    │   - Root Cause Detection   │
                    │   - Remediation Suggestion │
                    └────────────────────────────┘
```

## Component Details

### 1. Development Workflow

**Feature Branch Strategy:**
- Developers work on feature branches
- Branch naming: `feature/`, `bugfix/`, `hotfix/`
- No direct commits to main

**Pull Request Process:**
1. Developer creates PR
2. GitHub webhook triggers Jenkins
3. Jenkins runs CI pipeline
4. SonarQube quality gate must pass
5. Security scan must pass
6. Peer review required
7. Approval required before merge

### 2. CI Pipeline (Jenkins)

**Stages:**

1. **Checkout**: Clone repository
2. **Install Dependencies**: Python venv + pip install
3. **Unit Tests**: pytest with coverage
4. **SonarQube Analysis**: Code quality scan
5. **Quality Gate**: Enforce thresholds
6. **Security Scan**: Trivy for vulnerabilities
7. **Build Docker Image**: Multi-stage build
8. **Push to ECR**: Tag with git commit + build number
9. **Update GitOps Repo**: Update image tag in manifests
10. **Trigger ArgoCD**: Notify for sync

**Quality Gates:**
- Code coverage > 80%
- No critical vulnerabilities
- No code smells > threshold
- Maintainability rating A

### 3. CD Pipeline (ArgoCD)

**GitOps Principles:**
- Git as single source of truth
- Declarative configuration
- Automated sync
- Drift detection

**Environment Strategy:**

| Environment | Sync Policy | Approval | Replicas |
|-------------|-------------|----------|----------|
| Dev | Automated | None | 2 |
| Staging | Automated | None | 3 |
| Production | Manual | Required | 5 |

**Deployment Strategies:**
- Rolling Update (default)
- Blue-Green (optional with Argo Rollouts)
- Canary (optional with Argo Rollouts)

### 4. Infrastructure (Terraform)

**Modular Architecture:**

```
modules/
├── vpc/           # Network infrastructure
├── eks/           # Kubernetes cluster
├── ecr/           # Container registry
├── iam/           # Roles and policies
├── jenkins/       # CI server
├── sonarqube/     # Code quality server
└── lambda/        # AI remediation function

environments/
├── dev/           # Development config
├── staging/       # Staging config
└── prod/          # Production config
```

**State Management:**
- Backend: S3 + DynamoDB
- State locking enabled
- Separate state per environment
- Encrypted at rest

### 5. Monitoring & Observability

**CloudWatch:**
- Container Insights for EKS
- Application logs
- Custom metrics
- Alarms for failures

**Metrics Tracked:**
- Pod restart count
- CPU/Memory utilization
- Request latency
- Error rate
- Deployment frequency
- MTTR (Mean Time To Recovery)

### 6. AI-Powered Remediation

**Flow:**

1. **Failure Detection**
   - Pod crashes/restarts
   - CloudWatch alarm triggers

2. **Log Collection**
   - Lambda fetches last 10 minutes of logs
   - Filters relevant error messages

3. **AI Analysis**
   - Sends logs to Bedrock Claude 3
   - Prompt engineering for structured output
   - Returns: root_cause, action, confidence

4. **Remediation Execution**
   - If confidence = high → execute action
   - Actions: restart_pods, rollback_deployment, scale_up
   - Uses kubectl via SSM or K8s API

5. **Notification**
   - SNS notification to team
   - Logs action taken
   - Updates incident tracking

**AI Prompt Template:**
```
You are a Kubernetes DevOps expert analyzing application failures.

Alarm: {alarm_name}
Recent Logs: {logs}

Analyze and provide:
1. Root cause (one sentence)
2. Remediation action: [restart_pods, rollback_deployment, scale_up, none]
3. Confidence: [high, medium, low]

Response format: {"root_cause": "...", "action": "...", "confidence": "..."}
```

## Security Architecture

### Network Security

**VPC Design:**
- Public subnets: Jenkins, SonarQube, NAT Gateway, LoadBalancer
- Private subnets: EKS worker nodes
- No direct internet access for worker nodes
- NAT Gateway for outbound traffic

**Security Groups:**
- Jenkins: 8080 (HTTP), 22 (SSH)
- SonarQube: 9000 (HTTP), 22 (SSH)
- EKS: Managed by AWS, restricted to cluster communication
- LoadBalancer: 80 (HTTP), 443 (HTTPS)

### IAM Security

**Principle of Least Privilege:**

**Jenkins Role:**
- ECR: Push/pull images
- EKS: Describe cluster
- S3: Artifact storage
- SNS: Notifications
- Secrets Manager: Read secrets

**Lambda Role:**
- CloudWatch Logs: Read
- Bedrock: Invoke model
- EKS: Describe cluster
- SSM: Send commands
- SNS: Publish notifications

**EKS Node Role:**
- ECR: Pull images
- CloudWatch: Send logs/metrics
- EKS: Register with control plane

### Secrets Management

**AWS Secrets Manager:**
- Database credentials
- API keys
- Third-party tokens

**Jenkins Credentials:**
- AWS credentials (IAM role preferred)
- GitHub SSH key
- SonarQube token

**Kubernetes Secrets:**
- Application secrets
- TLS certificates
- Service account tokens

## Scalability

### Horizontal Pod Autoscaling

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: devops-platform-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: devops-platform
  minReplicas: 5
  maxReplicas: 20
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

### Cluster Autoscaling

- EKS managed node groups
- Auto-scaling based on pod resource requests
- Min: 3 nodes, Max: 10 nodes
- Spot instances for cost optimization (dev/staging)

### Database Scaling

- RDS with read replicas
- Aurora Serverless for variable workloads
- ElastiCache for caching

## Disaster Recovery

### Backup Strategy

**EKS:**
- Velero for cluster backups
- Daily snapshots
- Cross-region replication

**Databases:**
- Automated RDS snapshots
- Point-in-time recovery
- Cross-region replication

**GitOps:**
- Git history as backup
- Easy rollback via git revert

### Recovery Procedures

**Application Failure:**
1. ArgoCD rollback to previous version
2. Or git revert + ArgoCD sync

**Infrastructure Failure:**
1. Terraform recreate from state
2. ArgoCD redeploy applications

**Data Loss:**
1. Restore from RDS snapshot
2. Replay from backup

## Performance Optimization

### Application Level

- Gunicorn with multiple workers
- Connection pooling
- Caching with Redis
- Async processing with Celery

### Infrastructure Level

- EKS node instance types optimized for workload
- EBS volumes with provisioned IOPS
- CloudFront CDN for static assets
- Application Load Balancer with connection draining

### Cost Optimization

- Spot instances for non-production
- Auto-scaling to match demand
- ECR lifecycle policies
- CloudWatch log retention policies
- Reserved instances for production

## Compliance & Auditing

### Audit Trail

- Git history for all changes
- CloudTrail for AWS API calls
- Jenkins build logs
- ArgoCD sync history

### Compliance

- SOC 2 compliance ready
- GDPR data handling
- HIPAA (if needed)
- PCI DSS (if handling payments)

## Future Enhancements

1. **Service Mesh**: Istio for advanced traffic management
2. **Observability**: Prometheus + Grafana
3. **Tracing**: Jaeger for distributed tracing
4. **Policy Enforcement**: OPA Gatekeeper
5. **Progressive Delivery**: Flagger for canary deployments
6. **Multi-cluster**: Federated ArgoCD
7. **Cost Management**: Kubecost for cost visibility
8. **Chaos Engineering**: Chaos Mesh for resilience testing
