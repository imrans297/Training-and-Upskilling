# Lab 2: Multi-Resource Applications

## What We're Achieving
Build complete applications using multiple Kubernetes resources working together through YAML manifests.

## What We're Doing
- Creating multi-tier applications with YAML
- Understanding resource relationships and dependencies
- Implementing proper labeling and selection strategies
- Managing application lifecycle declaratively

## Prerequisites
- Completed Lab 1
- Shared training cluster running
- kubectl configured

## Lab Exercises

### Exercise 1: Three-Tier Web Application
```bash
# Switch to declarative namespace
kubectl config set-context --current --namespace=k8s-declarative

# Create complete web application stack
cat > web-app-stack.yaml << EOF
# Frontend Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  labels:
    app: web-app
    tier: frontend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web-app
      tier: frontend
  template:
    metadata:
      labels:
        app: web-app
        tier: frontend
    spec:
      containers:
      - name: nginx
        image: nginx:1.21
        ports:
        - containerPort: 80
        env:
        - name: BACKEND_URL
          value: "http://backend-service:8080"
---
# Backend Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  labels:
    app: web-app
    tier: backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-app
      tier: backend
  template:
    metadata:
      labels:
        app: web-app
        tier: backend
    spec:
      containers:
      - name: api
        image: httpd:2.4
        ports:
        - containerPort: 80
        env:
        - name: DB_HOST
          value: "database-service"
---
# Database Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: database
  labels:
    app: web-app
    tier: database
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web-app
      tier: database
  template:
    metadata:
      labels:
        app: web-app
        tier: database
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        ports:
        - containerPort: 3306
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: "rootpassword"
        - name: MYSQL_DATABASE
          value: "webapp"
---
# Frontend Service
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
  labels:
    app: web-app
    tier: frontend
spec:
  selector:
    app: web-app
    tier: frontend
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30080
  type: NodePort
---
# Backend Service
apiVersion: v1
kind: Service
metadata:
  name: backend-service
  labels:
    app: web-app
    tier: backend
spec:
  selector:
    app: web-app
    tier: backend
  ports:
    - port: 8080
      targetPort: 80
  type: ClusterIP
---
# Database Service
apiVersion: v1
kind: Service
metadata:
  name: database-service
  labels:
    app: web-app
    tier: database
spec:
  selector:
    app: web-app
    tier: database
  ports:
    - port: 3306
      targetPort: 3306
  type: ClusterIP
EOF

# Apply the entire stack
kubectl apply -f web-app-stack.yaml

# Verify all resources
kubectl get all -l app=web-app
```

### Exercise 2: Microservices with ConfigMaps
```bash
# Create microservices application with configuration
cat > microservices-app.yaml << EOF
# Configuration
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  database.properties: |
    db.host=postgres-service
    db.port=5432
    db.name=microservices
  app.properties: |
    app.name=Microservices Demo
    app.version=1.0.0
    log.level=INFO
---
# User Service
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
  labels:
    app: microservices
    service: user
spec:
  replicas: 2
  selector:
    matchLabels:
      app: microservices
      service: user
  template:
    metadata:
      labels:
        app: microservices
        service: user
    spec:
      containers:
      - name: user-api
        image: nginx:alpine
        ports:
        - containerPort: 80
        volumeMounts:
        - name: config-volume
          mountPath: /etc/config
      volumes:
      - name: config-volume
        configMap:
          name: app-config
---
# Order Service
apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-service
  labels:
    app: microservices
    service: order
spec:
  replicas: 2
  selector:
    matchLabels:
      app: microservices
      service: order
  template:
    metadata:
      labels:
        app: microservices
        service: order
    spec:
      containers:
      - name: order-api
        image: nginx:alpine
        ports:
        - containerPort: 80
        env:
        - name: USER_SERVICE_URL
          value: "http://user-service:80"
---
# Services
apiVersion: v1
kind: Service
metadata:
  name: user-service
spec:
  selector:
    app: microservices
    service: user
  ports:
    - port: 80
      targetPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: order-service
spec:
  selector:
    app: microservices
    service: order
  ports:
    - port: 80
      targetPort: 80
EOF

# Apply microservices
kubectl apply -f microservices-app.yaml

# Check configuration mounting
kubectl exec -it deployment/user-service -- ls /etc/config
kubectl exec -it deployment/user-service -- cat /etc/config/app.properties
```

### Exercise 3: Application with Persistent Storage
```bash
# Create application with persistent volume
cat > persistent-app.yaml << EOF
# Persistent Volume Claim
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-storage
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: gp2
---
# Application with persistent storage
apiVersion: apps/v1
kind: Deployment
metadata:
  name: persistent-app
  labels:
    app: persistent-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: persistent-demo
  template:
    metadata:
      labels:
        app: persistent-demo
    spec:
      containers:
      - name: app
        image: nginx:alpine
        ports:
        - containerPort: 80
        volumeMounts:
        - name: app-storage
          mountPath: /usr/share/nginx/html
        - name: init-script
          mountPath: /docker-entrypoint.d/
      volumes:
      - name: app-storage
        persistentVolumeClaim:
          claimName: app-storage
      - name: init-script
        configMap:
          name: init-script
          defaultMode: 0755
---
# Initialization script
apiVersion: v1
kind: ConfigMap
metadata:
  name: init-script
data:
  init.sh: |
    #!/bin/sh
    echo "<h1>Persistent Storage Demo</h1>" > /usr/share/nginx/html/index.html
    echo "<p>Data persists across pod restarts</p>" >> /usr/share/nginx/html/index.html
    echo "<p>Pod: $HOSTNAME</p>" >> /usr/share/nginx/html/index.html
---
# Service
apiVersion: v1
kind: Service
metadata:
  name: persistent-app-service
spec:
  selector:
    app: persistent-demo
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30081
  type: NodePort
EOF

# Apply persistent application
kubectl apply -f persistent-app.yaml

# Test persistence
kubectl get pvc
kubectl exec -it deployment/persistent-app -- ls -la /usr/share/nginx/html
```

## Cleanup
```bash
# Clean up all resources in namespace
kubectl delete all --all -n k8s-declarative
kubectl delete pvc --all -n k8s-declarative
kubectl delete configmap --all -n k8s-declarative
```

## Key Takeaways
1. Multi-resource YAML files use `---` separators
2. Labels and selectors create relationships between resources
3. ConfigMaps provide external configuration
4. Services enable inter-service communication
5. Persistent volumes provide data durability
6. Resource organization is crucial for complex applications

## Next Steps
- Move to Lab 3: ConfigMaps and Secrets
- Practice with different application architectures
- Learn about Helm for complex deployments