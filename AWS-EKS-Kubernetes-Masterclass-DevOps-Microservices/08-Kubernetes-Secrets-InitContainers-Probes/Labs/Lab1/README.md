# Lab 1: Kubernetes Secrets and ConfigMaps

## What We're Achieving
Master Kubernetes configuration management using Secrets and ConfigMaps for secure and flexible application deployment.

## What We're Doing
- Create and manage Kubernetes Secrets
- Use ConfigMaps for application configuration
- Mount secrets and configs in pods
- Implement security best practices

## Prerequisites
- Shared training cluster running
- kubectl configured
- Understanding of Kubernetes pods

## Lab Exercises

### Exercise 1: Basic ConfigMaps
```bash
# Switch to secrets namespace
kubectl config set-context --current --namespace=secrets-probes

# Create ConfigMap from literal values
kubectl create configmap app-config \
  --from-literal=database_host=mysql.example.com \
  --from-literal=database_port=3306 \
  --from-literal=app_name="My Application" \
  --from-literal=log_level=INFO

# Create ConfigMap from file
cat > app.properties << EOF
# Application Configuration
app.name=My Kubernetes App
app.version=1.0.0
app.environment=development
database.pool.size=10
cache.enabled=true
debug.mode=false
EOF

kubectl create configmap app-properties --from-file=app.properties

# Create ConfigMap from directory
mkdir config-files
echo "server.port=8080" > config-files/server.conf
echo "worker.threads=4" > config-files/worker.conf
kubectl create configmap app-files --from-file=config-files/

# View ConfigMaps
kubectl get configmaps
kubectl describe configmap app-config
kubectl get configmap app-config -o yaml
```

### Exercise 2: Basic Secrets
```bash
# Create Secret from literal values
kubectl create secret generic db-credentials \
  --from-literal=username=admin \
  --from-literal=password=supersecret123

# Create Secret from files
echo -n 'admin' > username.txt
echo -n 'topsecret' > password.txt
kubectl create secret generic file-credentials \
  --from-file=username.txt \
  --from-file=password.txt

# Create TLS Secret
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt \
  -subj "/CN=myapp.example.com/O=myapp"

kubectl create secret tls tls-secret --cert=tls.crt --key=tls.key

# Create Docker registry secret
kubectl create secret docker-registry registry-secret \
  --docker-server=myregistry.com \
  --docker-username=myuser \
  --docker-password=mypass \
  --docker-email=user@example.com

# View Secrets (data is base64 encoded)
kubectl get secrets
kubectl describe secret db-credentials
kubectl get secret db-credentials -o yaml
```

### Exercise 3: Using ConfigMaps in Pods
```bash
# Pod with ConfigMap as environment variables
cat > configmap-env-pod.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: configmap-env-pod
  namespace: secrets-probes
spec:
  containers:
  - name: app
    image: busybox
    command: ["/bin/sh"]
    args: ["-c", "while true; do echo 'App running with config'; env | grep -E '(DATABASE|APP)'; sleep 30; done"]
    env:
    - name: DATABASE_HOST
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: database_host
    - name: DATABASE_PORT
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: database_port
    - name: APP_NAME
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: app_name
    envFrom:
    - configMapRef:
        name: app-config
  restartPolicy: Never
EOF

kubectl apply -f configmap-env-pod.yaml

# Check environment variables
kubectl logs configmap-env-pod
kubectl exec configmap-env-pod -- env | grep -E "(DATABASE|APP)"
```

### Exercise 4: Mounting ConfigMaps as Volumes
```bash
# Pod with ConfigMap mounted as volume
cat > configmap-volume-pod.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: configmap-volume-pod
  namespace: secrets-probes
spec:
  containers:
  - name: app
    image: nginx:alpine
    volumeMounts:
    - name: config-volume
      mountPath: /etc/config
    - name: properties-volume
      mountPath: /etc/properties
    - name: files-volume
      mountPath: /etc/files
    command: ["/bin/sh"]
    args: ["-c", "while true; do echo 'Config files:'; ls -la /etc/config /etc/properties /etc/files; sleep 60; done"]
  volumes:
  - name: config-volume
    configMap:
      name: app-config
  - name: properties-volume
    configMap:
      name: app-properties
  - name: files-volume
    configMap:
      name: app-files
  restartPolicy: Never
EOF

kubectl apply -f configmap-volume-pod.yaml

# Check mounted files
kubectl exec configmap-volume-pod -- ls -la /etc/config
kubectl exec configmap-volume-pod -- cat /etc/config/database_host
kubectl exec configmap-volume-pod -- cat /etc/properties/app.properties
```

### Exercise 5: Using Secrets in Pods
```bash
# Pod with Secret as environment variables
cat > secret-env-pod.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: secret-env-pod
  namespace: secrets-probes
spec:
  containers:
  - name: app
    image: mysql:8.0
    env:
    - name: MYSQL_ROOT_PASSWORD
      valueFrom:
        secretKeyRef:
          name: db-credentials
          key: password
    - name: MYSQL_USER
      valueFrom:
        secretKeyRef:
          name: db-credentials
          key: username
    - name: MYSQL_PASSWORD
      valueFrom:
        secretKeyRef:
          name: db-credentials
          key: password
    - name: MYSQL_DATABASE
      value: "testdb"
    ports:
    - containerPort: 3306
EOF

kubectl apply -f secret-env-pod.yaml

# Wait for MySQL to start
kubectl wait --for=condition=Ready pod/secret-env-pod --timeout=120s

# Test database connection
kubectl exec secret-env-pod -- mysql -u admin -psupersecret123 -e "SHOW DATABASES;"
```

