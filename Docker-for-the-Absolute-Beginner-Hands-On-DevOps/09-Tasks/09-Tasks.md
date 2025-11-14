# 09. Hands-On Tasks

## Task 1: Simple Web Server

**Objective**: Deploy a static website using Nginx

### Steps:
1. Create HTML files
2. Create Dockerfile
3. Build image
4. Run container
5. Test website

### Solution:
```bash
# Create index.html
cat > index.html << EOF
<!DOCTYPE html>
<html>
<head><title>My Docker Site</title></head>
<body><h1>Hello from Docker!</h1></body>
</html>
EOF

# Create Dockerfile
cat > Dockerfile << EOF
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/
EXPOSE 80
EOF

# Build and run
docker build -t mywebsite .
docker run -d -p 8080:80 --name website mywebsite

# Test
curl http://localhost:8080
```

## Task 2: Multi-Container Application

**Objective**: Deploy WordPress with MySQL using Docker Compose

### docker-compose.yml:
```yaml
version: '3.8'

services:
  wordpress:
    image: wordpress:latest
    ports:
      - "8080:80"
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_USER: wordpress
      WORDPRESS_DB_PASSWORD: secret
      WORDPRESS_DB_NAME: wordpress
    volumes:
      - wordpress_data:/var/www/html
    depends_on:
      - db

  db:
    image: mysql:8.0
    environment:
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wordpress
      MYSQL_PASSWORD: secret
      MYSQL_ROOT_PASSWORD: rootsecret
    volumes:
      - db_data:/var/lib/mysql

volumes:
  wordpress_data:
  db_data:
```

### Commands:
```bash
docker-compose up -d
docker-compose ps
docker-compose logs -f
# Access http://localhost:8080
docker-compose down
```

## Task 3: Python Flask Application

**Objective**: Containerize a Flask application

### app.py:
```python
from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello():
    return 'Hello from Flask in Docker!'

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

### requirements.txt:
```
Flask==2.3.0
```

### Dockerfile:
```dockerfile
FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY app.py .
EXPOSE 5000
CMD ["python", "app.py"]
```

### Commands:
```bash
docker build -t flask-app .
docker run -d -p 5000:5000 flask-app
curl http://localhost:5000
```

## Task 4: Node.js API with MongoDB

**Objective**: Create a REST API with database

### docker-compose.yml:
```yaml
version: '3.8'

services:
  api:
    build: .
    ports:
      - "3000:3000"
    environment:
      MONGO_URL: mongodb://mongo:27017/mydb
    depends_on:
      - mongo

  mongo:
    image: mongo:5
    ports:
      - "27017:27017"
    volumes:
      - mongo_data:/data/db

volumes:
  mongo_data:
```

### Dockerfile:
```dockerfile
FROM node:16-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3000
CMD ["node", "server.js"]
```

## Task 5: Multi-Stage Build

**Objective**: Optimize image size with multi-stage build

### Dockerfile:
```dockerfile
# Build stage
FROM node:16 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Production stage
FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

## Task 6: Private Registry Setup

**Objective**: Set up and use a private Docker registry

### Steps:
```bash
# Start registry
docker run -d -p 5000:5000 --name registry registry:2

# Tag image
docker tag myapp:latest localhost:5000/myapp:latest

# Push to registry
docker push localhost:5000/myapp:latest

# Pull from registry
docker pull localhost:5000/myapp:latest

# List images in registry
curl http://localhost:5000/v2/_catalog
```

## Task 7: Docker Swarm Deployment

**Objective**: Deploy application on Docker Swarm

### Steps:
```bash
# Initialize swarm
docker swarm init

# Create service
docker service create \
  --name web \
  --replicas 3 \
  -p 8080:80 \
  nginx

# Scale service
docker service scale web=5

# Update service
docker service update --image nginx:alpine web

# Remove service
docker service rm web
```

## Task 8: Health Check Implementation

**Objective**: Add health checks to containers

### Dockerfile:
```dockerfile
FROM nginx:alpine

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost/ || exit 1

COPY index.html /usr/share/nginx/html/
```

### docker-compose.yml:
```yaml
version: '3.8'

services:
  web:
    image: nginx:alpine
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost/"]
      interval: 30s
      timeout: 3s
      retries: 3
      start_period: 5s
```

## Task 9: Volume Backup and Restore

**Objective**: Backup and restore Docker volumes

### Backup:
```bash
# Create volume
docker volume create mydata

# Run container with volume
docker run -d -v mydata:/data --name app nginx

# Backup volume
docker run --rm \
  -v mydata:/data \
  -v $(pwd):/backup \
  ubuntu tar czf /backup/backup.tar.gz /data
```

### Restore:
```bash
# Create new volume
docker volume create mydata-restored

# Restore backup
docker run --rm \
  -v mydata-restored:/data \
  -v $(pwd):/backup \
  ubuntu tar xzf /backup/backup.tar.gz -C /
```

## Task 10: CI/CD Pipeline

**Objective**: Automate Docker build and deployment

### .gitlab-ci.yml:
```yaml
stages:
  - build
  - test
  - deploy

build:
  stage: build
  script:
    - docker build -t myapp:$CI_COMMIT_SHA .
    - docker tag myapp:$CI_COMMIT_SHA myapp:latest
    - docker push myapp:$CI_COMMIT_SHA
    - docker push myapp:latest

test:
  stage: test
  script:
    - docker run myapp:$CI_COMMIT_SHA npm test

deploy:
  stage: deploy
  script:
    - docker service update --image myapp:$CI_COMMIT_SHA production
  only:
    - main
```

## Challenge Tasks

### Challenge 1: Microservices Architecture
Deploy a complete microservices application with:
- Frontend (React)
- Backend API (Node.js)
- Database (PostgreSQL)
- Cache (Redis)
- Message Queue (RabbitMQ)

### Challenge 2: Monitoring Stack
Set up monitoring with:
- Prometheus
- Grafana
- cAdvisor
- Node Exporter

### Challenge 3: Logging Stack
Implement centralized logging:
- Elasticsearch
- Logstash
- Kibana (ELK Stack)

### Challenge 4: Security Hardening
- Scan images for vulnerabilities
- Implement secrets management
- Use non-root users
- Enable Docker Content Trust
- Set up network policies

## Practice Exercises

1. **Exercise 1**: Create a custom base image for your organization
2. **Exercise 2**: Implement blue-green deployment with Docker Swarm
3. **Exercise 3**: Set up automated testing in containers
4. **Exercise 4**: Create a development environment with Docker Compose
5. **Exercise 5**: Implement container resource limits and monitoring

## Real-World Scenarios

### Scenario 1: Database Migration
Migrate from local database to containerized database with zero downtime

### Scenario 2: Legacy Application
Containerize a legacy application with minimal changes

### Scenario 3: Development Environment
Create reproducible development environment for team

### Scenario 4: Production Deployment
Deploy production application with high availability

### Scenario 5: Disaster Recovery
Implement backup and recovery strategy for containers

## Screenshots
![Task Completion](screenshots/task-complete.png)
![Multi-Container App](screenshots/multi-container-task.png)
![Swarm Deployment](screenshots/swarm-task.png)
![CI/CD Pipeline](screenshots/cicd-task.png)
