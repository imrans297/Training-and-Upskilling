# Lab 1: Docker Basics and Container Operations

## What We're Achieving
Master Docker fundamentals including container lifecycle, image management, and basic operations essential for Kubernetes.

## What We're Doing
- Install and configure Docker
- Run containers with various options
- Manage container lifecycle
- Work with Docker images and registries

## Prerequisites
- EC2 instance or local machine with Docker
- Basic Linux command knowledge
- Internet connectivity

## Lab Exercises

### Exercise 1: Docker Installation and Verification
```bash
# Install Docker (Ubuntu/Amazon Linux)
sudo yum update -y
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER

# Logout and login again, then verify
docker --version
docker info
docker run hello-world
```

### Exercise 2: Basic Container Operations
```bash
# Run interactive container
docker run -it ubuntu:20.04 /bin/bash
# Inside container: ls, pwd, cat /etc/os-release, exit

# Run container in background
docker run -d --name web-server nginx:alpine

# List running containers
docker ps

# List all containers
docker ps -a

# Check container logs
docker logs web-server

# Execute commands in running container
docker exec -it web-server /bin/sh
# Inside: ls /usr/share/nginx/html, exit
```

### Exercise 3: Container Networking and Port Mapping
```bash
# Run nginx with port mapping
docker run -d --name nginx-web -p 8080:80 nginx:alpine

# Test web access
curl http://localhost:8080

# Run container with custom content
docker run -d --name custom-web -p 8081:80 -v /tmp/html:/usr/share/nginx/html nginx:alpine

# Create custom content
mkdir -p /tmp/html
echo "<h1>Custom Docker Web Server</h1>" > /tmp/html/index.html
curl http://localhost:8081

# Check port mappings
docker port nginx-web
docker port custom-web
```

### Exercise 4: Volume Management
```bash
# Create named volume
docker volume create app-data

# List volumes
docker volume ls

# Run container with named volume
docker run -d --name data-container -v app-data:/data alpine:latest sleep 3600

# Add data to volume
docker exec data-container sh -c "echo 'Persistent data' > /data/test.txt"
docker exec data-container cat /data/test.txt

# Remove container but keep volume
docker rm -f data-container

# Create new container with same volume
docker run -d --name new-container -v app-data:/data alpine:latest sleep 3600
docker exec new-container cat /data/test.txt

# Bind mount example
mkdir -p /tmp/bind-mount
echo "Host file" > /tmp/bind-mount/host.txt
docker run --rm -v /tmp/bind-mount:/mount alpine:latest cat /mount/host.txt
```

### Exercise 5: Environment Variables and Configuration
```bash
# Run container with environment variables
docker run -d --name env-test \
  -e ENV_VAR1="Hello Docker" \
  -e ENV_VAR2="Production" \
  -p 8082:80 \
  nginx:alpine

# Check environment variables
docker exec env-test env | grep ENV_VAR

# Run MySQL with environment configuration
docker run -d --name mysql-db \
  -e MYSQL_ROOT_PASSWORD=rootpass \
  -e MYSQL_DATABASE=testdb \
  -e MYSQL_USER=testuser \
  -e MYSQL_PASSWORD=testpass \
  -p 3306:3306 \
  mysql:8.0

# Wait for MySQL to start
sleep 30

# Test MySQL connection
docker exec mysql-db mysql -u root -prootpass -e "SHOW DATABASES;"
```

### Exercise 6: Container Resource Management
```bash
# Run container with resource limits
docker run -d --name limited-container \
  --memory=512m \
  --cpus=0.5 \
  nginx:alpine

# Check resource usage
docker stats limited-container --no-stream

# Run stress test container
docker run -d --name stress-test \
  --memory=256m \
  --cpus=0.25 \
  polinux/stress stress --vm 1 --vm-bytes 200M --timeout 60s

# Monitor resources
docker stats --no-stream
```

### Exercise 7: Container Inspection and Troubleshooting
```bash
# Inspect container details
docker inspect nginx-web

# Check container processes
docker top nginx-web

# View container filesystem changes
docker diff nginx-web

# Copy files to/from container
echo "External file" > /tmp/external.txt
docker cp /tmp/external.txt nginx-web:/tmp/
docker exec nginx-web cat /tmp/external.txt

# Copy from container
docker cp nginx-web:/etc/nginx/nginx.conf /tmp/nginx.conf
cat /tmp/nginx.conf
```

## Cleanup
```bash
# Stop all running containers
docker stop $(docker ps -q)

# Remove all containers
docker rm $(docker ps -aq)

# Remove volumes
docker volume rm app-data

# Remove unused images
docker image prune -f

# Clean up files
rm -rf /tmp/html /tmp/bind-mount /tmp/external.txt /tmp/nginx.conf
```

## Key Takeaways
1. Containers are lightweight, portable runtime environments
2. Port mapping enables external access to container services
3. Volumes provide persistent storage for containers
4. Environment variables configure container behavior
5. Resource limits prevent containers from consuming excessive resources
6. Container inspection tools help with troubleshooting
7. Proper cleanup prevents resource accumulation

## Next Steps
- Move to Lab 2: Dockerfile and Image Building
- Practice with different base images
- Learn about container networking modes