# Lab 1: AWS Load Balancer Controller Installation and Basic Ingress

## What We're Achieving
Install AWS Load Balancer Controller and create basic Application Load Balancer (ALB) ingress resources for EKS applications.

## What We're Doing
- Install AWS Load Balancer Controller using Helm
- Create IAM service account for the controller
- Deploy sample applications with ALB ingress
- Test ingress routing and SSL termination

## Prerequisites
- Shared training cluster with OIDC provider
- Helm installed
- kubectl configured
- AWS CLI configured

## Lab Exercises

### Exercise 1: Install AWS Load Balancer Controller
```bash
# Switch to ALB controller namespace
kubectl config set-context --current --namespace=alb-controller

# Check if controller is already installed
kubectl get deployment -n kube-system aws-load-balancer-controller

# If not installed, create IAM service account
eksctl create iamserviceaccount \
  --cluster=eksdemo1-imran \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess \
  --approve \
  --region=ap-south-1

# Add EKS Helm repository
helm repo add eks https://aws.github.io/eks-charts
helm repo update

# Install AWS Load Balancer Controller
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=eksdemo1-imran \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=ap-south-1 \
  --set vpcId=$(aws eks describe-cluster --name eksdemo1-imran --region ap-south-1 --query 'cluster.resourcesVpcConfig.vpcId' --output text)

# Verify installation
kubectl get deployment -n kube-system aws-load-balancer-controller
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
```

### Exercise 2: Deploy Sample Applications
```bash
# Create sample applications for ingress testing
cat > sample-apps.yaml << EOF
# App 1: Frontend
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-app
  namespace: alb-controller
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        volumeMounts:
        - name: html-content
          mountPath: /usr/share/nginx/html
      volumes:
      - name: html-content
        configMap:
          name: frontend-content
---
# App 2: Backend API
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-app
  namespace: alb-controller
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: httpd
        image: httpd:alpine
        ports:
        - containerPort: 80
        volumeMounts:
        - name: html-content
          mountPath: /usr/local/apache2/htdocs
      volumes:
      - name: html-content
        configMap:
          name: backend-content
---
# Frontend Service
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
  namespace: alb-controller
spec:
  selector:
    app: frontend
  ports:
    - port: 80
      targetPort: 80
  type: ClusterIP
---
# Backend Service
apiVersion: v1
kind: Service
metadata:
  name: backend-service
  namespace: alb-controller
spec:
  selector:
    app: backend
  ports:
    - port: 80
      targetPort: 80
  type: ClusterIP
---
# Frontend Content
apiVersion: v1
kind: ConfigMap
metadata:
  name: frontend-content
  namespace: alb-controller
data:
  index.html: |
    <!DOCTYPE html>
    <html>
    <head>
        <title>Frontend App</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 40px; background-color: #f0f8ff; }
            .container { max-width: 800px; margin: 0 auto; padding: 20px; }
            h1 { color: #2c3e50; }
            .info { background-color: #e8f4fd; padding: 15px; border-radius: 5px; margin: 20px 0; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🚀 Frontend Application</h1>
            <div class="info">
                <p><strong>Service:</strong> Frontend</p>
                <p><strong>Version:</strong> 1.0.0</p>
                <p><strong>Pod:</strong> <span id="hostname"></span></p>
                <p><strong>Timestamp:</strong> <span id="timestamp"></span></p>
            </div>
            <p>This is the frontend application served through ALB Ingress.</p>
            <p><a href="/api">Test Backend API</a></p>
        </div>
        <script>
            document.getElementById('hostname').textContent = window.location.hostname;
            document.getElementById('timestamp').textContent = new Date().toLocaleString();
        </script>
    </body>
    </html>
---
# Backend Content
apiVersion: v1
kind: ConfigMap
metadata:
  name: backend-content
  namespace: alb-controller
data:
  index.html: |
    <!DOCTYPE html>
    <html>
    <head>
        <title>Backend API</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 40px; background-color: #fff8dc; }
            .container { max-width: 800px; margin: 0 auto; padding: 20px; }
            h1 { color: #8b4513; }
            .info { background-color: #fdf5e6; padding: 15px; border-radius: 5px; margin: 20px 0; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>⚙️ Backend API</h1>
            <div class="info">
                <p><strong>Service:</strong> Backend API</p>
                <p><strong>Version:</strong> 1.0.0</p>
                <p><strong>Status:</strong> ✅ Healthy</p>
                <p><strong>Timestamp:</strong> <span id="timestamp"></span></p>
            </div>
            <p>This is the backend API service served through ALB Ingress.</p>
            <p><a href="/">Back to Frontend</a></p>
        </div>
        <script>
            document.getElementById('timestamp').textContent = new Date().toLocaleString();
        </script>
    </body>
    </html>
EOF

# Deploy applications
kubectl apply -f sample-apps.yaml

# Wait for deployments to be ready
kubectl wait --for=condition=Available deployment/frontend-app -n alb-controller --timeout=120s
kubectl wait --for=condition=Available deployment/backend-app -n alb-controller --timeout=120s

# Verify services
kubectl get pods,svc -n alb-controller
```

