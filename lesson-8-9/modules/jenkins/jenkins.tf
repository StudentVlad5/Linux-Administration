resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_secret" "github_credentials" {
  metadata {
    name      = "jenkins-github-secret"
    namespace = kubernetes_namespace.jenkins.metadata[0].name
  }

  data = {
    username = var.github_username
    token    = var.github_token
  }

  type = "Opaque"
}

resource "helm_release" "jenkins" {
  name             = "jenkins"
  repository       = "https://charts.jenkins.io"
  chart            = "jenkins"
  namespace        = kubernetes_namespace.jenkins.metadata[0].name
  create_namespace = false
  timeout          = 600

  values = [
    templatefile("${path.module}/values.yaml", {
      jenkins_ecr_role_arn = var.jenkins_ecr_role_arn
      gitops_repo_url      = var.gitops_repo_url
    })
  ]

  depends_on = [kubernetes_secret.github_credentials]
}