output "jenkins_namespace" {
  value = helm_release.jenkins.namespace
}

output "jenkins_admin_password_cmd" {
  value = "kubectl exec --namespace ${var.namespace} -it svc/jenkins -c jenkins -- /bin/cat /run/secrets/additional/chart-admin-password"
}