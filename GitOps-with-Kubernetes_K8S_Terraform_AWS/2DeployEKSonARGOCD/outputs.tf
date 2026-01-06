# Outputs
# Created by: Imran Shaikh

output "argocd_server_url" {
  description = "Command to get ArgoCD server URL"
  value       = "kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
}

output "argocd_admin_password_command" {
  description = "Command to get ArgoCD admin password"
  value       = "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
}

output "argocd_login_info" {
  description = "ArgoCD login information"
  value       = <<-EOT
    Username: admin
    Password: Run the command in 'argocd_admin_password_command' output
    URL: Run the command in 'argocd_server_url' output
  EOT
}
