output "argocd_password_cmd" {
  value = "kubectl -n ${var.namespace} get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\""
}