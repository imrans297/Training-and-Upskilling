# 08. Container Orchestration

## What is Container Orchestration?

Container orchestration automates the deployment, management, scaling, and networking of containers across clusters of hosts.

## Why Orchestration?

- **Scaling**: Automatically scale containers up/down
- **Load Balancing**: Distribute traffic across containers
- **Self-Healing**: Restart failed containers
- **Rolling Updates**: Zero-downtime deployments
- **Service Discovery**: Automatic DNS and networking
- **Resource Management**: Optimize resource usage

## Docker Swarm

### Initialize Swarm

```bash
# Initialize swarm (manager node)
docker swarm init

# With specific IP
docker swarm init --advertise-addr 192.168.1.100

# Get join token for workers
docker swarm join-token worker

# Get join token for managers
docker swarm join-token manager
```

### Join Swarm

```bash
# Join as worker
docker swarm join \
  --token SWMTKN-1-xxx \
  192.168.1.100:2377

# Join as manager
docker swarm join \
  --token SWMTKN-1-xxx \
  --advertise-addr 192.168.1.101 \
  192.168.1.100:2377
```

### Swarm Management

```bash
# List nodes
docker node ls

# Inspect node
docker node inspect node-id

# Promote worker to manager
docker node promote node-id

# Demote manager to worker
docker node demote node-id

# Remove node
docker node rm node-id

# Leave swarm
docker swarm leave

# Leave swarm (force on manager)
docker swarm leave --force
```

### Services

```bash
# Create service
docker service create --name web nginx

# Create with replicas
docker service create \
  --name web \
  --replicas 3 \
  nginx

# Create with port mapping
docker service create \
  --name web \
  --replicas 3 \
  -p 8080:80 \
  nginx

# List services
docker service ls

# Inspect service
docker service inspect web

# View service logs
docker service logs web

# Scale service
docker service scale web=5

# Update service
docker service update --image nginx:alpine web

# Remove service
docker service rm web
```

### Service Constraints

```bash
# Run on specific node
docker service create \
  --name web \
  --constraint 'node.hostname==node1' \
  nginx

# Run on nodes with label
docker service create \
  --name web \
  --constraint 'node.labels.type==frontend' \
  nginx

# Multiple constraints
docker service create \
  --name web \
  --constraint 'node.role==worker' \
  --constraint 'node.labels.region==us-east' \
  nginx
```

### Service Networks

```bash
# Create overlay network
docker network create --driver overlay myoverlay

# Create service on network
docker service create \
  --name web \
  --network myoverlay \
  nginx

# Attach service to network
docker service update --network-add myoverlay web
```

### Service Volumes

```bash
# Create service with volume
docker service create \
  --name web \
  --mount type=volume,source=webdata,target=/data \
  nginx

# Bind mount
docker service create \
  --name web \
  --mount type=bind,source=/host/path,target=/container/path \
  nginx
```

### Rolling Updates

```bash
# Update with rolling update
docker service update \
  --image nginx:alpine \
  --update-parallelism 2 \
  --update-delay 10s \
  web

# Rollback
docker service rollback web
```

### Stack Deployment

```yaml
# docker-stack.yml
version: '3.8'

services:
  web:
    image: nginx:alpine
    ports:
      - "8080:80"
    deploy:
      replicas: 3
      update_config:
        parallelism: 1
        delay: 10s
      restart_policy:
        condition: on-failure
    networks:
      - webnet

  visualizer:
    image: dockersamples/visualizer
    ports:
      - "8081:8080"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    deploy:
      placement:
        constraints:
          - node.role==manager
    networks:
      - webnet

networks:
  webnet:
    driver: overlay
```

```bash
# Deploy stack
docker stack deploy -c docker-stack.yml mystack

# List stacks
docker stack ls

# List stack services
docker stack services mystack

# List stack tasks
docker stack ps mystack

# Remove stack
docker stack rm mystack
```

## Kubernetes Overview

### Key Concepts

- **Pod**: Smallest deployable unit
- **Service**: Stable network endpoint
- **Deployment**: Manages pod replicas
- **Namespace**: Virtual cluster
- **ConfigMap**: Configuration data
- **Secret**: Sensitive data
- **Ingress**: HTTP routing

### Basic Commands

```bash
# Get cluster info
kubectl cluster-info

# Get nodes
kubectl get nodes

# Get pods
kubectl get pods

# Get services
kubectl get services

# Describe resource
kubectl describe pod pod-name

# View logs
kubectl logs pod-name

# Execute command
kubectl exec -it pod-name -- /bin/bash
```

### Simple Deployment

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
```

```bash
# Apply deployment
kubectl apply -f deployment.yaml

# Scale deployment
kubectl scale deployment nginx-deployment --replicas=5

# Update image
kubectl set image deployment/nginx-deployment nginx=nginx:latest

# Rollback
kubectl rollout undo deployment/nginx-deployment
```

### Service Definition

```yaml
# service.yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
  type: LoadBalancer
```

## Comparison: Swarm vs Kubernetes

| Feature | Docker Swarm | Kubernetes |
|---------|--------------|------------|
| Setup | Easy | Complex |
| Learning Curve | Low | High |
| Scaling | Good | Excellent |
| Community | Smaller | Large |
| Features | Basic | Advanced |
| Best For | Small/Medium | Enterprise |

## Orchestration Best Practices

1. **High Availability**: Multiple manager nodes
2. **Resource Limits**: Set CPU/memory limits
3. **Health Checks**: Implement liveness/readiness probes
4. **Secrets Management**: Use secrets, not env vars
5. **Logging**: Centralized logging solution
6. **Monitoring**: Prometheus, Grafana
7. **Backup**: Regular etcd/swarm backups
8. **Security**: RBAC, network policies

## Docker Swarm Complete Example

```yaml
version: '3.8'

services:
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    deploy:
      replicas: 3
      update_config:
        parallelism: 1
        delay: 10s
      restart_policy:
        condition: on-failure
        max_attempts: 3
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M
    networks:
      - frontend
    configs:
      - source: nginx_config
        target: /etc/nginx/nginx.conf

  app:
    image: myapp:latest
    deploy:
      replicas: 5
      placement:
        constraints:
          - node.role==worker
    networks:
      - frontend
      - backend
    secrets:
      - db_password

  db:
    image: postgres:14
    deploy:
      replicas: 1
      placement:
        constraints:
          - node.labels.type==database
    volumes:
      - db-data:/var/lib/postgresql/data
    networks:
      - backend
    secrets:
      - db_password
    environment:
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password

networks:
  frontend:
    driver: overlay
  backend:
    driver: overlay
    internal: true

volumes:
  db-data:
    driver: local

configs:
  nginx_config:
    file: ./nginx.conf

secrets:
  db_password:
    external: true
```

## Monitoring and Logging

```bash
# Service logs
docker service logs -f web

# Node stats
docker node ps node-id

# Service tasks
docker service ps web

# Swarm events
docker events --filter type=service
```

## Troubleshooting

```bash
# Check service status
docker service ps web

# Inspect failed tasks
docker inspect task-id

# Check node availability
docker node ls

# View service constraints
docker service inspect web --pretty

# Force update
docker service update --force web
```

## Screenshots
![Docker Swarm](screenshots/docker-swarm.png)
![Service Scaling](screenshots/service-scaling.png)
![Stack Deployment](screenshots/stack-deploy.png)
![Kubernetes Dashboard](screenshots/k8s-dashboard.png)
