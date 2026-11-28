variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "django-app"
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "use_aurora" {
  description = "Flag to choose DB type: true for Aurora Cluster, false for standard RDS instance"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "ID of the VPC where the database will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of private subnet IDs for DB Subnet Group (minimum 2 across different AZs)"
  type        = list(string)
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access the database"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "allowed_security_group_ids" {
  description = "List of Security Group IDs (e.g., EKS nodes) allowed to connect to the database"
  type        = list(string)
  default     = []
}

variable "engine" {
  description = "Database engine: postgres / mysql (for RDS) or aurora-postgresql / aurora-mysql (for Aurora)"
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  description = "Database engine version (e.g., 15.7 for postgres or 8.0.35 for mysql)"
  type        = string
  default     = "15"
}

variable "parameter_family" {
  description = "AWS DB parameter group family (e.g., postgres15, mysql8.0, aurora-postgresql15, aurora-mysql8.0)"
  type        = string
  default     = "postgres15"
}

variable "instance_class" {
  description = "Database instance class (Aurora requires classes like db.t3.medium, db.r6g.large)"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Initial storage size in GB (used only for standard RDS)"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum storage size in GB for autoscaling (used only for standard RDS)"
  type        = number
  default     = 100
}

variable "db_name" {
  description = "Name of the initial database"
  type        = string
  default     = "djangodb"
}

variable "master_username" {
  description = "Master administrator username for the database"
  type        = string
  default     = "dbadmin"
}

variable "master_password" {
  description = "Master administrator password for the database (minimum 8 characters)"
  type        = string
  sensitive   = true
}

variable "multi_az" {
  description = "Enable Multi-AZ for high availability (standby replica for RDS, reader instance for Aurora)"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Number of days to retain automated backups"
  type        = number
  default     = 1
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on DB deletion (recommended for dev/testing environments)"
  type        = bool
  default     = true
}

variable "db_parameters" {
  description = "Core performance and logging parameters for the DB Parameter Group"
  type = object({
    max_connections = string
    log_statement   = string
    work_mem        = string
  })
  default = {
    max_connections = "100"
    log_statement   = "all"
    work_mem        = "4096"
  }
}
