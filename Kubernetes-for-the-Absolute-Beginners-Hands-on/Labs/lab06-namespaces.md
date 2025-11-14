# Lab 6: Namespaces and Resource Quotas

## Objective
Learn to organize resources using namespaces and apply resource quotas.

## Tasks

### Task 1: Create Namespaces
```bash
# Create namespaces
kubectl create namespace dev
kubectl create namespace staging
kubectl create namespace prod

# List namespaces
kubectl get namespaces
kubectl get ns
```

### Task 2: Create Resources in Namespace
```bash
# Create deployment in dev namespace
kubectl create deployment nginx --image=nginx -n dev

# Create service in dev namespace
kubectl expose deployment nginx --port=80 -n dev

# Verify
kubectl get all -n dev
```

### Task 3: Set Default Namespace
```bash
# Set default namespace to dev
kubectl config set-context --current --namespace=dev

# Verify
kubectl config view --minify | grep namespace

# Now commands use dev namespace by default
kubectl get pods
```

### Task 4: Create Namespace from YAML
Create `namespace.yaml`:
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: testing
  labels:
    env: test
```

Apply:
```bash
kubectl apply -f namespace.yaml
kubectl get ns testing --show-labels
```

### Task 5: Resource Quota
Create `resource-quota.yaml`:
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: dev-quota
  namespace: dev
spec:
  hard:
    requests.cpu: "4"
    requests.memory: 8Gi
    limits.cpu: "8"
    limits.memory: 16Gi
    pods: "10"
    services: "5"
    persistentvolumeclaims: "3"
```

Apply:
```bash
kubectl apply -f resource-quota.yaml
kubectl get quota -n dev
kubectl describe quota dev-quota -n dev
```

### Task 6: Test Resource Quota
Create `pod-with-resources.yaml`:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: quota-test-pod
  namespace: dev
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
kubectl apply -f pod-with-resources.yaml
kubectl describe quota dev-quota -n dev
```

### Task 7: LimitRange
Create `limit-range.yaml`:
```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: dev-limits
  namespace: dev
spec:
  limits:
  - max:
      cpu: "2"
      memory: 2Gi
    min:
      cpu: "100m"
      memory: 64Mi
    default:
      cpu: "500m"
      memory: 256Mi
    defaultRequest:
      cpu: "250m"
      memory: 128Mi
    type: Container
```

Apply:
```bash
kubectl apply -f limit-range.yaml
kubectl get limitrange -n dev
kubectl describe limitrange dev-limits -n dev
```

### Task 8: Cross-Namespace Communication
```bash
# Create service in dev namespace
kubectl create deployment backend --image=nginx -n dev
kubectl expose deployment backend --port=80 -n dev

# Create pod in staging namespace
kubectl run test-pod --image=busybox -n staging -it --rm -- /bin/sh

# Inside pod, access service from dev namespace
# wget -O- backend.dev.svc.cluster.local
```

### Task 9: Copy Resources Between Namespaces
```bash
# Get deployment YAML from dev
kubectl get deployment nginx -n dev -o yaml > nginx-deploy.yaml

# Edit namespace in YAML (change to staging)
# Apply to staging
kubectl apply -f nginx-deploy.yaml -n staging

# Verify
kubectl get deployments -n staging
```

### Task 10: Namespace Isolation
Create `network-policy.yaml`:
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-from-other-namespaces
  namespace: prod
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector: {}
```

Apply:
```bash
kubectl apply -f network-policy.yaml
kubectl get networkpolicy -n prod
```

## Cleanup
```bash
# Reset default namespace
kubectl config set-context --current --namespace=default

# Delete namespaces (deletes all resources)
kubectl delete namespace dev
kubectl delete namespace staging
kubectl delete namespace prod
kubectl delete namespace testing
```

## Verification
- [ ] Created multiple namespaces
- [ ] Created resources in specific namespace
- [ ] Set default namespace
- [ ] Applied resource quota
- [ ] Applied limit range
- [ ] Tested cross-namespace communication
- [ ] Applied network policy
