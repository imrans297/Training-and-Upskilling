# Lab 1: ECR Repository Setup and Image Management

## What We're Achieving
Set up AWS Elastic Container Registry (ECR) and integrate it with EKS for secure container image storage and deployment.

## What We're Doing
- Create ECR repositories
- Build and push Docker images to ECR
- Configure EKS authentication with ECR
- Deploy applications using ECR images
- Implement image scanning and lifecycle policies

## Prerequisites
- Shared training cluster running
- Docker installed locally
- AWS CLI configured
- kubectl configured

## Lab Exercises

### Exercise 1: Create ECR Repositories
```bash
# Switch to ECR namespace
kubectl config set-context --current --namespace=ecr-integration

# Create ECR repository for web application
aws ecr create-repository \
  --repository-name training/web-app \
  --image-scanning-configuration scanOnPush=true \
  --encryption-configuration encryptionType=AES256 \
  --region ap-south-1 \
  --tags Key=Owner,Value=imran.shaikh@einfochips.com Key=Project,Value="Internal POC"

# Create ECR repository for API service
aws ecr create-repository \
  --repository-name training/api-service \
  --image-scanning-configuration scanOnPush=true \
  --encryption-configuration encryptionType=AES256 \
  --region ap-south-1 \
  --tags Key=Owner,Value=imran.shaikh@einfochips.com Key=Project,Value="Internal POC"

# List repositories
aws ecr describe-repositories --region ap-south-1

# Get repository URIs
WEB_REPO_URI=$(aws ecr describe-repositories --repository-names training/web-app --region ap-south-1 --query 'repositories[0].repositoryUri' --output text)
API_REPO_URI=$(aws ecr describe-repositories --repository-names training/api-service --region ap-south-1 --query 'repositories[0].repositoryUri' --output text)

echo "Web App Repository: $WEB_REPO_URI"
echo "API Service Repository: $API_REPO_URI"
```

### Exercise 2: Build and Push Docker Images
```bash
# Create simple web application
mkdir -p web-app
cat > web-app/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>ECR Integration Demo</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background-color: #f0f8ff; }
        .container { max-width: 800px; margin: 0 auto; padding: 20px; }
        .info { background-color: #e8f4fd; padding: 20px; margin: 20px 0; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🐳 ECR Integration Demo</h1>
        <div class="info">
            <h3>Container Information</h3>
            <p><strong>Image:</strong> Stored in AWS ECR</p>
            <p><strong>Registry:</strong> Private ECR Repository</p>
            <p><strong>Scanning:</strong> Enabled for vulnerabilities</p>
            <p><strong>Encryption:</strong> AES256 at rest</p>
        </div>
        <div class="info">
            <h3>Deployment Details</h3>
            <p><strong>Platform:</strong> Amazon EKS</p>
            <p><strong>Namespace:</strong> ecr-integration</p>
            <p><strong>Version:</strong> 1.0.0</p>
        </div>
    </div>
</body>
</html>
EOF

# Create Dockerfile for web app
cat > web-app/Dockerfile << EOF
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF

# Create simple API service
mkdir -p api-service
cat > api-service/app.py << EOF
from flask import Flask, jsonify
import os
import socket

app = Flask(__name__)

@app.route('/')
def hello():
    return jsonify({
        'message': 'Hello from ECR API Service!',
        'hostname': socket.gethostname(),
        'version': '1.0.0',
        'environment': os.getenv('ENVIRONMENT', 'development')
    })

@app.route('/health')
def health():
    return jsonify({'status': 'healthy'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

# Create Dockerfile for API service
cat > api-service/Dockerfile << EOF
FROM python:3.9-slim
WORKDIR /app
RUN pip install flask
COPY app.py .
EXPOSE 5000
CMD ["python", "app.py"]
EOF

# Authenticate Docker with ECR
aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.ap-south-1.amazonaws.com

# Build and push web app image
cd web-app
docker build -t training/web-app:1.0.0 .
docker tag training/web-app:1.0.0 $WEB_REPO_URI:1.0.0
docker tag training/web-app:1.0.0 $WEB_REPO_URI:latest
docker push $WEB_REPO_URI:1.0.0
docker push $WEB_REPO_URI:latest

# Build and push API service image
cd ../api-service
docker build -t training/api-service:1.0.0 .
docker tag training/api-service:1.0.0 $API_REPO_URI:1.0.0
docker tag training/api-service:1.0.0 $API_REPO_URI:latest
docker push $API_REPO_URI:1.0.0
docker push $API_REPO_URI:latest

cd ..

# Verify images in ECR
aws ecr list-images --repository-name training/web-app --region ap-south-1
aws ecr list-images --repository-name training/api-service --region ap-south-1
```

