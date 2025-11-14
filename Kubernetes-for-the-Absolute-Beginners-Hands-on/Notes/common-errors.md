# Common Kubernetes Errors and Solutions

## ImagePullBackOff
**Error:** Cannot pull container image

**Causes:**
- Image doesn't exist
- Wrong image name/tag
- Private registry without credentials
- Network issues

**Solutions:**
```bash
# Check image name
kubectl describe pod <pod-name> | grep Image

# Create image pull secret
kubectl create secret docker-registry regcred \
  --docker-server=<registry> \
  --docker-username=<user> \
  --docker-password=<pass>

# Use in pod spec
imagePullSecrets:
- name: regcred
```

## CrashLoopBackOff
**Error:** Container keeps crashing

**Causes:**
- Application error
- Missing dependencies
- Wrong command/args
- Resource limits too low

**Solutions:**
```bash
# Check logs
kubectl logs <pod-name>
kubectl logs <pod-name> --previous

# Check events
kubectl describe pod <pod-name>

# Increase resources
resources:
  limits:
    memory: "512Mi"
    cpu: "500m"
```

## Pending Pods
**Error:** Pod stuck in Pending state

**Causes:**
- Insufficient resources
- Node selector mismatch
- PVC not bound
- Taints/tolerations

**Solutions:**
```bash
# Check events
kubectl describe pod <pod-name>

# Check node resources
kubectl top nodes
kubectl describe nodes

# Check PVC
kubectl get pvc
```

## Service Not Accessible
**Error:** Cannot access service

**Causes:**
- Wrong selector labels
- No endpoints
- Network policy blocking
- Port mismatch

**Solutions:**
```bash
# Check service
kubectl describe svc <service-name>

# Check endpoints
kubectl get endpoints <service-name>

# Check pod labels
kubectl get pods --show-labels

# Test connectivity
kubectl run test --image=busybox -it --rm -- wget -O- <service-name>
```

## OOMKilled
**Error:** Out of memory

**Causes:**
- Memory limit too low
- Memory leak
- Insufficient node memory

**Solutions:**
```bash
# Check pod status
kubectl describe pod <pod-name>

# Increase memory limit
resources:
  limits:
    memory: "1Gi"
```

## Evicted Pods
**Error:** Pod evicted

**Causes:**
- Node pressure (disk/memory)
- Resource limits exceeded

**Solutions:**
```bash
# Check node conditions
kubectl describe node <node-name>

# Clean up evicted pods
kubectl get pods -A | grep Evicted | awk '{print $2 " -n " $1}' | xargs kubectl delete pod
```

## CreateContainerConfigError
**Error:** Cannot create container

**Causes:**
- Missing ConfigMap/Secret
- Invalid volume mount

**Solutions:**
```bash
# Check ConfigMap/Secret exists
kubectl get configmap
kubectl get secret

# Verify references in pod spec
```
