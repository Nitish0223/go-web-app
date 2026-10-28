locals {
  tags = merge({
    Project   = var.project
    ManagedBy = "terraform"
  }, var.tags)

  hostnames = {
    app     = "app.${var.domain}"
    argocd  = "argocd.${var.domain}"
    grafana = "grafana.${var.domain}"
  }
}

module "vpc" {
  source = "./modules/vpc"

  name                 = var.project
  cluster_name         = var.cluster_name
  cidr                 = var.vpc_cidr
  azs                  = var.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

module "eks" {
  source = "./modules/eks"

  cluster_name       = var.cluster_name
  kubernetes_version = var.kubernetes_version
  cluster_subnet_ids = concat(module.vpc.public_subnet_ids, module.vpc.private_subnet_ids)

  # Nodes sit in the public subnets, as in the original eksctl cluster.
  # Moving them to module.vpc.private_subnet_ids is the more locked-down option.
  node_subnet_ids     = module.vpc.public_subnet_ids
  node_instance_types = var.node_instance_types
  node_min_size       = var.node_min_size
  node_max_size       = var.node_max_size
  node_desired_size   = var.node_desired_size
  node_disk_size      = var.node_disk_size

  addons = var.eks_addons
}

module "platform" {
  source = "./modules/platform"

  ingress_nginx_chart_version = var.chart_versions.ingress_nginx
  cert_manager_chart_version  = var.chart_versions.cert_manager
  argocd_chart_version        = var.chart_versions.argocd
  argocd_apps_chart_version   = var.chart_versions.argocd_apps

  argocd_hostname           = local.hostnames.argocd
  github_sso_enabled        = var.github_sso_enabled
  argocd_admin_github_users = var.argocd_admin_github_users

  git_repo_url = var.git_repo_url
  git_revision = var.git_revision

  # Argo CD then deploys the app (helm/go-web-app-chart) and the monitoring stack from these files.
  bootstrap_applications = {
    apps = {
      path    = "argocd"
      include = "go-web-app-application.yaml"
    }
    monitoring = {
      path = "monitoring"
    }
  }

  # Helm needs the nodes and the EBS CSI driver before installing workloads.
  depends_on = [module.eks]
}
