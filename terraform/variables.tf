# Defaults mirror the cluster this project runs on today.

variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name, used for resource names and tags."
  type        = string
  default     = "go-web-app"
}

variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
  default     = "my-eks-cluster"
}

variable "kubernetes_version" {
  description = "Kubernetes version of the EKS control plane."
  type        = string
  default     = "1.34"
}

# ---- Network ----

variable "vpc_cidr" {
  description = "VPC CIDR block."
  type        = string
  default     = "192.168.0.0/16"
}

variable "azs" {
  description = "Availability zones for the subnets."
  type        = list(string)
  default     = ["us-east-1b", "us-east-1f"]
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs, one per availability zone."
  type        = list(string)
  default     = ["192.168.0.0/19", "192.168.32.0/19"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs, one per availability zone."
  type        = list(string)
  default     = ["192.168.64.0/19", "192.168.96.0/19"]
}

# ---- Nodes ----

variable "node_instance_types" {
  description = "EC2 instance types for the worker nodes."
  type        = list(string)
  default     = ["t3.small"]
}

variable "node_min_size" {
  description = "Minimum number of worker nodes."
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of worker nodes."
  type        = number
  default     = 4
}

variable "node_desired_size" {
  description = "Initial number of worker nodes."
  type        = number
  default     = 4
}

variable "node_disk_size" {
  description = "Root volume size of each node, in GiB."
  type        = number
  default     = 80
}

variable "eks_addons" {
  description = "EKS managed add-ons and their versions."
  type = map(object({
    version              = optional(string)
    configuration_values = optional(string)
  }))
  default = {
    "vpc-cni"            = { version = "v1.22.4-eksbuild.8" }
    "kube-proxy"         = { version = "v1.34.6-eksbuild.59" }
    "coredns"            = { version = "v1.12.4-eksbuild.66" }
    "metrics-server"     = { version = "v0.9.0-eksbuild.14" }
    "aws-ebs-csi-driver" = { version = "v1.67.2-eksbuild.1" }
  }
}

# ---- Platform ----

variable "domain" {
  description = "DNS domain the app, Argo CD and Grafana hostnames live under."
  type        = string
  default     = "myexample.sbs"
}

variable "git_repo_url" {
  description = "Git repository Argo CD deploys from."
  type        = string
  default     = "https://github.com/Nitish0223/go-web-app.git"
}

variable "git_revision" {
  description = "Branch Argo CD tracks."
  type        = string
  default     = "main"
}

variable "argocd_admin_github_users" {
  description = "GitHub usernames with admin rights in Argo CD."
  type        = list(string)
  default     = ["Nitish0223"]
}

variable "github_sso_enabled" {
  description = "Enable GitHub login for Argo CD (needs the argocd-github-oauth secret)."
  type        = bool
  default     = true
}

variable "chart_versions" {
  description = "Helm chart versions for the platform components."
  type = object({
    ingress_nginx = string
    cert_manager  = string
    argocd        = string
    argocd_apps   = string
  })
  default = {
    ingress_nginx = "4.15.1"
    cert_manager  = "v1.21.3"
    argocd        = "10.11.6"
    argocd_apps   = "2.0.7"
  }
}

variable "tags" {
  description = "Extra tags added to every AWS resource."
  type        = map(string)
  default     = {}
}
