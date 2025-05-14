output "cert_manager_service" {
  description = "Cert Manager service on EKS"
  value = {
    name      = helm_release.cert_manager.name
    namespace = helm_release.cert_manager.namespace
  }
}
output "argocd_server_service" {
  description = "ArgoCD LoadBalancer service for UI"
  value = {
    name      = helm_release.argocd.name
    namespace = helm_release.argocd.namespace
  }
}