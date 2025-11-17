# Lab 1: Pods and Basic Operations

## What We're Achieving
Master Kubernetes Pods - the smallest deployable units in Kubernetes. Learn to create, manage, and troubleshoot pods using imperative commands.

## What We're Doing
- Creating pods using kubectl run command
- Understanding pod lifecycle and states
- Executing commands inside pods
- Viewing logs and debugging pods
- Managing pod resources and constraints

## Prerequisites
- EKS cluster with worker nodes running
- kubectl configured and working
- Basic understanding of containers

## Definitions

### Pod
A Pod is the smallest deployable unit in Kubernetes that can hold one or more containers. Containers in a pod share:
- Network (IP address and port space)
- Storage volumes
- Lifecycle

### Pod States
- **Pending**: Pod accepted but not yet scheduled
- **Running**: Pod bound to node and containers created
- **Succeeded**: All containers terminated successfully
- **Failed**: All containers terminated, at least one failed
- **Unknown**: Pod state cannot be determined

## Lab Exercises

### Exercise 1: Basic Pod Creation
```bash
# Create a simple nginx pod
kubectl run nginx-pod --image=nginx --port=80

# Verify pod creation
kubectl get pods
kubectl get pods -o wide

# Check pod details
kubectl describe pod nginx-pod
```

**Expected Output:**
```
NAME        READY   STATUS    RESTARTS   AGE
nginx-pod   1/1     Running   0          30s
```

### Exercise 2: Pod Interaction
```bash
# View pod logs
kubectl logs nginx-pod

# Execute commands inside pod
kubectl exec nginx-pod -- ls /usr/share/nginx/html
kubectl exec nginx-pod -- cat /etc/nginx/nginx.conf

# Interactive shell access
kubectl exec -it nginx-pod -- /bin/bash
# Inside pod: curl localhost, exit
```

### Exercise 3: Port Forwarding
```bash
# Forward local port to pod
kubectl port-forward nginx-pod 8080:80

# Test in another terminal
curl http://localhost:8080
# You should see nginx welcome page
```

### Exercise 4: Pod with Resource Limits
```bash
# Create pod with resource constraints
kubectl run resource-pod --image=nginx \
  --requests='cpu=100m,memory=128Mi' \
  --limits='cpu=200m,memory=256Mi'

# Check resource allocation
kubectl describe pod resource-pod | grep -A 10 "Requests\|Limits"
```

### Exercise 5: Pod with Environment Variables
```bash
# Create pod with environment variables
kubectl run env-pod --image=nginx \
  --env="ENV_VAR1=value1" \
  --env="ENV_VAR2=value2"

# Verify environment variables
kubectl exec env-pod -- env | grep ENV_VAR
```

### Exercise 6: Multi-Container Pod (Advanced)
```bash
# Create a pod with sidecar container (using YAML for this)
cat << EOF | kubectl apply -f -
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
  - name: sidecar
    image: busybox
    command: ['sh', '-c', 'while true; do echo "Sidecar running"; sleep 30; done']
EOF

# Check both containers
kubectl get pod multi-container-pod
kubectl logs multi-container-pod -c nginx
kubectl logs multi-container-pod -c sidecar
```

### Exercise 7: Pod Troubleshooting
```bash
# Create a pod that will fail
kubectl run failing-pod --image=nginx:invalid-tag

# Troubleshoot the issue
kubectl get pods
kubectl describe pod failing-pod
kubectl logs failing-pod

# Fix by deleting and recreating
kubectl delete pod failing-pod
kubectl run failing-pod --image=nginx
```

## Troubleshooting Guide

### Common Issues
1. **ImagePullBackOff**: Invalid image name or tag
2. **CrashLoopBackOff**: Container keeps crashing
3. **Pending**: Insufficient resources or scheduling issues
4. **ContainerCreating**: Still pulling image or mounting volumes

### Debugging Commands
```bash
# Get detailed pod information
kubectl describe pod <pod-name>

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp

# View logs
kubectl logs <pod-name>
kubectl logs <pod-name> --previous  # Previous container logs

# Check resource usage
kubectl top pod <pod-name>
```

## Cleanup
```bash
# Delete all pods created in this lab
kubectl delete pod nginx-pod resource-pod env-pod multi-container-pod failing-pod

# Verify cleanup
kubectl get pods
```

## Cost Considerations
- Pods themselves don't incur additional costs
- Resource usage (CPU/Memory) affects node utilization
- Practice on existing cluster to minimize costs

## Key Takeaways
1. Pods are ephemeral - they can be created and destroyed
2. Each pod gets its own IP address
3. Containers in a pod share network and storage
4. Use `kubectl describe` and `kubectl logs` for troubleshooting
5. Resource limits prevent pods from consuming too many resources

## Next Steps
- Move to Lab 2: ReplicaSets and Scaling
- Practice pod operations until comfortable
- Understand pod networking and storage concepts