variable "github_token" {
  description = "GitHub Personal Access Token for Jenkins CI/CD (pass via TF_VAR_github_token)"
  type        = string
  sensitive   = true
  default     = ""
}