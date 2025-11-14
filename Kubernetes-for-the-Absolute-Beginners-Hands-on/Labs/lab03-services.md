# Lab 3: Working with Services

## Objective
Learn to expose applications using different service types.

## Tasks

### Task 1: ClusterIP Service
```bash
# Create deployment
kubectl create deployment web-app --image=nginx --replicas=3

# Expose as ClusterIP (default)
kubectl expose deployment web-app --port=80 --target-port=80 --name=web-service

# Verify
kubectl get svc web-service
kubectl describe svc web-service
kubectl get endpoints web-service
```

Test from within cluster:
```bash
# Run test pod
kubectl run test-pod --image=busybox -it --rm -- wget -O- web-service
```

### Task 2: NodePort Service
Create `nodeport-service.yaml`:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: nodeport-service
spec:
  type: NodePort
  selector:
    app: web-app
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
```

Apply:
```bash
kubectl apply -f nodeport-service.yaml
kubectl get svc nodeport-service

# Get node IP
kubectl get nodes -o wide

# Access: http://<node-ip>:30080
```

### Task 3: LoadBalancer Service (Cloud)
Create `loadbalancer-service.yaml`:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: lb-service
spec:
  type: LoadBalancer
  selector:
    app: web-app
  ports:
  - port: 80
    targetPort: 80
```

Apply:
```bash
kubectl apply -f loadbalancer-service.yaml
kubectl get svc lb-service

# Wait for external IP
kubectl get svc lb-service -w
```

### Task 4: Service with Multiple Ports
Create `multi-port-service.yaml`:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: multi-port-service
spec:
  selector:
    app: web-app
  ports:
  - name: http
    port: 80
    targetPort: 80
  - name: https
    port: 443
    targetPort: 443
```

Apply:
```bash
kubectl apply -f multi-port-service.yaml
kubectl describe svc multi-port-service
```

### Task 5: Headless Service
Create `headless-service.yaml`:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: headless-service
spec:
  clusterIP: None
  selector:
    app: web-app
  ports:
  - port: 80
    targetPort: 80
```

Apply:
```bash
kubectl apply -f headless-service.yaml
kubectl get svc headless-service

# DNS lookup
kubectl run test --image=busybox -it --rm -- nslookup headless-service
```

### Task 6: Service Discovery
```bash
# Create deployment and service
kubectl create deployment backend --image=nginx
kubectl expose deployment backend --port=80

# Test DNS resolution
kubectl run test --image=busybox -it --rm -- nslookup backend

# Test connectivity
kubectl run test --image=curlimages/curl -it --rm -- curl http://backend
```

### Task 7: Service Endpoints
```bash
# View endpoints
kubectl get endpoints web-service

# Scale deployment
kubectl scale deployment web-app --replicas=5

# Check endpoints updated
kubectl get endpoints web-service

# Scale down
kubectl scale deployment web-app --replicas=1
kubectl get endpoints web-service
```

## Cleanup
```bash
kubectl delete deployment web-app
kubectl delete deployment backend
kubectl delete svc web-service
kubectl delete svc nodeport-service
kubectl delete svc lb-service
kubectl delete svc multi-port-service
kubectl delete svc headless-service
kubectl delete svc backend
```

## Verification
- [ ] Created ClusterIP service
- [ ] Created NodePort service
- [ ] Created LoadBalancer service
- [ ] Created multi-port service
- [ ] Created headless service
- [ ] Tested service discovery
- [ ] Verified endpoints