### Exercise 3: Deploy Applications Using ECR Images
```bash
# Create deployment using ECR images
cat > ecr-applications.yaml << EOF
# Web Application Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: ecr-integration
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
      - name: web-app
        image: $WEB_REPO_URI:1.0.0
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
---
# API Service Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-service
  namespace: ecr-integration
spec:
  replicas: 2
  selector:
    matchLabels:
      app: api-service
  template:
    metadata:
      labels:
        app: api-service
    spec:
      containers:
      - name: api-service
        image: $API_REPO_URI:1.0.0
        ports:
        - containerPort: 5000
        env:
        - name: ENVIRONMENT
          value: "production"
        resources:
          requests:
            memory: "128Mi"
            cpu: "250m"
          limits:
            memory: "256Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 5000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 5000
          initialDelaySeconds: 5
          periodSeconds: 5
---
# Web App Service
apiVersion: v1
kind: Service
metadata:
  name: web-app-service
  namespace: ecr-integration
spec:
  selector:
    app: web-app
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30084
  type: NodePort
---
# API Service
apiVersion: v1
kind: Service
metadata:
  name: api-service
  namespace: ecr-integration
spec:
  selector:
    app: api-service
  ports:
    - port: 5000
      targetPort: 5000
  type: ClusterIP
EOF

kubectl apply -f ecr-applications.yaml

# Wait for deployments to be ready
kubectl wait --for=condition=Available deployment/web-app -n ecr-integration --timeout=120s
kubectl wait --for=condition=Available deployment/api-service -n ecr-integration --timeout=120s

# Verify deployments
kubectl get pods,svc -n ecr-integration
```

### Exercise 4: Test Image Scanning
```bash
# Check scan results for web app
aws ecr describe-image-scan-findings \
  --repository-name training/web-app \
  --image-id imageTag=1.0.0 \
  --region ap-south-1

# Check scan results for API service
aws ecr describe-image-scan-findings \
  --repository-name training/api-service \
  --image-id imageTag=1.0.0 \
  --region ap-south-1

# Start scan manually if needed
aws ecr start-image-scan \
  --repository-name training/web-app \
  --image-id imageTag=1.0.0 \
  --region ap-south-1

# Wait for scan to complete and check results
sleep 60
aws ecr describe-image-scan-findings \
  --repository-name training/web-app \
  --image-id imageTag=1.0.0 \
  --region ap-south-1 \
  --query 'imageScanFindingsSummary'
```

### Exercise 5: Implement Lifecycle Policies
```bash
# Create lifecycle policy for web app repository
cat > lifecycle-policy.json << EOF
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keep last 10 production images",
      "selection": {
        "tagStatus": "tagged",
        "tagPrefixList": ["v"],
        "countType": "imageCountMoreThan",
        "countNumber": 10
      },
      "action": {
        "type": "expire"
      }
    },
    {
      "rulePriority": 2,
      "description": "Delete untagged images older than 1 day",
      "selection": {
        "tagStatus": "untagged",
        "countType": "sinceImagePushed",
        "countUnit": "days",
        "countNumber": 1
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
EOF

# Apply lifecycle policy
aws ecr put-lifecycle-policy \
  --repository-name training/web-app \
  --lifecycle-policy-text file://lifecycle-policy.json \
  --region ap-south-1

# Apply same policy to API service
aws ecr put-lifecycle-policy \
  --repository-name training/api-service \
  --lifecycle-policy-text file://lifecycle-policy.json \
  --region ap-south-1

# Verify lifecycle policies
aws ecr get-lifecycle-policy \
  --repository-name training/web-app \
  --region ap-south-1
```

