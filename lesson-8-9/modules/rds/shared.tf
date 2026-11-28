locals {
  name_prefix = "${var.project_name}-${var.environment}"
  is_mysql    = can(regex("mysql", var.engine))
  db_port     = local.is_mysql ? 3306 : 5432

  pg_parameters = [
    {
      name         = "max_connections"
      value        = var.db_parameters.max_connections
      apply_method = "pending-reboot"
    },
    {
      name         = "log_statement"
      value        = var.db_parameters.log_statement
      apply_method = "immediate"
    },
    {
      name         = "work_mem"
      value        = var.db_parameters.work_mem
      apply_method = "immediate"
    }
  ]

  mysql_parameters = [
    {
      name         = "max_connections"
      value        = var.db_parameters.max_connections
      apply_method = "immediate"
    },
    {
      name         = "general_log"
      value        = var.db_parameters.log_statement == "none" ? "0" : "1"
      apply_method = "immediate"
    },
    {
      name         = "sort_buffer_size"
      value        = tostring(tonumber(var.db_parameters.work_mem) * 1024)
      apply_method = "immediate"
    }
  ]

  active_parameters = local.is_mysql ? local.mysql_parameters : local.pg_parameters
}

resource "aws_db_subnet_group" "this" {
  name        = "${local.name_prefix}-db-subnet-group"
  description = "Database subnet group for ${local.name_prefix}"
  subnet_ids  = var.subnet_ids

  tags = {
    Name        = "${local.name_prefix}-db-subnet-group"
    Environment = var.environment
  }
}

resource "aws_security_group" "this" {
  name        = "${local.name_prefix}-db-sg"
  description = "Allow database traffic for ${local.name_prefix}"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Database access from VPC CIDR and EKS Security Groups"
    from_port       = local.db_port
    to_port         = local.db_port
    protocol        = "tcp"
    cidr_blocks     = var.allowed_cidr_blocks
    security_groups = var.allowed_security_group_ids
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${local.name_prefix}-db-sg"
    Environment = var.environment
  }
}

resource "aws_db_parameter_group" "this" {
  name        = "${local.name_prefix}-db-params"
  family      = var.parameter_family
  description = "Custom DB parameter group for ${local.name_prefix}"

  dynamic "parameter" {
    for_each = local.active_parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "${local.name_prefix}-db-params"
    Environment = var.environment
  }
}