### Exercise 3: Create Basic ALB Ingress
```bash
# Create basic ingress resource
cat > basic-ingress.yaml << EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: basic-alb-ingress
  namespace: alb-controller
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}]'
    alb.ingress.kubernetes.io/inbound-cidrs: 106.215.177.196/32
    alb.ingress.kubernetes.io/tags: 'Owner=imran.shaikh@einfochips.com,Project=Internal POC,Environment=learning'
spec:
  ingressClassName: alb
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: backend-service
            port:
              number: 80
EOF

# Apply ingress
kubectl apply -f basic-ingress.yaml

# Check ingress status
kubectl get ingress -n alb-controller

# Wait for ALB to be provisioned (takes 2-3 minutes)
kubectl wait --for=condition=Ready ingress/basic-alb-ingress -n alb-controller --timeout=300s

# Get ALB DNS name
ALB_DNS=$(kubectl get ingress basic-alb-ingress -n alb-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "ALB DNS: $ALB_DNS"
```

### Exercise 4: Test Ingress Routing
```bash
# Test frontend access
curl -H "Host: $ALB_DNS" http://$ALB_DNS/

# Test backend API access
curl -H "Host: $ALB_DNS" http://$ALB_DNS/api

# Test with browser (if available)
echo "Frontend URL: http://$ALB_DNS/"
echo "Backend URL: http://$ALB_DNS/api"

# Check ALB target groups
aws elbv2 describe-target-groups --region ap-south-1 --query 'TargetGroups[?contains(TargetGroupName, `k8s-albcontr-basicalb`)].{Name:TargetGroupName,Health:HealthCheckPath,Port:Port}'

# Check target health
TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups --region ap-south-1 --query 'TargetGroups[?contains(TargetGroupName, `k8s-albcontr-basicalb`)].TargetGroupArn' --output text | head -1)
aws elbv2 describe-target-health --target-group-arn $TARGET_GROUP_ARN --region ap-south-1
```

### Exercise 5: Add Health Checks and Annotations
```bash
# Create advanced ingress with health checks
cat > advanced-ingress.yaml << EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: advanced-alb-ingress
  namespace: alb-controller
  annotations:
    # ALB Configuration
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}]'
    alb.ingress.kubernetes.io/inbound-cidrs: 106.215.177.196/32
    
    # Health Check Configuration
    alb.ingress.kubernetes.io/healthcheck-path: /
    alb.ingress.kubernetes.io/healthcheck-interval-seconds: '30'
    alb.ingress.kubernetes.io/healthcheck-timeout-seconds: '5'
    alb.ingress.kubernetes.io/healthy-threshold-count: '2'
    alb.ingress.kubernetes.io/unhealthy-threshold-count: '3'
    
    # Load Balancer Attributes
    alb.ingress.kubernetes.io/load-balancer-attributes: |
      idle_timeout.timeout_seconds=60,
      routing.http2.enabled=true,
      access_logs.s3.enabled=false
    
    # Tags
    alb.ingress.kubernetes.io/tags: |
      Owner=imran.shaikh@einfochips.com,
      Project=Internal POC,
      Environment=learning,
      ManagedBy=ALB-Ingress-Controller
spec:
  ingressClassName: alb
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: backend-service
            port:
              number: 80
EOF

# Delete old ingress and apply new one
kubectl delete -f basic-ingress.yaml
kubectl apply -f advanced-ingress.yaml

# Wait for new ALB
kubectl wait --for=condition=Ready ingress/advanced-alb-ingress -n alb-controller --timeout=300s

# Get new ALB DNS
NEW_ALB_DNS=$(kubectl get ingress advanced-alb-ingress -n alb-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "New ALB DNS: $NEW_ALB_DNS"

# Test new ingress
curl http://$NEW_ALB_DNS/
curl http://$NEW_ALB_DNS/api
```

### Exercise 6: Monitor and Troubleshoot
```bash
# Check AWS Load Balancer Controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller --tail=50

# Check ingress events
kubectl describe ingress advanced-alb-ingress -n alb-controller

# Check service endpoints
kubectl get endpoints -n alb-controller

# List all ALBs created by the controller
aws elbv2 describe-load-balancers --region ap-south-1 --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-albcontr`)].{Name:LoadBalancerName,DNS:DNSName,State:State.Code}'

# Check ALB tags
ALB_ARN=$(aws elbv2 describe-load-balancers --region ap-south-1 --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-albcontr`)].LoadBalancerArn' --output text | head -1)
aws elbv2 describe-tags --resource-arns $ALB_ARN --region ap-south-1
```

## Cleanup
```bash
# Delete ingress (this will delete the ALB)
kubectl delete -f advanced-ingress.yaml

# Delete applications
kubectl delete -f sample-apps.yaml

# Clean up files
rm -f sample-apps.yaml basic-ingress.yaml advanced-ingress.yaml

# Verify ALB deletion
aws elbv2 describe-load-balancers --region ap-south-1 --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-albcontr`)]'
```

## Key Takeaways
1. AWS Load Balancer Controller manages ALB lifecycle automatically
2. Ingress annotations control ALB behavior and features
3. Target type 'ip' is recommended for EKS
4. Health checks ensure traffic goes to healthy pods
5. ALB supports advanced features like HTTP/2 and WebSocket
6. Proper tagging helps with cost tracking and management
7. Controller logs are essential for troubleshooting

## Next Steps
- Move to Lab 2: SSL/TLS Termination and Custom Domains
- Practice with different ingress patterns
- Learn about advanced ALB features and annotations