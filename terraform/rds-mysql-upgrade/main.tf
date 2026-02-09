data "aws_db_instance" "current" {
  db_instance_identifier = var.db_instance_identifier
}

resource "aws_db_instance" "mysql" {
  identifier                  = var.db_instance_identifier
  engine                      = data.aws_db_instance.current.engine
  instance_class              = data.aws_db_instance.current.instance_class
  allocated_storage           = data.aws_db_instance.current.allocated_storage
  storage_type                = data.aws_db_instance.current.storage_type
  db_subnet_group_name        = data.aws_db_instance.current.db_subnet_group
  vpc_security_group_ids      = data.aws_db_instance.current.vpc_security_groups[*].vpc_security_group_id
  backup_retention_period     = data.aws_db_instance.current.backup_retention_period
  backup_window               = data.aws_db_instance.current.backup_window
  maintenance_window          = data.aws_db_instance.current.maintenance_window
  multi_az                    = data.aws_db_instance.current.multi_az
  publicly_accessible         = data.aws_db_instance.current.publicly_accessible
  deletion_protection         = data.aws_db_instance.current.deletion_protection
  auto_minor_version_upgrade  = data.aws_db_instance.current.auto_minor_version_upgrade
  parameter_group_name        = data.aws_db_instance.current.parameter_group_name
  option_group_name           = data.aws_db_instance.current.option_group_name
  copy_tags_to_snapshot       = data.aws_db_instance.current.copy_tags_to_snapshot
  ca_cert_identifier          = data.aws_db_instance.current.ca_cert_identifier
  iam_database_authentication_enabled = data.aws_db_instance.current.iam_database_authentication_enabled

  engine_version              = var.target_engine_version
  allow_major_version_upgrade = var.allow_major_version_upgrade
  apply_immediately           = var.apply_immediately

  lifecycle {
    prevent_destroy = true

    precondition {
      condition     = data.aws_db_instance.current.engine_version == var.source_engine_version
      error_message = "Current engine version does not match source_engine_version. Verify SOURCE_ENGINE_VERSION before upgrade."
    }

    precondition {
      condition     = can(regex("^8\\.", var.source_engine_version)) && can(regex("^8\\.", var.target_engine_version))
      error_message = "This module is designed for MySQL 8.x to 8.x upgrades."
    }
  }
}

output "db_instance_status" {
  value = {
    identifier     = aws_db_instance.mysql.identifier
    from_version   = var.source_engine_version
    to_version     = aws_db_instance.mysql.engine_version
    apply_now      = var.apply_immediately
    major_upgrade  = var.allow_major_version_upgrade
  }
}
