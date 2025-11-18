# Lab 2: Dockerfile and Image Building

## What We're Achieving
Master Docker image creation using Dockerfiles, implement multi-stage builds, and optimize images for production use.

## What We're Doing
- Create custom Docker images with Dockerfiles
- Implement multi-stage builds for optimization
- Build images for different programming languages
- Optimize image size and security

## Prerequisites
- Completed Lab 1 (Docker Basics)
- Docker installed and running
- Basic understanding of application development

## Lab Exercises

### Exercise 1: Basic Dockerfile Creation
```bash
# Create a simple web application
mkdir -p webapp
cd webapp

# Create HTML content
cat > index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Custom Docker App</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background-color: #f0f8ff; }
        .container { max-width: 800px; margin: 0 auto; padding: 20px; }
        .info { background-color: #e8f4fd; padding: 20px; margin: 20px 0; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🐳 Custom Docker Application</h1>
        <div class="info">
            <h3>Application Details</h3>
            <p><strong>Built with:</strong> Custom Dockerfile</p>
            <p><strong>Base Image:</strong> nginx:alpine</p>
            <p><strong>Size:</strong> Optimized for production</p>
        </div>
    </div>
</body>
</html>
EOF

# Create basic Dockerfile
cat > Dockerfile << EOF
# Use official nginx alpine image
FROM nginx:alpine

# Set maintainer label
LABEL maintainer="training@example.com"
LABEL version="1.0"
LABEL description="Custom web application"

# Copy HTML content
COPY index.html /usr/share/nginx/html/

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
EOF

# Build the image
docker build -t custom-webapp:1.0 .

# Run the container
docker run -d --name webapp-container -p 8080:80 custom-webapp:1.0

# Test the application
curl http://localhost:8080

cd ..
```

### Exercise 2: Python Application with Dockerfile
```bash
# Create Python Flask application
mkdir -p python-app
cd python-app

# Create Flask application
cat > app.py << EOF
from flask import Flask, jsonify
import os
import socket
from datetime import datetime

app = Flask(__name__)

@app.route('/')
def hello():
    return jsonify({
        'message': 'Hello from Python Flask App!',
        'hostname': socket.gethostname(),
        'timestamp': datetime.now().isoformat(),
        'version': os.getenv('APP_VERSION', '1.0.0'),
        'environment': os.getenv('ENVIRONMENT', 'development')
    })

@app.route('/health')
def health():
    return jsonify({'status': 'healthy', 'timestamp': datetime.now().isoformat()})

@app.route('/info')
def info():
    return jsonify({
        'python_version': os.sys.version,
        'flask_version': '2.3.0',
        'container_info': {
            'hostname': socket.gethostname(),
            'environment_vars': dict(os.environ)
        }
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
EOF

# Create requirements file
cat > requirements.txt << EOF
Flask==2.3.0
Werkzeug==2.3.0
EOF

# Create Dockerfile for Python app
cat > Dockerfile << EOF
# Use official Python runtime as base image
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV APP_VERSION=1.0.0

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first (for better caching)
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app.py .

# Create non-root user
RUN adduser --disabled-password --gecos '' appuser
RUN chown -R appuser:appuser /app
USER appuser

# Expose port
EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:5000/health || exit 1

# Run the application
CMD ["python", "app.py"]
EOF

# Build Python application image
docker build -t python-flask-app:1.0 .

# Run the container
docker run -d --name flask-container -p 5000:5000 -e ENVIRONMENT=production python-flask-app:1.0

# Test the application
curl http://localhost:5000
curl http://localhost:5000/health
curl http://localhost:5000/info

cd ..
```

### Exercise 3: Multi-stage Build for Node.js Application
```bash
# Create Node.js application
mkdir -p nodejs-app
cd nodejs-app

# Create package.json
cat > package.json << EOF
{
  "name": "nodejs-docker-app",
  "version": "1.0.0",
  "description": "Node.js application with multi-stage Docker build",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  },
  "dependencies": {
    "express": "^4.18.0",
    "cors": "^2.8.5"
  },
  "devDependencies": {
    "nodemon": "^2.0.20"
  }
}
EOF

# Create Node.js server
cat > server.js << EOF
const express = require('express');
const cors = require('cors');
const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// Routes
app.get('/', (req, res) => {
    res.json({
        message: 'Node.js Multi-stage Docker App',
        version: process.env.npm_package_version || '1.0.0',
        environment: process.env.NODE_ENV || 'development',
        timestamp: new Date().toISOString(),
        hostname: require('os').hostname()
    });
});

app.get('/health', (req, res) => {
    res.json({ 
        status: 'healthy', 
        uptime: process.uptime(),
        memory: process.memoryUsage()
    });
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(\`Server running on port \${PORT}\`);
});
EOF

# Create multi-stage Dockerfile
cat > Dockerfile << EOF
# Build stage
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install all dependencies (including dev dependencies)
RUN npm ci --only=production && npm cache clean --force

# Production stage
FROM node:18-alpine AS production

# Create app directory
WORKDIR /app

# Create non-root user
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nodejs -u 1001

# Copy package files
COPY package*.json ./

# Copy node_modules from builder stage
COPY --from=builder /app/node_modules ./node_modules

# Copy application code
COPY server.js ./

# Change ownership to nodejs user
RUN chown -R nodejs:nodejs /app
USER nodejs

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

# Start the application
CMD ["node", "server.js"]
EOF

# Build multi-stage image
docker build -t nodejs-multistage:1.0 .

# Run the container
docker run -d --name nodejs-container -p 3000:3000 -e NODE_ENV=production nodejs-multistage:1.0

# Test the application
curl http://localhost:3000
curl http://localhost:3000/health

cd ..
```

