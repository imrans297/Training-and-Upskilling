# Services

## What is a Service?
Abstraction that exposes pods to network traffic with stable IP and DNS.

## Service Types

### 1. ClusterIP (Default)
- Internal cluster access only
- Virtual IP within cluster
- Use: Internal microservices

### 2. NodePort
- Exposes on each node's IP at static port
- Range: 30000-32767
- Use: Development, testing

### 3. LoadBalancer
- External load balancer (cloud provider)
- Assigns external IP
- Use: Production external access

### 4. ExternalName
- Maps to external DNS name
- No proxying
- Use: External service integration

## Service Discovery
- DNS-based (recommended)
- Environment variables

## Endpoints
- List of pod IPs matching selector
- Automatically updated
