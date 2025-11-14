# 01. Introduction to Docker

## What is Docker?
Docker is a platform for developing, shipping, and running applications in containers. Containers package software with all dependencies, ensuring consistency across environments.

## Why Use Containers?
- **Consistency**: Same environment everywhere
- **Isolation**: Applications run independently
- **Portability**: Run anywhere Docker is installed
- **Efficiency**: Lightweight compared to VMs
- **Scalability**: Easy to scale up/down

## Docker vs Virtual Machines

| Feature | Docker | Virtual Machine |
|---------|--------|-----------------|
| Size | MBs | GBs |
| Startup | Seconds | Minutes |
| Performance | Native | Overhead |
| Isolation | Process-level | Hardware-level |

## Docker Architecture

### Components:
1. **Docker Client**: CLI interface
2. **Docker Daemon**: Background service
3. **Docker Registry**: Image repository
4. **Docker Images**: Application templates
5. **Docker Containers**: Running instances

## Installation

### Linux (Ubuntu/Debian)
```bash
# Update package index
sudo apt-get update

# Install dependencies
sudo apt-get install ca-certificates curl gnupg

# Add Docker's official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Set up repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Verify installation
sudo docker run hello-world
```

### macOS
```bash
# Download Docker Desktop from docker.com
# Install and start Docker Desktop
# Verify installation
docker --version
```

### Windows
```bash
# Download Docker Desktop from docker.com
# Enable WSL 2
# Install and start Docker Desktop
# Verify installation
docker --version
```

## Verify Installation
```bash
# Check Docker version
docker --version

# Check Docker info
docker info

# Run test container
docker run hello-world
```

## Docker Hello World
```bash
# Pull and run hello-world image
docker run hello-world

# What happens:
# 1. Docker client contacts Docker daemon
# 2. Daemon pulls "hello-world" image from Docker Hub
# 3. Daemon creates container from image
# 4. Daemon streams output to client
```

## Key Concepts
- **Image**: Read-only template
- **Container**: Runnable instance of image
- **Dockerfile**: Instructions to build image
- **Registry**: Storage for images
- **Volume**: Persistent data storage
- **Network**: Container communication
