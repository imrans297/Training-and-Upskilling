# Lab 3: Load Balancer Performance and Optimization

## What We're Achieving
Optimize load balancer performance, implement best practices, and compare CLB vs NLB for different use cases.

## What We're Doing
- Performance benchmarking and comparison
- Cost optimization strategies
- Security best practices
- Monitoring and alerting setup

## Prerequisites
- Completed Lab 1 and Lab 2
- EKS cluster running
- kubectl configured

## Lab Exercises

### Exercise 1: Performance Comparison
```bash
# Deploy test application
kubectl create namespace perf-test

cat > perf-app.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: perf-app
  namespace: perf-test
spec:
  replicas: 5
  selector:
    matchLabels:
      app: perf
  template:
    metadata:
      labels:
        app: perf
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
EOF

kubectl apply -f perf-app.yaml

# Create both CLB and NLB with IP restrictions
kubectl expose deployment perf-app --type=LoadBalancer --name=perf-clb --port=80 -n perf-test
kubectl annotate svc perf-clb service.beta.kubernetes.io/aws-load-balancer-type=classic -n perf-test
kubectl annotate svc perf-clb service.beta.kubernetes.io/aws-load-balancer-source-ranges=106.215.177.196/32 -n perf-test

kubectl expose deployment perf-app --type=LoadBalancer --name=perf-nlb --port=80 -n perf-test
kubectl annotate svc perf-nlb service.beta.kubernetes.io/aws-load-balancer-type=nlb -n perf-test
kubectl annotate svc perf-nlb service.beta.kubernetes.io/aws-load-balancer-source-ranges=106.215.177.196/32 -n perf-test

# Wait for provisioning
kubectl get svc -n perf-test -w
```

### Exercise 2: Benchmark Testing
```bash
# Get URLs
CLB_URL=$(kubectl get svc perf-clb -n perf-test -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
NLB_URL=$(kubectl get svc perf-nlb -n perf-test -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Test CLB performance
echo "Testing CLB..."
ab -n 10000 -c 100 -g clb-results.tsv http://$CLB_URL/

# Test NLB performance
echo "Testing NLB..."
ab -n 10000 -c 100 -g nlb-results.tsv http://$NLB_URL/

# Compare results
echo "CLB Results:"
grep "Requests per second" clb-results.tsv
echo "NLB Results:"
grep "Requests per second" nlb-results.tsv
```

### Exercise 3: Cost Optimization
```bash
# Check load balancer costs
cat > cost-analysis.sh << 'EOF'
#!/bin/bash
echo "=== Load Balancer Cost Analysis ==="

# Get CLB details
echo -e "\nClassic Load Balancers:"
aws elb describe-load-balancers --region ap-south-1 \
  --query 'LoadBalancerDescriptions[*].[LoadBalancerName,CreatedTime]' \
  --output table

# Get NLB details
echo -e "\nNetwork Load Balancers:"
aws elbv2 describe-load-balancers --region ap-south-1 \
  --query 'LoadBalancers[?Type==`network`].[LoadBalancerName,CreatedTime]' \
  --output table

# Estimated monthly costs
echo -e "\n=== Estimated Monthly Costs ==="
echo "CLB: ~\$18/month + data processing"
echo "NLB: ~\$16/month + data processing"
echo "Data Processing: \$0.008/GB"
EOF

chmod +x cost-analysis.sh
./cost-analysis.sh
```

### Exercise 4: Security Best Practices
```bash
# Implement security group restrictions
cat > secure-nlb.yaml << EOF
apiVersion: v1
kind: Service
metadata:
  name: secure-nlb
  namespace: perf-test
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
    service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "ip"
    service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
    service.beta.kubernetes.io/aws-load-balancer-source-ranges: "106.215.177.196/32"
    service.beta.kubernetes.io/aws-load-balancer-manage-backend-security-group-rules: "true"
spec:
  type: LoadBalancer
  selector:
    app: perf
  ports:
  - port: 443
    targetPort: 80
    protocol: TCP
EOF

# Note: Update sg-xxxxx with actual security group
# kubectl apply -f secure-nlb.yaml
```