### Exercise 6: Mounting Secrets as Volumes
```bash
# Pod with Secret mounted as volume
cat > secret-volume-pod.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: secret-volume-pod
  namespace: secrets-probes
spec:
  containers:
  - name: app
    image: nginx:alpine
    volumeMounts:
    - name: secret-volume
      mountPath: /etc/secrets
      readOnly: true
    - name: tls-volume
      mountPath: /etc/tls
      readOnly: true
    command: ["/bin/sh"]
    args: ["-c", "while true; do echo 'Secret files:'; ls -la /etc/secrets /etc/tls; sleep 60; done"]
  volumes:
  - name: secret-volume
    secret:
      secretName: db-credentials
      defaultMode: 0400
  - name: tls-volume
    secret:
      secretName: tls-secret
  restartPolicy: Never
EOF

kubectl apply -f secret-volume-pod.yaml

# Check mounted secrets
kubectl exec secret-volume-pod -- ls -la /etc/secrets
kubectl exec secret-volume-pod -- cat /etc/secrets/username
kubectl exec secret-volume-pod -- ls -la /etc/tls
```

### Exercise 7: Application with Complete Configuration
```bash
# Complete web application with configs and secrets
cat > complete-app.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: secrets-probes
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
      - name: web
        image: nginx:alpine
        ports:
        - containerPort: 80
        - containerPort: 443
        env:
        - name: APP_NAME
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: app_name
        - name: DB_HOST
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: database_host
        - name: DB_USER
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: username
        - name: DB_PASS
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: password
        volumeMounts:
        - name: config-volume
          mountPath: /etc/nginx/conf.d
        - name: tls-volume
          mountPath: /etc/nginx/ssl
        - name: html-volume
          mountPath: /usr/share/nginx/html
      volumes:
      - name: config-volume
        configMap:
          name: nginx-config
      - name: tls-volume
        secret:
          secretName: tls-secret
      - name: html-volume
        configMap:
          name: html-content
---
# Nginx configuration
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
  namespace: secrets-probes
data:
  default.conf: |
    server {
        listen 80;
        server_name localhost;
        location / {
            root /usr/share/nginx/html;
            index index.html;
        }
    }
    server {
        listen 443 ssl;
        server_name localhost;
        ssl_certificate /etc/nginx/ssl/tls.crt;
        ssl_certificate_key /etc/nginx/ssl/tls.key;
        location / {
            root /usr/share/nginx/html;
            index index.html;
        }
    }
---
# HTML content
apiVersion: v1
kind: ConfigMap
metadata:
  name: html-content
  namespace: secrets-probes
data:
  index.html: |
    <!DOCTYPE html>
    <html>
    <head>
        <title>Configured Web App</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 40px; }
            .config { background-color: #f0f0f0; padding: 20px; margin: 20px 0; }
        </style>
    </head>
    <body>
        <h1>Web Application with Configuration</h1>
        <div class="config">
            <h3>Configuration loaded from ConfigMaps and Secrets</h3>
            <p>This application demonstrates secure configuration management.</p>
            <p>Database and credentials are loaded from Kubernetes resources.</p>
        </div>
    </body>
    </html>
---
apiVersion: v1
kind: Service
metadata:
  name: web-app-service
  namespace: secrets-probes
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
      nodePort: 30443
  type: NodePort
EOF

kubectl apply -f complete-app.yaml

# Test the application
kubectl get pods -l app=web-app
kubectl get svc web-app-service

# Test HTTP access
kubectl port-forward service/web-app-service 8080:80 &
curl http://localhost:8080
kill %1
```

## Cleanup
```bash
# Delete all resources
kubectl delete pod configmap-env-pod configmap-volume-pod secret-env-pod secret-volume-pod -n secrets-probes
kubectl delete -f complete-app.yaml
kubectl delete configmap app-config app-properties app-files nginx-config html-content -n secrets-probes
kubectl delete secret db-credentials file-credentials tls-secret registry-secret -n secrets-probes

# Clean up files
rm -f app.properties username.txt password.txt tls.key tls.crt
rm -rf config-files
rm -f configmap-env-pod.yaml configmap-volume-pod.yaml secret-env-pod.yaml secret-volume-pod.yaml complete-app.yaml
```

## Key Takeaways
1. ConfigMaps store non-sensitive configuration data
2. Secrets store sensitive information with base64 encoding
3. Both can be used as environment variables or mounted volumes
4. Volume mounts provide file-based configuration
5. Secrets should have restricted file permissions (defaultMode)
6. Environment variables are visible in process lists
7. Volume mounts are more secure for sensitive data
8. ConfigMaps and Secrets can be updated independently of pods

## Next Steps
- Move to Lab 2: InitContainers and Startup Patterns
- Practice with different secret types
- Learn about secret rotation strategies