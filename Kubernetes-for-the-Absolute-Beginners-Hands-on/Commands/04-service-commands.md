# Service Commands

## Purpose
Expose applications to network traffic with stable endpoints.

## What You'll Achieve
- Expose pods to internal/external traffic
- Create different service types
- Enable service discovery
- Load balance traffic across pods

---

## Create Services
```bash
# From YAML - Create service from manifest
# Purpose: Define service with full configuration
kubectl create -f service.yaml
kubectl apply -f service.yaml

# Expose deployment - Create service for deployment
# Purpose: Make deployment accessible via network
kubectl expose deployment nginx --port=80 --type=ClusterIP  # Internal only
kubectl expose deployment nginx --port=80 --type=NodePort  # External via node port
kubectl expose deployment nginx --port=80 --type=LoadBalancer  # Cloud load balancer

# Expose pod
kubectl expose pod nginx --port=80 --name=nginx-service

# Dry run
kubectl expose deployment nginx --port=80 --dry-run=client -o yaml > service.yaml
```

## List Services
```bash
# All services
kubectl get services
kubectl get svc

# Wide output
kubectl get svc -o wide

# All namespaces
kubectl get svc -A
```

## Service Details
```bash
# Describe service - Detailed service information
# Purpose: View endpoints, selectors, ports
kubectl describe service <service-name>
kubectl describe svc <service-name>

# Get endpoints - View backend pod IPs
# Purpose: Verify service is routing to pods
kubectl get endpoints <service-name>
kubectl get ep <service-name>
```

## Delete Services
```bash
# Delete service
kubectl delete service <service-name>
kubectl delete svc <service-name>

# Delete from file
kubectl delete -f service.yaml
```

## Edit Services
```bash
# Edit service
kubectl edit service <service-name>
```

## Test Services
```bash
# Port forward - Access service from localhost
# Purpose: Test service without external exposure
kubectl port-forward service/<service-name> 8080:80

# Run test pod - Test service connectivity
# Purpose: Verify service is accessible from cluster
kubectl run test --image=busybox -it --rm -- wget -O- <service-name>
```
