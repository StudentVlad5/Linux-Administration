variable "cluster_name" {
  type = string
}

variable "cluster_endpoint" {
  type = string
}

variable "namespace" {
  type    = string
  default = "argocd"
}

variable "repo_url" {
  type = string
}

variable "target_revision" {
  type    = string
  default = "lesson-8-9"
}

variable "chart_path" {
  type    = string
  default = "lesson-8-9/charts/django-app"
}