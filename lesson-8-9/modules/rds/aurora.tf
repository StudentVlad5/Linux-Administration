resource "aws_rds_cluster_parameter_group" "this" {
  count = var.use_aurora ? 1 : 0

  name        = "${local.name_prefix}-aurora-cluster-params"
  family      = var.parameter_family
  description = "Custom Aurora cluster parameter group for ${local.name_prefix}"

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
    Name        = "${local.name_prefix}-aurora-cluster-params"
    Environment = var.environment
  }
}

resource "aws_rds_cluster" "this" {
  count = var.use_aurora ? 1 : 0

  cluster_identifier = "${local.name_prefix}-aurora-cluster"
  engine             = var.engine
  engine_version     = var.engine_version
  database_name      = var.db_name
  master_username    = var.master_username
  master_password    = var.master_password
  port               = local.db_port
  storage_encrypted  = true

  db_subnet_group_name            = aws_db_subnet_group.this.name
  vpc_security_group_ids          = [aws_security_group.this.id]
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.this[0].name

  backup_retention_period   = var.backup_retention_period
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${local.name_prefix}-aurora-final-snapshot"
  deletion_protection       = false

  tags = {
    Name        = "${local.name_prefix}-aurora-cluster"
    Environment = var.environment
    EngineType  = "Aurora"
  }
}

resource "aws_rds_cluster_instance" "this" {
  count = var.use_aurora ? (var.multi_az ? 2 : 1) : 0

  identifier              = "${local.name_prefix}-aurora-node-${count.index + 1}"
  cluster_identifier      = aws_rds_cluster.this[0].id
  instance_class          = var.instance_class
  engine                  = aws_rds_cluster.this[0].engine
  engine_version          = aws_rds_cluster.this[0].engine_version
  db_subnet_group_name    = aws_db_subnet_group.this.name
  db_parameter_group_name = aws_db_parameter_group.this.name
  publicly_accessible     = false

  tags = {
    Name        = "${local.name_prefix}-aurora-node-${count.index + 1}"
    Role        = count.index == 0 ? "writer" : "reader"
    Environment = var.environment
  }
}