### Exercise 6: Image Updates and Rolling Deployments
```bash
# Update web app content
cat > web-app/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>ECR Integration Demo v2.0</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background-color: #f0fff0; }
        .container { max-width: 800px; margin: 0 auto; padding: 20px; }
        .info { background-color: #e8f5e8; padding: 20px; margin: 20px 0; border-radius: 5px; }
        .update { background-color: #fff3cd; padding: 15px; margin: 10px 0; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🐳 ECR Integration Demo v2.0</h1>
        <div class="update">
            <h3>🆕 What's New in v2.0</h3>
            <ul>
                <li>Updated UI design</li>
                <li>Enhanced security scanning</li>
                <li>Improved performance</li>
            </ul>
        </div>
        <div class="info">
            <h3>Container Information</h3>
            <p><strong>Image:</strong> Stored in AWS ECR</p>
            <p><strong>Version:</strong> 2.0.0</p>
            <p><strong>Registry:</strong> Private ECR Repository</p>
            <p><strong>Scanning:</strong> Enabled for vulnerabilities</p>
        </div>
    </div>
</body>
</html>
EOF

# Build and push v2.0
cd web-app
docker build -t training/web-app:2.0.0 .
docker tag training/web-app:2.0.0 $WEB_REPO_URI:2.0.0
docker push $WEB_REPO_URI:2.0.0
cd ..

# Update deployment to use new image
kubectl set image deployment/web-app web-app=$WEB_REPO_URI:2.0.0 -n ecr-integration

# Monitor rolling update
kubectl rollout status deployment/web-app -n ecr-integration

# Verify update
kubectl get pods -n ecr-integration
kubectl describe deployment web-app -n ecr-integration | grep Image
```

### Exercise 7: Cross-Account ECR Access (Simulation)
```bash
# Create repository policy for cross-account access (example)
cat > repository-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowCrossAccountPull",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::ACCOUNT-ID:root"
      },
      "Action": [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability"
      ]
    }
  ]
}
EOF

echo "Repository policy created (replace ACCOUNT-ID with actual account)"
# aws ecr set-repository-policy --repository-name training/web-app --policy-text file://repository-policy.json --region ap-south-1
```

### Exercise 8: Monitor ECR Usage and Costs
```bash
# Get repository size and image count
aws ecr describe-repositories \
  --repository-names training/web-app training/api-service \
  --region ap-south-1 \
  --query 'repositories[*].{Name:repositoryName,Size:repositorySizeInBytes,Images:imageCount}'

# List all images with details
aws ecr describe-images \
  --repository-name training/web-app \
  --region ap-south-1 \
  --query 'imageDetails[*].{Tags:imageTags,Size:imageSizeInBytes,Pushed:imagePushedAt}' \
  --output table

# Check scan status for all images
aws ecr describe-images \
  --repository-name training/web-app \
  --region ap-south-1 \
  --query 'imageDetails[*].{Tags:imageTags,ScanStatus:imageScanFindingsSummary.findingCounts}'
```

## Cleanup
```bash
# Delete Kubernetes resources
kubectl delete -f ecr-applications.yaml

# Delete ECR images
aws ecr batch-delete-image \
  --repository-name training/web-app \
  --image-ids imageTag=1.0.0 imageTag=2.0.0 imageTag=latest \
  --region ap-south-1

aws ecr batch-delete-image \
  --repository-name training/api-service \
  --image-ids imageTag=1.0.0 imageTag=latest \
  --region ap-south-1

# Delete ECR repositories
aws ecr delete-repository \
  --repository-name training/web-app \
  --force \
  --region ap-south-1

aws ecr delete-repository \
  --repository-name training/api-service \
  --force \
  --region ap-south-1

# Clean up local files
rm -rf web-app api-service
rm -f ecr-applications.yaml lifecycle-policy.json repository-policy.json

# Clean up local Docker images
docker rmi training/web-app:1.0.0 training/web-app:2.0.0 training/api-service:1.0.0 2>/dev/null || true
```

## Key Takeaways
1. ECR provides secure, managed container registry service
2. Image scanning helps identify security vulnerabilities
3. Lifecycle policies automate image cleanup and cost management
4. EKS has built-in authentication with ECR in the same account
5. Repository policies enable cross-account access
6. Image tags should follow semantic versioning
7. Rolling updates enable zero-downtime deployments
8. Monitoring repository usage helps control costs

## Next Steps
- Move to Lab 2: CI/CD Pipeline Integration with ECR
- Practice with multi-architecture images
- Learn about ECR replication and disaster recovery