output "load_balancer_hostname" {
  description = "Hostname of the ingress-nginx load balancer. Point every app's DNS CNAME here."
  value       = try(data.kubernetes_service_v1.ingress_nginx.status[0].load_balancer[0].ingress[0].hostname, null)
}

output "argocd_url" {
  description = "URL of the Argo CD UI."
  value       = "https://${var.argocd_hostname}"
}

output "helm_releases" {
  description = "Helm releases installed by this module and their chart versions."
  value = {
    (helm_release.ingress_nginx.name) = helm_release.ingress_nginx.version
    (helm_release.cert_manager.name)  = helm_release.cert_manager.version
    (helm_release.argocd.name)        = helm_release.argocd.version
    (helm_release.argocd_apps.name)   = helm_release.argocd_apps.version
  }
}
