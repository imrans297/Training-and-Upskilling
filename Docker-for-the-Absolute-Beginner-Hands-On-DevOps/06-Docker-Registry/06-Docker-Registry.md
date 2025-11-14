# 06. Docker Registry

## What is Docker Registry?

A Docker registry is a storage and distribution system for Docker images. Docker Hub is the default public registry.

## Docker Hub

### Login to Docker Hub
```bash
# Login
docker login

# Login with username
docker login -u username

# Logout
docker logout
```

### Pushing Images
```bash
# Tag image with username
docker tag myapp:1.0 username/myapp:1.0

# Push to Docker Hub
docker push username/myapp:1.0

# Push all tags
docker push username/myapp --all-tags
```

### Pulling Images
```bash
# Pull from Docker Hub
docker pull username/myapp:1.0

# Pull latest
docker pull username/myapp

# Pull specific version
docker pull nginx:1.21-alpine
```

### Searching Images
```bash
# Search on Docker Hub
docker search nginx

# Search with filters
docker search --filter stars=100 nginx
docker search --filter is-official=true nginx
```

## Private Docker Registry

### Run Local Registry
```bash
# Start registry container
docker run -d -p 5000:5000 --name registry registry:2

# With persistent storage
docker run -d -p 5000:5000 \
  --name registry \
  -v registry-data:/var/lib/registry \
  registry:2
```

### Push to Private Registry
```bash
# Tag for private registry
docker tag myapp:1.0 localhost:5000/myapp:1.0

# Push to private registry
docker push localhost:5000/myapp:1.0

# Pull from private registry
docker pull localhost:5000/myapp:1.0
```

### Secure Registry with TLS
```bash
# Generate certificates
mkdir -p certs
openssl req -newkey rsa:4096 -nodes -sha256 \
  -keyout certs/domain.key -x509 -days 365 \
  -out certs/domain.crt

# Run with TLS
docker run -d -p 5000:5000 \
  --name registry \
  -v $(pwd)/certs:/certs \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
  -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
  registry:2
```

### Registry with Authentication
```bash
# Create password file
mkdir auth
docker run --entrypoint htpasswd \
  httpd:2 -Bbn username password > auth/htpasswd

# Run with authentication
docker run -d -p 5000:5000 \
  --name registry \
  -v $(pwd)/auth:/auth \
  -e REGISTRY_AUTH=htpasswd \
  -e REGISTRY_AUTH_HTPASSWD_REALM="Registry Realm" \
  -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
  registry:2

# Login to private registry
docker login localhost:5000
```

## AWS ECR (Elastic Container Registry)

### Login to ECR
```bash
# Get login password
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  123456789012.dkr.ecr.us-east-1.amazonaws.com
```

### Create Repository
```bash
# Create ECR repository
aws ecr create-repository --repository-name myapp
```

### Push to ECR
```bash
# Tag image
docker tag myapp:1.0 \
  123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp:1.0

# Push to ECR
docker push \
  123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp:1.0
```

## Google Container Registry (GCR)

### Configure GCR
```bash
# Configure Docker for GCR
gcloud auth configure-docker

# Tag image
docker tag myapp:1.0 gcr.io/project-id/myapp:1.0

# Push to GCR
docker push gcr.io/project-id/myapp:1.0
```

## Azure Container Registry (ACR)

### Login to ACR
```bash
# Login
az acr login --name myregistry

# Tag image
docker tag myapp:1.0 myregistry.azurecr.io/myapp:1.0

# Push to ACR
docker push myregistry.azurecr.io/myapp:1.0
```

## Image Tagging Strategies

### Semantic Versioning
```bash
docker tag myapp:latest myapp:1.0.0
docker tag myapp:latest myapp:1.0
docker tag myapp:latest myapp:1
```

### Environment Tags
```bash
docker tag myapp:latest myapp:dev
docker tag myapp:latest myapp:staging
docker tag myapp:latest myapp:production
```

### Git Commit Tags
```bash
docker tag myapp:latest myapp:$(git rev-parse --short HEAD)
docker tag myapp:latest myapp:commit-abc123
```

### Date Tags
```bash
docker tag myapp:latest myapp:$(date +%Y%m%d)
docker tag myapp:latest myapp:2024-01-15
```

## Registry API

### List Repositories
```bash
# List repositories
curl http://localhost:5000/v2/_catalog

# List tags
curl http://localhost:5000/v2/myapp/tags/list
```

### Delete Image
```bash
# Get digest
curl -I -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
  http://localhost:5000/v2/myapp/manifests/1.0

# Delete by digest
curl -X DELETE http://localhost:5000/v2/myapp/manifests/sha256:digest
```

## Registry Configuration

### config.yml
```yaml
version: 0.1
log:
  level: info
storage:
  filesystem:
    rootdirectory: /var/lib/registry
  delete:
    enabled: true
http:
  addr: :5000
  headers:
    X-Content-Type-Options: [nosniff]
health:
  storagedriver:
    enabled: true
    interval: 10s
    threshold: 3
```

## Docker Compose Registry Setup

```yaml
version: '3.8'

services:
  registry:
    image: registry:2
    ports:
      - "5000:5000"
    environment:
      REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY: /data
      REGISTRY_AUTH: htpasswd
      REGISTRY_AUTH_HTPASSWD_PATH: /auth/htpasswd
      REGISTRY_AUTH_HTPASSWD_REALM: Registry
    volumes:
      - registry-data:/data
      - ./auth:/auth
      - ./certs:/certs

  registry-ui:
    image: joxit/docker-registry-ui:latest
    ports:
      - "8080:80"
    environment:
      REGISTRY_URL: http://registry:5000
      DELETE_IMAGES: "true"
    depends_on:
      - registry

volumes:
  registry-data:
```

## Best Practices

1. **Use specific tags** - Avoid `latest` in production
2. **Implement tagging strategy** - Semantic versioning
3. **Scan images** - Security vulnerabilities
4. **Use private registries** - For proprietary code
5. **Enable authentication** - Secure access
6. **Regular cleanup** - Remove unused images
7. **Use image signing** - Docker Content Trust
8. **Monitor registry** - Disk usage and performance

## Image Scanning

```bash
# Scan with Docker Scout
docker scout cves myapp:1.0

# Scan with Trivy
trivy image myapp:1.0

# Scan with Snyk
snyk container test myapp:1.0
```

## Garbage Collection

```bash
# Run garbage collection
docker exec registry bin/registry garbage-collect \
  /etc/docker/registry/config.yml

# With dry-run
docker exec registry bin/registry garbage-collect \
  --dry-run /etc/docker/registry/config.yml
```

## Troubleshooting

```bash
# Check registry logs
docker logs registry

# Test registry connectivity
curl http://localhost:5000/v2/

# Verify image exists
curl http://localhost:5000/v2/myapp/tags/list

# Check disk usage
docker system df
```

## Screenshots
![Docker Hub](screenshots/docker-hub.png)
![Private Registry](screenshots/private-registry.png)
![ECR Console](screenshots/ecr-console.png)
![Registry UI](screenshots/registry-ui.png)
