output "cluster_name" {
  description = "Name of the EKS cluster."
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "URL of the Kubernetes API server."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64-encoded CA certificate of the API server."
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_version" {
  description = "Kubernetes version of the control plane."
  value       = aws_eks_cluster.this.version
}

output "cluster_security_group_id" {
  description = "Security group EKS created for the control plane and nodes."
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "oidc_provider_arn" {
  description = "ARN of the IAM OIDC provider, for further IRSA roles."
  value       = aws_iam_openid_connect_provider.this.arn
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL of the cluster."
  value       = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

output "node_group_name" {
  description = "Name of the managed node group."
  value       = aws_eks_node_group.this.node_group_name
}

output "node_role_arn" {
  description = "IAM role ARN of the worker nodes."
  value       = aws_iam_role.node.arn
}

output "ebs_csi_role_arn" {
  description = "IAM role ARN used by the EBS CSI driver."
  value       = aws_iam_role.ebs_csi.arn
}

output "addons" {
  description = "Installed EKS add-ons and their versions."
  value = merge(
    { for name, addon in aws_eks_addon.before_nodes : name => addon.addon_version },
    { for name, addon in aws_eks_addon.after_nodes : name => addon.addon_version },
  )
}
