resource "aws_db_instance" "this" {
  count = var.use_aurora ? 0 : 1

  identifier            = "${local.name_prefix}-rds"
  engine                = var.engine
  engine_version        = var.engine_version
  instance_class        = var.instance_class
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.master_username
  password = var.master_password
  port     = local.db_port

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]
  parameter_group_name   = aws_db_parameter_group.this.name

  multi_az                  = var.multi_az
  publicly_accessible       = false
  backup_retention_period   = var.backup_retention_period
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${local.name_prefix}-rds-final-snapshot"
  deletion_protection       = false

  tags = {
    Name        = "${local.name_prefix}-rds"
    Environment = var.environment
    EngineType  = "RDS"
  }
}
