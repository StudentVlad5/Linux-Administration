output "ecr_repository_url" {
  description = "URL створеного репозиторію ECR"
  value       = aws_ecr_repository.main.repository_url
}

output "ecr_repository_arn" {
  description = "ARN створеного репозиторію ECR"
  value       = aws_ecr_repository.main.arn
}