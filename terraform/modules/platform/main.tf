# Cluster platform installed with Helm: ingress, TLS certificates and Argo CD.
# Everything else (the app, Prometheus/Grafana/Alertmanager) is deployed by Argo CD from git.

resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = var.ingress_nginx_chart_version
  namespace        = "ingress-nginx"
  create_namespace = true

  # Creates the AWS load balancer that every *.myexample.sbs hostname points at.
  values = [yamlencode({
    controller = {
      service = {
        type = "LoadBalancer"
      }
    }
  })]
}

resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = var.cert_manager_chart_version
  namespace        = "cert-manager"
  create_namespace = true

  values = [yamlencode({
    crds = {
      enabled = true
    }
  })]
}

locals {
  dex_config = yamlencode({
    connectors = [{
      type = "github"
      id   = "github"
      name = "GitHub"
      config = {
        clientID     = "$argocd-github-oauth:clientID"
        clientSecret = "$argocd-github-oauth:clientSecret"
      }
    }]
  })
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_chart_version
  namespace        = "argocd"
  create_namespace = true

  values = [yamlencode({
    global = {
      domain = var.argocd_hostname
    }
    configs = {
      # TLS ends at ingress-nginx, so argocd-server serves plain HTTP inside the cluster.
      params = {
        "server.insecure" = true
      }
      cm = merge(
        { url = "https://${var.argocd_hostname}" },
        var.github_sso_enabled ? { "dex.config" = local.dex_config } : {},
      )
      rbac = {
        # Dex puts the GitHub username in preferred_username.
        scopes       = "[groups, email, preferred_username]"
        "policy.csv" = join("\n", [for user in var.argocd_admin_github_users : "g, ${user}, role:admin"])
      }
    }
    dex = {
      enabled = var.github_sso_enabled
    }
    server = {
      ingress = {
        enabled          = true
        ingressClassName = "nginx"
        annotations = {
          "cert-manager.io/cluster-issuer"               = var.cluster_issuer
          "nginx.ingress.kubernetes.io/backend-protocol" = "HTTP"
        }
        # The chart stores the certificate in argocd-server-tls, which Argo CD also loads as its own.
        # Dex login verification relies on that (see argocd/argocd-server-ingress.yaml).
        tls = true
      }
    }
  })]

  depends_on = [helm_release.ingress_nginx, helm_release.cert_manager]
}

# App-of-apps: one Argo CD Application per folder of Application manifests in git.
resource "helm_release" "argocd_apps" {
  name       = "argocd-apps"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  version    = var.argocd_apps_chart_version
  namespace  = "argocd"

  values = [yamlencode({
    applications = {
      for name, app in var.bootstrap_applications : name => {
        namespace = "argocd"
        project   = "default"
        source = {
          repoURL        = var.git_repo_url
          targetRevision = var.git_revision
          path           = app.path
          directory = {
            include = app.include
          }
        }
        destination = {
          server    = "https://kubernetes.default.svc"
          namespace = "argocd"
        }
        syncPolicy = {
          automated = {
            prune    = true
            selfHeal = true
          }
          syncOptions = ["ServerSideApply=true"]
        }
      }
    }
  })]

  depends_on = [helm_release.argocd]
}

# The load balancer hostname that DNS records must point at.
data "kubernetes_service_v1" "ingress_nginx" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = helm_release.ingress_nginx.namespace
  }
}
