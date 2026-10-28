output "vpc_id" {
  description = "ID of the VPC."
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs."
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs."
  value       = module.vpc.private_subnet_ids
}

output "cluster_name" {
  description = "Name of the EKS cluster."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Kubernetes API server URL."
  value       = module.eks.cluster_endpoint
}

output "configure_kubectl" {
  description = "Command that points kubectl at the cluster."
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.aws_region}"
}

output "eks_addons" {
  description = "Installed EKS add-ons and versions."
  value       = module.eks.addons
}

output "ebs_csi_role_arn" {
  description = "IAM role used by the EBS CSI driver."
  value       = module.eks.ebs_csi_role_arn
}

output "load_balancer_hostname" {
  description = "Hostname of the ingress-nginx load balancer."
  value       = module.platform.load_balancer_hostname
}

output "dns_records" {
  description = "CNAME records to create at the DNS provider (Hostinger)."
  value       = { for name, host in local.hostnames : host => module.platform.load_balancer_hostname }
}

output "argocd_url" {
  description = "URL of the Argo CD UI."
  value       = module.platform.argocd_url
}

output "manual_secrets" {
  description = "Secrets kept out of Terraform state and git; create them with kubectl."
  value = [
    "argocd/argocd-github-oauth (clientID, clientSecret; label app.kubernetes.io/part-of=argocd)",
    "monitoring/grafana-admin (admin-user, admin-password)",
    "monitoring/alertmanager-gmail (app-password)",
  ]
}
