# Lab 2: Network Load Balancer (NLB) with EKS

## What We're Achieving
Deploy high-performance applications with AWS Network Load Balancer for ultra-low latency and static IP requirements.

## What We're Doing
- Create NLB with LoadBalancer service
- Configure target type (instance vs IP)
- Implement cross-zone load balancing
- Test performance and static IPs

## Prerequisites
- Completed Lab 1 (CLB)
- EKS cluster running
- kubectl configured

## Lab Exercises

### Exercise 1: Deploy Application with NLB
```bash
# Create namespace
kubectl create namespace nlb-demo

# Deploy application
cat > nlb-app.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: nlb-demo
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
EOF

kubectl apply -f nlb-app.yaml
kubectl wait --for=condition=Available deployment/web-app -n nlb-demo --timeout=120s
```

### Exercise 2: Create NLB Service (Instance Mode)
```bash
# NLB with instance target type
cat > nlb-instance.yaml << EOF
apiVersion: v1
kind: Service
metadata:
  name: web-nlb-instance
  namespace: nlb-demo
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
    service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
    service.beta.kubernetes.io/aws-load-balancer-backend-protocol: "tcp"
    service.beta.kubernetes.io/aws-load-balancer-source-ranges: "106.215.177.196/32"
spec:
  type: LoadBalancer
  selector:
    app: web
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
EOF

kubectl apply -f nlb-instance.yaml

# Get NLB DNS
NLB_DNS=$(kubectl get svc web-nlb-instance -n nlb-demo -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "NLB DNS: $NLB_DNS"

# Test access
curl http://$NLB_DNS
```

### Exercise 3: Create NLB Service (IP Mode)
```bash
# NLB with IP target type (better for pod-to-pod)
cat > nlb-ip.yaml << EOF
apiVersion: v1
kind: Service
metadata:
  name: web-nlb-ip
  namespace: nlb-demo
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
    service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "ip"
    service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
    service.beta.kubernetes.io/aws-load-balancer-source-ranges: "106.215.177.196/32"
spec:
  type: LoadBalancer
  selector:
    app: web
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
EOF

kubectl apply -f nlb-ip.yaml

# Compare instance vs IP mode
kubectl get svc -n nlb-demo
```

### Exercise 4: Configure Health Checks
```bash
# NLB with custom health checks
cat > nlb-healthcheck.yaml << EOF
apiVersion: v1
kind: Service
metadata:
  name: web-nlb-health
  namespace: nlb-demo
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
    service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "ip"
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-protocol: "HTTP"
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-path: "/"
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-interval: "10"
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-timeout: "6"
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-healthy-threshold: "2"
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-unhealthy-threshold: "2"
    service.beta.kubernetes.io/aws-load-balancer-source-ranges: "106.215.177.196/32"
spec:
  type: LoadBalancer
  selector:
    app: web
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
EOF

kubectl apply -f nlb-healthcheck.yaml
```

### Exercise 5: Static IP with NLB
```bash
# Allocate Elastic IPs
EIP1=$(aws ec2 allocate-address --domain vpc --region ap-south-1 --query 'AllocationId' --output text)
EIP2=$(aws ec2 allocate-address --domain vpc --region ap-south-1 --query 'AllocationId' --output text)

echo "EIP1: $EIP1"
echo "EIP2: $EIP2"

# Create NLB with static IPs
cat > nlb-static-ip.yaml << EOF
apiVersion: v1
kind: Service
metadata:
  name: web-nlb-static
  namespace: nlb-demo
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
    service.beta.kubernetes.io/aws-load-balancer-eip-allocations: "$EIP1,$EIP2"
    service.beta.kubernetes.io/aws-load-balancer-source-ranges: "106.215.177.196/32"
spec:
  type: LoadBalancer
  selector:
    app: web
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
EOF

kubectl apply -f nlb-static-ip.yaml

# Get static IPs
kubectl get svc web-nlb-static -n nlb-demo
```

### Exercise 6: Performance Testing
```bash
# Install Apache Bench (if not installed)
# sudo apt-get install apache2-utils

# Performance test
ab -n 10000 -c 100 http://$NLB_DNS/

# Compare with CLB (from Lab1)
# ab -n 10000 -c 100 http://$CLB_URL/

# Monitor NLB metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/NetworkELB \
  --metric-name ActiveFlowCount \
  --dimensions Name=LoadBalancer,Value=<NLB_ARN> \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average \
  --region ap-south-1
```

### Exercise 7: Internal NLB
```bash
# Create internal NLB (for private access)
cat > nlb-internal.yaml << EOF
apiVersion: v1
kind: Service
metadata:
  name: web-nlb-internal
  namespace: nlb-demo
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
    service.beta.kubernetes.io/aws-load-balancer-internal: "true"
    service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "ip"
spec:
  type: LoadBalancer
  selector:
    app: web
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
EOF

kubectl apply -f nlb-internal.yaml

# Verify internal NLB
kubectl get svc web-nlb-internal -n nlb-demo
```

## Cleanup
```bash
kubectl delete -f nlb-app.yaml
kubectl delete -f nlb-instance.yaml
kubectl delete -f nlb-ip.yaml
kubectl delete -f nlb-healthcheck.yaml
kubectl delete -f nlb-static-ip.yaml
kubectl delete -f nlb-internal.yaml
kubectl delete namespace nlb-demo

# Release Elastic IPs
aws ec2 release-address --allocation-id $EIP1 --region ap-south-1
aws ec2 release-address --allocation-id $EIP2 --region ap-south-1

rm -f nlb-app.yaml nlb-instance.yaml nlb-ip.yaml nlb-healthcheck.yaml nlb-static-ip.yaml nlb-internal.yaml
```

## Key Takeaways
1. NLB provides ultra-low latency and high throughput
2. IP target type better for pod-level load balancing
3. Instance target type uses NodePort
4. Static IPs enable whitelisting and DNS management
5. Cross-zone load balancing distributes traffic evenly
6. Internal NLB for private application access
7. NLB supports TCP, UDP, and TLS protocols
8. Health checks ensure traffic to healthy targets

## Next Steps
- Move to Lab 3: Performance Optimization
- Compare CLB vs NLB performance
- Implement TLS termination with NLB