### Exercise 5: Monitoring Setup
```bash
# Create CloudWatch dashboard
cat > create-dashboard.sh << 'EOF'
#!/bin/bash

# Get NLB ARN
NLB_ARN=$(aws elbv2 describe-load-balancers --region ap-south-1 \
  --query 'LoadBalancers[?contains(LoadBalancerName, `perf-nlb`)].LoadBalancerArn' \
  --output text)

echo "Creating CloudWatch Dashboard..."
aws cloudwatch put-dashboard \
  --dashboard-name EKS-LoadBalancer-Metrics \
  --dashboard-body '{
    "widgets": [
      {
        "type": "metric",
        "properties": {
          "metrics": [
            ["AWS/NetworkELB", "ActiveFlowCount", {"stat": "Average"}],
            [".", "ProcessedBytes", {"stat": "Sum"}],
            [".", "HealthyHostCount", {"stat": "Average"}],
            [".", "UnHealthyHostCount", {"stat": "Average"}]
          ],
          "period": 300,
          "stat": "Average",
          "region": "ap-south-1",
          "title": "NLB Metrics"
        }
      }
    ]
  }' \
  --region ap-south-1

echo "Dashboard created: https://console.aws.amazon.com/cloudwatch/home?region=ap-south-1#dashboards:name=EKS-LoadBalancer-Metrics"
EOF

chmod +x create-dashboard.sh
./create-dashboard.sh
```

### Exercise 6: Health Check Optimization
```bash
# Optimized health check configuration
cat > optimized-health.yaml << EOF
apiVersion: v1
kind: Service
metadata:
  name: optimized-nlb
  namespace: perf-test
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
    service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "ip"
    service.beta.kubernetes.io/aws-load-balancer-source-ranges: "106.215.177.196/32"
    # Aggressive health checks for faster failover
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-interval: "10"
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-timeout: "6"
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-healthy-threshold: "2"
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-unhealthy-threshold: "2"
    # Connection settings
    service.beta.kubernetes.io/aws-load-balancer-target-group-attributes: |
      deregistration_delay.timeout_seconds=30,
      deregistration_delay.connection_termination.enabled=true
spec:
  type: LoadBalancer
  selector:
    app: perf
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
EOF

kubectl apply -f optimized-health.yaml
```

### Exercise 7: Troubleshooting Guide
```bash
# Common troubleshooting commands
cat > troubleshoot.sh << 'EOF'
#!/bin/bash

echo "=== Load Balancer Troubleshooting ==="

# Check service status
echo -e "\n1. Service Status:"
kubectl get svc -n perf-test

# Check endpoints
echo -e "\n2. Service Endpoints:"
kubectl get endpoints -n perf-test

# Check pod status
echo -e "\n3. Pod Status:"
kubectl get pods -n perf-test -o wide

# Check events
echo -e "\n4. Recent Events:"
kubectl get events -n perf-test --sort-by='.lastTimestamp' | tail -10

# Check target health
echo -e "\n5. Target Group Health:"
TG_ARN=$(aws elbv2 describe-target-groups --region ap-south-1 \
  --query 'TargetGroups[?contains(TargetGroupName, `perf`)].TargetGroupArn' \
  --output text | head -1)

if [ ! -z "$TG_ARN" ]; then
  aws elbv2 describe-target-health --target-group-arn $TG_ARN --region ap-south-1
fi
EOF

chmod +x troubleshoot.sh
./troubleshoot.sh
```

## Cleanup
```bash
kubectl delete -f perf-app.yaml
kubectl delete svc perf-clb perf-nlb secure-nlb optimized-nlb -n perf-test
kubectl delete namespace perf-test
rm -f perf-app.yaml secure-nlb.yaml optimized-health.yaml
rm -f cost-analysis.sh create-dashboard.sh troubleshoot.sh
rm -f clb-results.tsv nlb-results.tsv
```

## Key Takeaways
1. NLB provides better performance for high-throughput workloads
2. CLB suitable for HTTP/HTTPS with SSL termination
3. Optimize health checks for faster failover
4. Monitor CloudWatch metrics for performance insights
5. Implement security groups for access control
6. Use target group attributes for connection management
7. Cost optimization through proper sizing and configuration
8. Regular monitoring prevents performance degradation

## Next Steps
- Implement ALB for advanced HTTP routing (Section 11)
- Set up CloudWatch alarms for proactive monitoring
- Explore AWS Load Balancer Controller features
