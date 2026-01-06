# ArgoCD Installation Resources
# Created by: Imran Shaikh

# Configure kubectl
resource "null_resource" "configure_kubectl" {
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --region ${var.aws_region} --name ${var.cluster_name}"
  }

  depends_on = [data.aws_eks_cluster.cluster]
}

# Install ArgoCD
resource "null_resource" "install_argocd" {
  provisioner "local-exec" {
    command = <<-EOT
      # Create argocd namespace
      kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
      
      # Install ArgoCD
      kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
      
      # Wait for ArgoCD to be ready
      kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
      
      echo "ArgoCD installed successfully!"
    EOT
  }

  depends_on = [null_resource.configure_kubectl]
}

# Patch ArgoCD service to LoadBalancer
resource "null_resource" "patch_argocd_service" {
  provisioner "local-exec" {
    command = <<-EOT
      kubectl apply -f argocd-service-patch.yaml
      echo "ArgoCD service patched to LoadBalancer"
    EOT
  }

  depends_on = [null_resource.install_argocd]
}

# Get ArgoCD admin password
resource "null_resource" "get_argocd_password" {
  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for ArgoCD secret..."
      sleep 30
      echo "=========================================="
      echo "ArgoCD Admin Password:"
      kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
      echo ""
      echo "=========================================="
    EOT
  }

  depends_on = [null_resource.install_argocd]
}

# Deploy Mario Game Application
resource "null_resource" "deploy_mario_game" {
  provisioner "local-exec" {
    command = "kubectl apply -f applications/mario-game.yaml"
  }

  depends_on = [null_resource.install_argocd]
}
