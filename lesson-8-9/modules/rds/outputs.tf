output "db_endpoint" {
  description = "Primary connection endpoint (Writer endpoint for Aurora or address for RDS)"
  value       = var.use_aurora ? aws_rds_cluster.this[0].endpoint : aws_db_instance.this[0].address
}

output "db_reader_endpoint" {
  description = "Reader endpoint (Aurora only; returns primary address for standard RDS)"
  value       = var.use_aurora ? aws_rds_cluster.this[0].reader_endpoint : aws_db_instance.this[0].address
}

output "db_port" {
  description = "Database connection port"
  value       = local.db_port
}

output "db_name" {
  description = "Name of the created database"
  value       = var.db_name
}

output "db_security_group_id" {
  description = "ID of the created database Security Group"
  value       = aws_security_group.this.id
}

output "db_subnet_group_name" {
  description = "Name of the created DB Subnet Group"
  value       = aws_db_subnet_group.this.name
}

output "db_type" {
  description = "Deployed database architecture type (Aurora Cluster or RDS Instance)"
  value       = var.use_aurora ? "Aurora Cluster" : "RDS Instance"
}
