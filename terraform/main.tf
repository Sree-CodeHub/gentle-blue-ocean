locals {
  common_tags = merge(
    {
      ManagedBy = "Terraform"
      Service   = "rds-mysql"
    },
    var.tags
  )

  security_group_ids = var.create_security_group ? concat([aws_security_group.rds_mysql[0].id], var.additional_security_group_ids) : var.additional_security_group_ids
}

resource "aws_security_group" "rds_mysql" {
  count = var.create_security_group ? 1 : 0

  name        = "${var.db_identifier}-sg"
  description = "Security group for ${var.db_identifier} MySQL RDS"
  vpc_id      = var.vpc_id

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.db_identifier}-sg"
  })
}

resource "aws_security_group_rule" "mysql_cidr_ingress" {
  for_each = var.create_security_group ? toset(var.allowed_cidr_blocks) : []

  type              = "ingress"
  description       = "Allow MySQL from ${each.value}"
  from_port         = var.db_port
  to_port           = var.db_port
  protocol          = "tcp"
  cidr_blocks       = [each.value]
  security_group_id = aws_security_group.rds_mysql[0].id
}

resource "aws_security_group_rule" "mysql_security_group_ingress" {
  for_each = var.create_security_group ? toset(var.allowed_source_security_group_ids) : []

  type                     = "ingress"
  description              = "Allow MySQL from source security group ${each.value}"
  from_port                = var.db_port
  to_port                  = var.db_port
  protocol                 = "tcp"
  source_security_group_id = each.value
  security_group_id        = aws_security_group.rds_mysql[0].id
}

resource "aws_db_subnet_group" "mysql" {
  name       = "${var.db_identifier}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(local.common_tags, {
    Name = "${var.db_identifier}-subnet-group"
  })
}

resource "aws_db_instance" "mysql" {
  identifier = var.db_identifier

  engine         = "mysql"
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  storage_encrypted     = var.storage_encrypted

  db_name  = var.db_name
  username = var.db_username
  password = var.manage_master_user_password ? null : var.db_password
  port     = var.db_port

  manage_master_user_password = var.manage_master_user_password

  db_subnet_group_name   = aws_db_subnet_group.mysql.name
  vpc_security_group_ids = local.security_group_ids
  publicly_accessible    = var.publicly_accessible
  multi_az               = var.multi_az

  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window

  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  deletion_protection        = var.deletion_protection
  apply_immediately          = var.apply_immediately
  skip_final_snapshot        = var.skip_final_snapshot
  final_snapshot_identifier  = var.skip_final_snapshot ? null : "${var.db_identifier}-final-snapshot"

  tags = merge(local.common_tags, {
    Name = var.db_identifier
  })
}
