locals {
  resource_identifier = coalesce(var.resource_identifier, var.db_identifier)
  is_rds_mysql        = var.resource_type == "rds-mysql"
  is_aurora_mysql     = var.resource_type == "aurora-mysql"
  is_cache_redis      = var.resource_type == "elasticache-redis"
  is_cache_memcached  = var.resource_type == "elasticache-memcached"
  uses_rds            = local.is_rds_mysql || local.is_aurora_mysql
  uses_elasticache    = local.is_cache_redis || local.is_cache_memcached
  cache_engine        = local.is_cache_memcached ? "memcached" : var.cache_engine
  service_port        = var.cache_port != null && local.uses_elasticache ? var.cache_port : local.is_cache_memcached ? 11211 : local.uses_elasticache ? 6379 : var.db_port

  common_tags = merge(
    {
      ManagedBy = "Terraform"
      Service   = var.resource_type
    },
    var.tags
  )

  security_group_ids = var.create_security_group ? concat([aws_security_group.rds_mysql[0].id], var.additional_security_group_ids) : var.additional_security_group_ids
}

resource "aws_security_group" "rds_mysql" {
  count = var.create_security_group ? 1 : 0

  name        = "${local.resource_identifier}-sg"
  description = "Security group for ${local.resource_identifier}"
  vpc_id      = var.vpc_id

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.resource_identifier}-sg"
  })
}

resource "aws_security_group_rule" "service_cidr_ingress" {
  for_each = var.create_security_group ? toset(var.allowed_cidr_blocks) : []

  type              = "ingress"
  description       = "Allow ${var.resource_type} from ${each.value}"
  from_port         = local.service_port
  to_port           = local.service_port
  protocol          = "tcp"
  cidr_blocks       = [each.value]
  security_group_id = aws_security_group.rds_mysql[0].id
}

resource "aws_security_group_rule" "service_security_group_ingress" {
  for_each = var.create_security_group ? toset(var.allowed_source_security_group_ids) : []

  type                     = "ingress"
  description              = "Allow ${var.resource_type} from source security group ${each.value}"
  from_port                = local.service_port
  to_port                  = local.service_port
  protocol                 = "tcp"
  source_security_group_id = each.value
  security_group_id        = aws_security_group.rds_mysql[0].id
}

resource "aws_db_subnet_group" "mysql" {
  count = local.uses_rds ? 1 : 0

  name       = "${local.resource_identifier}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(local.common_tags, {
    Name = "${local.resource_identifier}-subnet-group"
  })
}

resource "aws_db_instance" "mysql" {
  count = local.is_rds_mysql ? 1 : 0

  identifier = local.resource_identifier

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

  db_subnet_group_name   = aws_db_subnet_group.mysql[0].name
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
  final_snapshot_identifier  = var.skip_final_snapshot ? null : "${local.resource_identifier}-final-snapshot"

  tags = merge(local.common_tags, {
    Name = local.resource_identifier
  })
}

resource "aws_rds_cluster" "aurora_mysql" {
  count = local.is_aurora_mysql ? 1 : 0

  cluster_identifier = local.resource_identifier

  engine         = "aurora-mysql"
  engine_version = var.engine_version
  engine_mode    = var.aurora_engine_mode

  database_name   = var.db_name
  master_username = var.db_username
  master_password = var.manage_master_user_password ? null : var.db_password
  port            = var.db_port

  manage_master_user_password = var.manage_master_user_password

  db_subnet_group_name   = aws_db_subnet_group.mysql[0].name
  vpc_security_group_ids = local.security_group_ids

  allocated_storage = var.aurora_allocated_storage
  storage_encrypted = var.storage_encrypted
  storage_type      = var.aurora_storage_type != "" ? var.aurora_storage_type : null

  backup_retention_period = var.backup_retention_period
  preferred_backup_window = var.backup_window

  deletion_protection       = var.deletion_protection
  apply_immediately         = var.apply_immediately
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${local.resource_identifier}-final-snapshot"

  tags = merge(local.common_tags, {
    Name = local.resource_identifier
  })
}

resource "aws_rds_cluster_instance" "aurora_mysql" {
  count = local.is_aurora_mysql ? var.aurora_instance_count : 0

  identifier         = "${local.resource_identifier}-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.aurora_mysql[0].id

  engine         = aws_rds_cluster.aurora_mysql[0].engine
  engine_version = aws_rds_cluster.aurora_mysql[0].engine_version
  instance_class = var.instance_class

  db_subnet_group_name         = aws_db_subnet_group.mysql[0].name
  publicly_accessible          = var.publicly_accessible
  auto_minor_version_upgrade   = var.auto_minor_version_upgrade
  apply_immediately            = var.apply_immediately
  preferred_maintenance_window = var.maintenance_window

  tags = merge(local.common_tags, {
    Name = "${local.resource_identifier}-${count.index + 1}"
  })
}

resource "aws_elasticache_subnet_group" "cache" {
  count = local.uses_elasticache ? 1 : 0

  name       = "${local.resource_identifier}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(local.common_tags, {
    Name = "${local.resource_identifier}-subnet-group"
  })
}

resource "aws_elasticache_replication_group" "redis" {
  count = local.is_cache_redis ? 1 : 0

  replication_group_id = local.resource_identifier
  description          = "ElastiCache ${local.cache_engine} replication group for ${local.resource_identifier}"

  engine             = local.cache_engine
  engine_version     = var.engine_version
  node_type          = var.cache_node_type
  num_cache_clusters = var.cache_num_nodes

  port               = local.service_port
  subnet_group_name  = aws_elasticache_subnet_group.cache[0].name
  security_group_ids = local.security_group_ids

  parameter_group_name       = var.cache_parameter_group_name != "" ? var.cache_parameter_group_name : null
  automatic_failover_enabled = var.cache_num_nodes > 1 ? var.cache_automatic_failover_enabled : false
  multi_az_enabled           = var.cache_num_nodes > 1 ? var.cache_multi_az_enabled : false
  at_rest_encryption_enabled = var.cache_at_rest_encryption_enabled
  transit_encryption_enabled = var.cache_transit_encryption_enabled
  apply_immediately          = var.apply_immediately
  maintenance_window         = var.maintenance_window
  snapshot_retention_limit   = var.cache_snapshot_retention_limit

  tags = merge(local.common_tags, {
    Name = local.resource_identifier
  })
}

resource "aws_elasticache_cluster" "memcached" {
  count = local.is_cache_memcached ? 1 : 0

  cluster_id      = local.resource_identifier
  engine          = local.cache_engine
  engine_version  = var.engine_version
  node_type       = var.cache_node_type
  num_cache_nodes = var.cache_num_nodes

  port               = local.service_port
  subnet_group_name  = aws_elasticache_subnet_group.cache[0].name
  security_group_ids = local.security_group_ids

  az_mode                    = var.cache_num_nodes > 1 ? "cross-az" : "single-az"
  parameter_group_name       = var.cache_parameter_group_name != "" ? var.cache_parameter_group_name : null
  apply_immediately          = var.apply_immediately
  maintenance_window         = var.maintenance_window
  transit_encryption_enabled = var.cache_transit_encryption_enabled

  tags = merge(local.common_tags, {
    Name = local.resource_identifier
  })
}
