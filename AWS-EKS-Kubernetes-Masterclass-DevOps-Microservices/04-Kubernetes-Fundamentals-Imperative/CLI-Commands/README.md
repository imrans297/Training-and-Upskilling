# Kubernetes CLI Commands - Imperative Approach

## What We're Achieving
Master kubectl imperative commands for direct Kubernetes resource management without YAML files.

## What We're Doing
Learning to create, manage, and troubleshoot Kubernetes resources using only command-line instructions.

## Prerequisites
- EKS cluster with worker nodes
- kubectl configured and working

## Core kubectl Commands

### Cluster Information
```bash
# Check cluster info
kubectl cluster-info
kubectl get nodes
kubectl get nodes -o wide

# Check cluster version
kubectl version --short
```

### Pod Operations
```bash
# Create pod imperatively
kubectl run nginx-pod --image=nginx --port=80

# List pods
kubectl get pods
kubectl get pods -o wide
kubectl get pods --show-labels

# Describe pod
kubectl describe pod nginx-pod

# Get pod logs
kubectl logs nginx-pod
kubectl logs nginx-pod -f  # follow logs

# Execute commands in pod
kubectl exec nginx-pod -- ls /
kubectl exec -it nginx-pod -- /bin/bash

# Port forward
kubectl port-forward nginx-pod 8080:80

# Delete pod
kubectl delete pod nginx-pod
```

### ReplicaSet Operations
```bash
# Create deployment (creates ReplicaSet automatically)
kubectl create deployment nginx-deploy --image=nginx --replicas=3

# Scale ReplicaSet
kubectl scale deployment nginx-deploy --replicas=5

# Get ReplicaSets
kubectl get rs
kubectl get rs -o wide

# Describe ReplicaSet
kubectl describe rs nginx-deploy-<hash>
```

### Deployment Operations
```bash
# Create deployment
kubectl create deployment web-app --image=nginx:1.20

# Scale deployment
kubectl scale deployment web-app --replicas=4

# Update image
kubectl set image deployment/web-app nginx=nginx:1.21

# Check rollout status
kubectl rollout status deployment/web-app

# View rollout history
kubectl rollout history deployment/web-app

# Rollback deployment
kubectl rollout undo deployment/web-app

# Rollback to specific revision
kubectl rollout undo deployment/web-app --to-revision=1
```

### Service Operations
```bash
# Expose deployment as ClusterIP service
kubectl expose deployment web-app --port=80 --target-port=80

# Create NodePort service
kubectl expose deployment web-app --type=NodePort --port=80 --target-port=80 --name=web-nodeport

# Create LoadBalancer service
kubectl expose deployment web-app --type=LoadBalancer --port=80 --target-port=80 --name=web-lb

# Get services
kubectl get svc
kubectl get svc -o wide

# Describe service
kubectl describe svc web-app
```

### Namespace Operations
```bash
# List namespaces
kubectl get namespaces

# Create namespace
kubectl create namespace dev-env

# Create resources in namespace
kubectl run nginx --image=nginx -n dev-env

# Set default namespace
kubectl config set-context --current --namespace=dev-env

# Delete namespace
kubectl delete namespace dev-env
```

### Label Operations
```bash
# Create pod with labels
kubectl run labeled-pod --image=nginx --labels="env=prod,tier=frontend"

# Show labels
kubectl get pods --show-labels

# Filter by labels
kubectl get pods -l env=prod
kubectl get pods -l tier=frontend
kubectl get pods -l 'env in (prod,dev)'

# Add label to existing resource
kubectl label pod labeled-pod version=v1

# Remove label
kubectl label pod labeled-pod version-

# Update label
kubectl label pod labeled-pod env=staging --overwrite
```

### ConfigMap Operations
```bash
# Create ConfigMap from literal values
kubectl create configmap app-config --from-literal=database_url=mysql://localhost:3306

# Create ConfigMap from file
echo "app.properties" > app.properties
echo "debug=true" >> app.properties
kubectl create configmap app-props --from-file=app.properties

# Get ConfigMaps
kubectl get configmaps
kubectl describe configmap app-config
```

### Secret Operations
```bash
# Create secret from literal
kubectl create secret generic db-secret --from-literal=username=admin --from-literal=password=secret123

# Create secret from file
echo -n 'admin' > username.txt
echo -n 'secret123' > password.txt
kubectl create secret generic file-secret --from-file=username.txt --from-file=password.txt

# Get secrets
kubectl get secrets
kubectl describe secret db-secret

# View secret data (base64 encoded)
kubectl get secret db-secret -o yaml
```

### Troubleshooting Commands
```bash
# Get events
kubectl get events
kubectl get events --sort-by=.metadata.creationTimestamp

# Check resource usage
kubectl top nodes
kubectl top pods

# Debug pod issues
kubectl describe pod <pod-name>
kubectl logs <pod-name> --previous

# Get all resources
kubectl get all
kubectl get all -n kube-system

# Check API resources
kubectl api-resources
kubectl explain pod
kubectl explain deployment.spec
```

## Practice Exercises

### Exercise 1: Pod Lifecycle
1. Create an nginx pod
2. Check its status and logs
3. Execute commands inside it
4. Delete and recreate

### Exercise 2: Scaling Applications
1. Create a deployment with 1 replica
2. Scale to 5 replicas
3. Scale down to 2 replicas
4. Observe pod creation/deletion

### Exercise 3: Service Discovery
1. Create two deployments
2. Expose them as services
3. Test connectivity between them
4. Try different service types

### Exercise 4: Rolling Updates
1. Create deployment with nginx:1.20
2. Update to nginx:1.21
3. Monitor rollout progress
4. Rollback to previous version

## Cost Considerations
- Commands are free - you only pay for underlying infrastructure
- Practice on existing EKS cluster
- Clean up resources after practice: `kubectl delete all --all`

## Next Steps
- Practice these commands regularly
- Move to Labs for structured exercises
- Learn declarative approach with YAML files