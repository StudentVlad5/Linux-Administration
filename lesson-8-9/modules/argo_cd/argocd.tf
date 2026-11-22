resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = var.namespace
  create_namespace = true
  timeout          = 600

  values = [
    file("${path.module}/values.yaml")
  ]
}

resource "helm_release" "argocd_apps" {
  name       = "argocd-apps"
  chart      = "${path.module}/charts"
  namespace  = var.namespace
  depends_on = [helm_release.argocd]

  set {
    name  = "repoURL"
    value = var.repo_url
  }

  set {
    name  = "targetRevision"
    value = var.target_revision
  }

  set {
    name  = "path"
    value = var.chart_path
  }
}