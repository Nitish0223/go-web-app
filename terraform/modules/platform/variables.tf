variable "ingress_nginx_chart_version" {
  description = "Version of the ingress-nginx Helm chart."
  type        = string
}

variable "cert_manager_chart_version" {
  description = "Version of the cert-manager Helm chart."
  type        = string
}

variable "argocd_chart_version" {
  description = "Version of the argo-cd Helm chart."
  type        = string
}

variable "argocd_apps_chart_version" {
  description = "Version of the argocd-apps Helm chart used to create the bootstrap Applications."
  type        = string
}

variable "argocd_hostname" {
  description = "Public hostname of the Argo CD UI, e.g. argocd.example.com."
  type        = string
}

variable "cluster_issuer" {
  description = "cert-manager ClusterIssuer used for ingress certificates (created by the app's Helm chart)."
  type        = string
  default     = "letsencrypt-prod"
}

variable "github_sso_enabled" {
  description = "Enable \"Log in via GitHub\" in Argo CD. Requires Secret argocd/argocd-github-oauth (keys clientID, clientSecret, label app.kubernetes.io/part-of=argocd)."
  type        = bool
  default     = true
}

variable "argocd_admin_github_users" {
  description = "GitHub usernames granted role:admin in Argo CD. Other GitHub users get no permissions."
  type        = list(string)
  default     = []
}

variable "git_repo_url" {
  description = "Git repository Argo CD deploys from."
  type        = string
}

variable "git_revision" {
  description = "Branch, tag or commit Argo CD tracks."
  type        = string
  default     = "main"
}

variable "bootstrap_applications" {
  description = "Argo CD Applications created at install time. Each points at a folder of Application manifests in the repo (app-of-apps)."
  type = map(object({
    path    = string
    include = optional(string, "*.yaml")
  }))
}
