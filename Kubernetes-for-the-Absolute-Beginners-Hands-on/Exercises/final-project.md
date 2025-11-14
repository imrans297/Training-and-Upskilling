# Final Project: Multi-Tier Web Application

## Project Overview
Deploy a complete multi-tier application with frontend, backend, and database.

## Requirements

### 1. Database Layer (MySQL)
- StatefulSet with 1 replica
- PersistentVolume for data (5Gi)
- Secret for root password
- Headless service
- Resource limits: 512Mi memory, 500m CPU

### 2. Backend Layer (API)
- Deployment with 3 replicas
- ConfigMap for database connection
- Secret for database credentials
- ClusterIP service on port 8080
- Health checks (liveness/readiness)
- Resource limits: 256Mi memory, 250m CPU

### 3. Frontend Layer (Web)
- Deployment with 2 replicas
- ConfigMap for API endpoint
- NodePort service on port 80
- Resource limits: 128Mi memory, 200m CPU

### 4. Namespace Organization
- Create namespace: `webapp`
- Apply ResourceQuota:
  - Max 10 pods
  - Max 4 CPU
  - Max 8Gi memory
- Apply LimitRange with defaults

### 5. Monitoring
- Create CronJob for health checks (every 5 minutes)
- Log aggregation setup

### 6. Security
- Network Policy: Frontend → Backend only
- Network Policy: Backend → Database only
- No direct Frontend → Database access

## Implementation Steps

### Step 1: Setup Namespace
```bash
kubectl create namespace webapp
# Apply ResourceQuota and LimitRange
```

### Step 2: Deploy Database
```bash
# Create Secret for MySQL
# Create PV and PVC
# Deploy MySQL StatefulSet
# Create Headless Service
```

### Step 3: Deploy Backend
```bash
# Create ConfigMap for DB connection
# Create Deployment
# Create ClusterIP Service
```

### Step 4: Deploy Frontend
```bash
# Create ConfigMap for API endpoint
# Create Deployment
# Create NodePort Service
```

### Step 5: Apply Network Policies
```bash
# Create policies for tier isolation
```

### Step 6: Testing
```bash
# Test frontend access
# Test backend API
# Test database connectivity
# Verify network policies
```

## Deliverables
1. All YAML manifests
2. Deployment script
3. Testing documentation
4. Architecture diagram
5. Cleanup script

## Bonus Challenges
- Implement Ingress for external access
- Add HPA for auto-scaling
- Implement backup CronJob
- Add monitoring with Prometheus
- Implement rolling updates with zero downtime

## Evaluation Criteria
- [ ] All components deployed successfully
- [ ] Services communicate correctly
- [ ] Resource limits applied
- [ ] Network policies enforced
- [ ] Health checks working
- [ ] Data persists after pod restart
- [ ] Application accessible externally
- [ ] Proper namespace organization
- [ ] Security best practices followed
- [ ] Documentation complete
