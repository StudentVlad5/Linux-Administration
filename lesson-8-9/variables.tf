variable "github_token" {
  description = "GitHub Personal Access Token for Jenkins CI/CD (pass via TF_VAR_github_token)"
  type        = string
  sensitive   = true
  default     = ""
}
variable "db_password" {
  description = "Master password for the RDS/Aurora database"
  type        = string
  sensitive   = true
}