### Exercise 4: Image Optimization Techniques
```bash
# Create optimized Dockerfile example
mkdir -p optimized-app
cd optimized-app

# Create a simple Go application
cat > main.go << EOF
package main

import (
    "encoding/json"
    "fmt"
    "log"
    "net/http"
    "os"
    "time"
)

type Response struct {
    Message   string    \`json:"message"\`
    Timestamp time.Time \`json:"timestamp"\`
    Hostname  string    \`json:"hostname"\`
    Version   string    \`json:"version"\`
}

func main() {
    http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        hostname, _ := os.Hostname()
        response := Response{
            Message:   "Optimized Go Application",
            Timestamp: time.Now(),
            Hostname:  hostname,
            Version:   "1.0.0",
        }
        
        w.Header().Set("Content-Type", "application/json")
        json.NewEncoder(w).Encode(response)
    })

    http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("Content-Type", "application/json")
        fmt.Fprintf(w, \`{"status":"healthy","timestamp":"%s"}\`, time.Now().Format(time.RFC3339))
    })

    port := os.Getenv("PORT")
    if port == "" {
        port = "8080"
    }

    log.Printf("Server starting on port %s", port)
    log.Fatal(http.ListenAndServe(":"+port, nil))
}
EOF

# Create optimized multi-stage Dockerfile
cat > Dockerfile << EOF
# Build stage
FROM golang:1.19-alpine AS builder

# Install git and ca-certificates (needed for go modules)
RUN apk add --no-cache git ca-certificates

# Set working directory
WORKDIR /app

# Copy go mod files
COPY go.* ./

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Build the binary with optimizations
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

# Final stage - use scratch for minimal image
FROM scratch

# Copy ca-certificates from builder
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Copy the binary
COPY --from=builder /app/main /main

# Expose port
EXPOSE 8080

# Run the binary
ENTRYPOINT ["/main"]
EOF

# Initialize go module
go mod init optimized-app
go mod tidy

# Build optimized image
docker build -t optimized-go-app:1.0 .

# Compare image sizes
echo "Image sizes comparison:"
docker images | grep -E "(optimized-go-app|nodejs-multistage|python-flask-app|custom-webapp)"

# Run optimized container
docker run -d --name optimized-container -p 8080:8080 optimized-go-app:1.0

# Test the application
curl http://localhost:8080
curl http://localhost:8080/health

cd ..
```

### Exercise 5: Docker Build Context and .dockerignore
```bash
# Create application with build context optimization
mkdir -p build-context-demo
cd build-context-demo

# Create various files
mkdir -p src tests docs logs
echo "console.log('main app');" > src/app.js
echo "console.log('test file');" > tests/test.js
echo "# Documentation" > docs/README.md
echo "log entry" > logs/app.log
echo "node_modules/" > .gitignore

# Create .dockerignore file
cat > .dockerignore << EOF
# Ignore unnecessary files to reduce build context
node_modules
npm-debug.log
logs/
*.log
tests/
docs/
.git
.gitignore
README.md
Dockerfile
.dockerignore
*.md
.DS_Store
.env.local
.env.development.local
.env.test.local
.env.production.local
EOF

# Create Dockerfile
cat > Dockerfile << EOF
FROM node:18-alpine

WORKDIR /app

# Copy only necessary files
COPY src/ ./src/

# Create a simple server
RUN echo 'const http = require("http"); \
const server = http.createServer((req, res) => { \
  res.writeHead(200, {"Content-Type": "application/json"}); \
  res.end(JSON.stringify({message: "Build context optimized app", timestamp: new Date()})); \
}); \
server.listen(3000, () => console.log("Server running on port 3000"));' > server.js

EXPOSE 3000
CMD ["node", "server.js"]
EOF

# Build and check build context
echo "Building with optimized build context..."
docker build -t build-context-demo:1.0 .

cd ..
```

### Exercise 6: Image Security Scanning
```bash
# Scan images for vulnerabilities (if Docker Scout is available)
echo "Scanning images for security vulnerabilities..."

# Scan the Python Flask app
docker scout cves python-flask-app:1.0 || echo "Docker Scout not available"

# Check image history and layers
docker history python-flask-app:1.0

# Inspect image for security information
docker inspect python-flask-app:1.0 | grep -A 10 -B 10 -i security || echo "No security info found"
```

## Cleanup
```bash
# Stop and remove containers
docker stop webapp-container flask-container nodejs-container optimized-container
docker rm webapp-container flask-container nodejs-container optimized-container

# Remove images
docker rmi custom-webapp:1.0 python-flask-app:1.0 nodejs-multistage:1.0 optimized-go-app:1.0 build-context-demo:1.0

# Clean up directories
rm -rf webapp python-app nodejs-app optimized-app build-context-demo

# Clean up unused images and build cache
docker system prune -f
```

## Key Takeaways
1. Dockerfiles define how to build custom images
2. Multi-stage builds reduce final image size significantly
3. Layer caching improves build performance
4. .dockerignore reduces build context and improves security
5. Non-root users improve container security
6. Health checks enable better container monitoring
7. Scratch base images create minimal production images
8. Image optimization is crucial for production deployments

## Next Steps
- Move to Lab 3: Docker Compose and Multi-Container Applications
- Practice with different programming languages
- Learn about image registry management and security