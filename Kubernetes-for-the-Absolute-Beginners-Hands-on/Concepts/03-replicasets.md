# ReplicaSets

## What is a ReplicaSet?
Ensures specified number of pod replicas are running at any time.

## Purpose
- High availability
- Load balancing
- Scaling
- Self-healing

## Key Components
- **Replicas** - Desired number of pods
- **Selector** - Identifies pods to manage
- **Template** - Pod template for creating new pods

## ReplicaSet vs ReplicationController
- ReplicaSet - Newer, supports set-based selectors
- ReplicationController - Older, equality-based selectors

## When to Use
- Usually managed by Deployments
- Direct use for specific scenarios
- Stateless applications
