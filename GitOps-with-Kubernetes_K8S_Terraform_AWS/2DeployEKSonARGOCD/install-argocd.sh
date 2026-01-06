#!/bin/bash
# ArgoCD Installation and Mario Game Deployment Script
# Created by: Imran Shaikh

set -e

echo "=========================================="
echo "ArgoCD Installation on EKS"
echo "=========================================="

# Step 1: Create ArgoCD namespace
echo "Creating argocd namespace..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# Step 2: Install ArgoCD
echo "Installing ArgoCD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Step 3: Wait for ArgoCD pods to be ready
echo "Waiting for ArgoCD pods to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s

# Step 4: Get ArgoCD admin password
echo "=========================================="
echo "ArgoCD Admin Password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo ""
echo "=========================================="

# Step 5: Expose ArgoCD server (LoadBalancer)
echo "Exposing ArgoCD server..."
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

# Step 6: Get ArgoCD URL
echo "Waiting for LoadBalancer to be ready..."
sleep 30
ARGOCD_URL=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo "=========================================="
echo "ArgoCD Installation Complete!"
echo "=========================================="
echo "ArgoCD URL: https://$ARGOCD_URL"
echo "Username: admin"
echo "Password: (shown above)"
echo "=========================================="
echo ""
echo "To deploy Mario game:"
echo "kubectl apply -f applications/mario-game.yaml"
echo "=========================================="
