variable "cluster_name" {
  type = string
}

variable "cluster_endpoint" {
  type = string
}

variable "namespace" {
  type    = string
  default = "jenkins"
}

variable "cluster_ca_certificate" {
  type = string
}

variable "jenkins_ecr_role_arn" {
  description = "IAM Role ARN for Jenkins IRSA to push images to ECR"
  type        = string
}

variable "github_username" {
  description = "GitHub username for CI/CD commits"
  type        = string
  default     = "StudentVlad5"
}

variable "github_token" {
  description = "GitHub Personal Access Token for pushing Helm tag updates"
  type        = string
  sensitive   = true
  default     = ""
}

variable "gitops_repo_url" {
  description = "GitHub repository URL containing Jenkinsfile"
  type        = string
  default     = "https://github.com/StudentVlad5/Linux-Administration.git"
}