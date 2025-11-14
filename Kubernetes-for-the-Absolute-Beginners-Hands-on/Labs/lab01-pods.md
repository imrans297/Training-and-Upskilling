# Lab 1: Working with Pods

## Objective
Learn to create, manage, and troubleshoot Kubernetes pods.

## Prerequisites
- Kubernetes cluster running
- kubectl configured

## Tasks

### Task 1: Create a Simple Pod
```bash
# Create nginx pod
kubectl run nginx-pod --image=nginx:latest

# Verify pod is running
kubectl get pods

# Get detailed information
kubectl get pods -o wide
```

### Task 2: Create Pod from YAML
Create `nginx-pod.yaml`:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-yaml-pod
  labels:
    app: nginx
    env: dev
spec:
  containers:
  - name: nginx
    image: nginx:latest
    ports:
    - containerPort: 80
```

Apply:
```bash
kubectl apply -f nginx-pod.yaml
kubectl get pods
```

### Task 3: Access Pod
```bash
# Describe pod
kubectl describe pod nginx-pod

# View logs
kubectl logs nginx-pod

# Execute command in pod
kubectl exec nginx-pod -- nginx -v

# Interactive shell
kubectl exec -it nginx-pod -- /bin/bash
# Inside pod: curl localhost
# Exit: exit
```

### Task 4: Port Forwarding
```bash
# Forward local port to pod
kubectl port-forward nginx-pod 8080:80

# Open browser: http://localhost:8080
# Or: curl http://localhost:8080
```

### Task 5: Multi-Container Pod
Create `multi-container-pod.yaml`:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: multi-container-pod
spec:
  containers:
  - name: nginx
    image: nginx
    ports:
    - containerPort: 80
  - name: busybox
    image: busybox
    command: ['sh', '-c', 'while true; do echo Hello; sleep 10; done']
```

Apply and test:
```bash
kubectl apply -f multi-container-pod.yaml
kubectl logs multi-container-pod -c nginx
kubectl logs multi-container-pod -c busybox
kubectl exec -it multi-container-pod -c busybox -- /bin/sh
```

### Task 6: Pod with Environment Variables
Create `env-pod.yaml`:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: env-pod
spec:
  containers:
  - name: nginx
    image: nginx
    env:
    - name: ENV_NAME
      value: "production"
    - name: APP_VERSION
      value: "1.0"
```

Apply and verify:
```bash
kubectl apply -f env-pod.yaml
kubectl exec env-pod -- env | grep ENV_NAME
kubectl exec env-pod -- env | grep APP_VERSION
```

### Task 7: Troubleshooting
```bash
# Check pod status
kubectl get pods

# Describe pod for events
kubectl describe pod nginx-pod

# View logs
kubectl logs nginx-pod

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp
```

## Cleanup
```bash
kubectl delete pod nginx-pod
kubectl delete pod nginx-yaml-pod
kubectl delete pod multi-container-pod
kubectl delete pod env-pod
```

## Verification
- [ ] Created pod using kubectl run
- [ ] Created pod from YAML file
- [ ] Accessed pod shell
- [ ] Viewed pod logs
- [ ] Port forwarded to pod
- [ ] Created multi-container pod
- [ ] Set environment variables
