# Lab 2: Working with Deployments

## Objective
Learn to create, scale, update, and rollback deployments.

## Tasks

### Task 1: Create Deployment
```bash
# Create deployment
kubectl create deployment nginx-deploy --image=nginx:1.19 --replicas=3

# Verify
kubectl get deployments
kubectl get pods
kubectl get rs
```

### Task 2: Create Deployment from YAML
Create `nginx-deployment.yaml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp-deployment
  labels:
    app: webapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
        app: webapp
    spec:
      containers:
      - name: webapp
        image: nginx:1.19
        ports:
        - containerPort: 80
```

Apply:
```bash
kubectl apply -f nginx-deployment.yaml
kubectl get deployments
kubectl get pods -l app=webapp
```

### Task 3: Scale Deployment
```bash
# Scale up
kubectl scale deployment nginx-deploy --replicas=5
kubectl get pods

# Scale down
kubectl scale deployment nginx-deploy --replicas=2
kubectl get pods

# Watch scaling
kubectl get pods -w
```

### Task 4: Update Deployment
```bash
# Update image
kubectl set image deployment/nginx-deploy nginx=nginx:1.20

# Check rollout status
kubectl rollout status deployment/nginx-deploy

# View rollout history
kubectl rollout history deployment/nginx-deploy

# Describe deployment
kubectl describe deployment nginx-deploy
```

### Task 5: Rollback Deployment
```bash
# Update to bad image
kubectl set image deployment/nginx-deploy nginx=nginx:invalid

# Check status
kubectl rollout status deployment/nginx-deploy
kubectl get pods

# Rollback
kubectl rollout undo deployment/nginx-deploy

# Verify
kubectl rollout status deployment/nginx-deploy
kubectl get pods
```

### Task 6: Rollback to Specific Revision
```bash
# View history
kubectl rollout history deployment/nginx-deploy

# Rollback to revision 1
kubectl rollout undo deployment/nginx-deploy --to-revision=1

# Verify
kubectl rollout status deployment/nginx-deploy
```

### Task 7: Pause and Resume Rollout
```bash
# Pause rollout
kubectl rollout pause deployment/nginx-deploy

# Make changes
kubectl set image deployment/nginx-deploy nginx=nginx:1.21
kubectl set resources deployment/nginx-deploy -c=nginx --limits=cpu=200m,memory=512Mi

# Resume rollout
kubectl rollout resume deployment/nginx-deploy

# Check status
kubectl rollout status deployment/nginx-deploy
```

### Task 8: Deployment with Resource Limits
Create `resource-deployment.yaml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: resource-deploy
spec:
  replicas: 2
  selector:
    matchLabels:
      app: resource-app
  template:
    metadata:
      labels:
        app: resource-app
    spec:
      containers:
      - name: nginx
        image: nginx
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
```

Apply:
```bash
kubectl apply -f resource-deployment.yaml
kubectl describe deployment resource-deploy
```

## Cleanup
```bash
kubectl delete deployment nginx-deploy
kubectl delete deployment webapp-deployment
kubectl delete deployment resource-deploy
```

## Verification
- [ ] Created deployment with replicas
- [ ] Scaled deployment up and down
- [ ] Updated deployment image
- [ ] Rolled back deployment
- [ ] Paused and resumed rollout
- [ ] Set resource limits
