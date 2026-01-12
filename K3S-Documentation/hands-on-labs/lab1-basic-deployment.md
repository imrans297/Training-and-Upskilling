# Lab 1: Basic K3S Deployment

## Lab Overview
Deploy a complete web application stack on K3S including:
- Frontend (Nginx)
- Backend (Node.js API)
- Database (MongoDB)
- Persistent storage
- Service exposure

**Duration**: 30-45 minutes

## Prerequisites
- K3S installed (single or multi-node)
- kubectl configured
- Basic Kubernetes knowledge

## Lab Architecture

```
┌──────────────────────────────────────────┐
│           Internet/User                  │
└────────────────┬─────────────────────────┘
                 │
                 ▼
┌────────────────────────────────────────┐
│        NodePort Service (30080)        │
└────────────────┬───────────────────────┘
                 │
                 ▼
┌────────────────────────────────────────┐
│      Nginx Frontend (3 replicas)       │
└────────────────┬───────────────────────┘
                 │
                 ▼
┌────────────────────────────────────────┐
│      Backend API (2 replicas)          │
└────────────────┬───────────────────────┘
                 │
                 ▼
┌────────────────────────────────────────┐
│      MongoDB (StatefulSet)             │
│      + Persistent Volume                │
└────────────────────────────────────────┘
```

## Step 1: Create Namespace

```bash
# Create namespace
kubectl create namespace webapp

# Set as default
kubectl config set-context --current --namespace=webapp

# Verify
kubectl get ns
```

## Step 2: Deploy MongoDB with Persistent Storage

### Create PersistentVolumeClaim

```yaml
# mongodb-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mongodb-pvc
  namespace: webapp
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: local-path
  resources:
    requests:
      storage: 1Gi
```

```bash
kubectl apply -f mongodb-pvc.yaml
kubectl get pvc
```

### Deploy MongoDB

```yaml
# mongodb-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongodb
  namespace: webapp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mongodb
  template:
    metadata:
      labels:
        app: mongodb
    spec:
      containers:
      - name: mongodb
        image: mongo:5.0
        ports:
        - containerPort: 27017
        env:
        - name: MONGO_INITDB_ROOT_USERNAME
          value: "admin"
        - name: MONGO_INITDB_ROOT_PASSWORD
          value: "password123"
        volumeMounts:
        - name: mongodb-storage
          mountPath: /data/db
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
      volumes:
      - name: mongodb-storage
        persistentVolumeClaim:
          claimName: mongodb-pvc
```

```bash
kubectl apply -f mongodb-deployment.yaml
kubectl get pods -l app=mongodb
kubectl logs -l app=mongodb
```

### Create MongoDB Service

```yaml
# mongodb-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: mongodb-service
  namespace: webapp
spec:
  selector:
    app: mongodb
  ports:
  - port: 27017
    targetPort: 27017
  type: ClusterIP
```

```bash
kubectl apply -f mongodb-service.yaml
kubectl get svc mongodb-service
```

## Step 3: Deploy Backend API

### Create ConfigMap for Backend

```yaml
# backend-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: backend-config
  namespace: webapp
data:
  MONGO_URL: "mongodb://admin:password123@mongodb-service:27017"
  PORT: "3000"
  NODE_ENV: "production"
```

```bash
kubectl apply -f backend-config.yaml
```

### Deploy Backend

```yaml
# backend-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: webapp
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
      - name: backend
        image: node:16-alpine
        command: ["/bin/sh"]
        args:
          - -c
          - |
            cat > server.js << 'EOF'
            const http = require('http');
            const port = process.env.PORT || 3000;
            
            const server = http.createServer((req, res) => {
              if (req.url === '/health') {
                res.writeHead(200);
                res.end('OK');
              } else if (req.url === '/api/data') {
                res.writeHead(200, {'Content-Type': 'application/json'});
                res.end(JSON.stringify({
                  message: 'Hello from Backend',
                  timestamp: new Date().toISOString(),
                  hostname: require('os').hostname()
                }));
              } else {
                res.writeHead(404);
                res.end('Not Found');
              }
            });
            
            server.listen(port, () => {
              console.log(`Server running on port ${port}`);
            });
            EOF
            node server.js
        ports:
        - containerPort: 3000
        envFrom:
        - configMapRef:
            name: backend-config
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 10
          periodSeconds: 5
        readinessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 3
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
```

```bash
kubectl apply -f backend-deployment.yaml
kubectl get pods -l app=backend
kubectl logs -l app=backend
```

### Create Backend Service

```yaml
# backend-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: backend-service
  namespace: webapp
spec:
  selector:
    app: backend
  ports:
  - port: 3000
    targetPort: 3000
  type: ClusterIP
```

```bash
kubectl apply -f backend-service.yaml
kubectl get svc backend-service
```

## Step 4: Deploy Frontend (Nginx)

### Create Nginx ConfigMap

