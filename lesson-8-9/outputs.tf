output "vpc_id" {
  description = "ID створеної VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "ID публічних підмереж"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "ID приватних підмереж"
  value       = module.vpc.private_subnet_ids
}

output "ecr_repository_url" {
  description = "URL репозиторію ECR"
  value       = module.ecr.ecr_repository_url
}

output "eks_cluster_name" {
  description = "Назва створеного EKS кластера"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "Endpoint для підключення до EKS кластера"
  value       = module.eks.cluster_endpoint
}

output "ebs_csi_driver_role_arn" {
  value = module.eks.ebs_csi_driver_role_arn
}

output "jenkins_ecr_role_arn" {
  value = module.eks.jenkins_ecr_role_arn
}
