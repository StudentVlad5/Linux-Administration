variable "ecr_name" {
  description = "Ім'я репозиторію ECR"
  type        = string
  default     = "django-app"
}

variable "scan_on_push" {
  description = "Увімкнути автоматичне сканування образів при push"
  type        = bool
  default     = true
}