```yaml
# nginx-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
  namespace: webapp
data:
  nginx.conf: |
    events {
      worker_connections 1024;
    }
    
    http {
      upstream backend {
        server backend-service:3000;
      }
      
      server {
        listen 80;
        
        location / {
          root /usr/share/nginx/html;
          index index.html;
        }
        
        location /api/ {
          proxy_pass http://backend/api/;
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
        }
      }
    }
  index.html: |
    <!DOCTYPE html>
    <html>
    <head>
      <title>K3S Web App</title>
      <style>
        body { font-family: Arial; margin: 50px; background: #f0f0f0; }
        .container { background: white; padding: 30px; border-radius: 10px; }
        button { padding: 10px 20px; font-size: 16px; cursor: pointer; }
        #result { margin-top: 20px; padding: 15px; background: #e8f4f8; }
      </style>
    </head>
    <body>
      <div class="container">
        <h1>Welcome to K3S Web Application</h1>
        <p>This is a demo application running on K3S cluster</p>
        <button onclick="fetchData()">Fetch Backend Data</button>
        <div id="result"></div>
      </div>
      <script>
        async function fetchData() {
          try {
            const response = await fetch('/api/data');
            const data = await response.json();
            document.getElementById('result').innerHTML = 
              '<h3>Backend Response:</h3>' +
              '<pre>' + JSON.stringify(data, null, 2) + '</pre>';
          } catch (error) {
            document.getElementById('result').innerHTML = 
              '<p style="color:red;">Error: ' + error.message + '</p>';
          }
        }
      </script>
    </body>
    </html>
```

```bash
kubectl apply -f nginx-config.yaml
```

### Deploy Nginx Frontend

```yaml
# frontend-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: webapp
spec:
  replicas: 3
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
        - name: nginx-config
          mountPath: /etc/nginx/nginx.conf
          subPath: nginx.conf
        - name: nginx-config
          mountPath: /usr/share/nginx/html/index.html
          subPath: index.html
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
      volumes:
      - name: nginx-config
        configMap:
          name: nginx-config
```

```bash
kubectl apply -f frontend-deployment.yaml
kubectl get pods -l app=frontend
```

### Expose Frontend Service

```yaml
# frontend-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
  namespace: webapp
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
  type: NodePort
```

```bash
kubectl apply -f frontend-service.yaml
kubectl get svc frontend-service
```

## Step 5: Verify Deployment

### Check All Resources

```bash
# Check all pods
kubectl get pods -n webapp

# Check services
kubectl get svc -n webapp

# Check PVC
kubectl get pvc -n webapp

# Check deployments
kubectl get deployments -n webapp
```

### Test Application

```bash
# Get node IP
kubectl get nodes -o wide

# Test frontend (replace NODE_IP)
curl http://<NODE_IP>:30080

# Test backend through frontend
curl http://<NODE_IP>:30080/api/data

# Or open in browser
# http://<NODE_IP>:30080
```

## Step 6: Scale Application

```bash
# Scale frontend
kubectl scale deployment frontend --replicas=5 -n webapp

# Scale backend
kubectl scale deployment backend --replicas=3 -n webapp

# Verify
kubectl get pods -n webapp
```

## Step 7: Monitor Application

### Check Logs

```bash
# Frontend logs
kubectl logs -l app=frontend -n webapp --tail=50

# Backend logs
kubectl logs -l app=backend -n webapp --tail=50 -f

# MongoDB logs
kubectl logs -l app=mongodb -n webapp --tail=50
```

### Check Resource Usage

```bash
# Pod resources
kubectl top pods -n webapp

# Node resources
kubectl top nodes
```

### Describe Resources

```bash
# Describe pod
kubectl describe pod -l app=frontend -n webapp

# Check events
kubectl get events -n webapp --sort-by='.lastTimestamp'
```

## Step 8: Test High Availability

### Delete a Pod

```bash
# Delete frontend pod
kubectl delete pod -l app=frontend -n webapp --force --grace-period=0

# Watch pods recreate
kubectl get pods -n webapp -w
```

### Simulate Load

```bash
# Install hey (load testing tool)
# Or use curl in loop
for i in {1..100}; do
  curl -s http://<NODE_IP>:30080/api/data
  sleep 0.1
done
```

## Step 9: Update Application

### Rolling Update

```yaml
# Update backend image
kubectl set image deployment/backend \
  backend=node:18-alpine \
  -n webapp

# Watch rollout
kubectl rollout status deployment/backend -n webapp

# Check rollout history
kubectl rollout history deployment/backend -n webapp
```

### Rollback

```bash
# Rollback to previous version
kubectl rollout undo deployment/backend -n webapp

# Rollback to specific revision
kubectl rollout undo deployment/backend --to-revision=1 -n webapp
```

## Step 10: Cleanup

```bash
# Delete all resources in namespace
kubectl delete namespace webapp

# Or delete individually
kubectl delete -f frontend-service.yaml
kubectl delete -f frontend-deployment.yaml
kubectl delete -f backend-service.yaml
kubectl delete -f backend-deployment.yaml
kubectl delete -f mongodb-service.yaml
kubectl delete -f mongodb-deployment.yaml
kubectl delete -f mongodb-pvc.yaml
```

## Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl describe pod <pod-name> -n webapp

# Check events
kubectl get events -n webapp

# Check logs
kubectl logs <pod-name> -n webapp
```

### Service Not Accessible

```bash
# Check service endpoints
kubectl get endpoints -n webapp

# Test from within cluster
kubectl run -it --rm debug --image=busybox --restart=Never -n webapp -- sh
wget -O- http://backend-service:3000/api/data
```

### Storage Issues

```bash
# Check PVC status
kubectl describe pvc mongodb-pvc -n webapp

# Check PV
kubectl get pv
```

## Next Steps

- [Lab 2: Ingress Setup](lab2-ingress-setup.md)
- [Lab 3: Persistent Storage](lab3-persistent-storage.md)
- [Lab 4: Monitoring](lab4-monitoring.md)
