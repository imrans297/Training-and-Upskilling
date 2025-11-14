# Deployments

## What is a Deployment?
Higher-level abstraction that manages ReplicaSets and provides declarative updates.

## Features
- Rolling updates
- Rollback capability
- Scaling
- Pause/Resume
- Version history

## Deployment Strategies
1. **Recreate** - Terminate all, then create new
2. **RollingUpdate** - Gradual replacement (default)
3. **Blue/Green** - Two identical environments
4. **Canary** - Gradual traffic shift

## Update Process
1. Update deployment spec
2. New ReplicaSet created
3. Old pods terminated gradually
4. New pods created gradually

## Use Cases
- Stateless applications
- Web applications
- Microservices
- API servers
