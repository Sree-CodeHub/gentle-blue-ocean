output "db_instance_identifier" {
  description = "RDS instance identifier."
  value       = try(aws_db_instance.mysql[0].id, null)
}

output "db_instance_address" {
  description = "RDS instance DNS address."
  value       = try(aws_db_instance.mysql[0].address, null)
}

output "db_instance_endpoint" {
  description = "RDS instance endpoint."
  value       = try(aws_db_instance.mysql[0].endpoint, null)
}

output "db_instance_port" {
  description = "RDS instance port."
  value       = try(aws_db_instance.mysql[0].port, null)
}

output "db_name" {
  description = "Initial database name."
  value       = try(coalesce(try(aws_db_instance.mysql[0].db_name, null), try(aws_rds_cluster.aurora_mysql[0].database_name, null)), null)
}

output "db_subnet_group_name" {
  description = "RDS subnet group name."
  value       = try(aws_db_subnet_group.mysql[0].name, null)
}

output "db_security_group_ids" {
  description = "Security group IDs attached to the RDS instance."
  value       = local.security_group_ids
}

output "db_master_user_secret_arn" {
  description = "AWS Secrets Manager secret ARN for the managed master user password, when enabled."
  value       = try(coalesce(try(aws_db_instance.mysql[0].master_user_secret[0].secret_arn, null), try(aws_rds_cluster.aurora_mysql[0].master_user_secret[0].secret_arn, null)), null)
}

output "resource_type" {
  description = "Selected AWS data service type."
  value       = var.resource_type
}

output "resource_identifier" {
  description = "Selected AWS data service identifier."
  value       = local.resource_identifier
}

output "service_endpoint" {
  description = "Primary endpoint for the selected data service."
  value = try(coalesce(
    try(aws_db_instance.mysql[0].endpoint, null),
    try(aws_rds_cluster.aurora_mysql[0].endpoint, null),
    try(aws_elasticache_replication_group.redis[0].primary_endpoint_address, null),
    try(aws_elasticache_cluster.memcached[0].configuration_endpoint, null)
  ), null)
}

output "aurora_cluster_identifier" {
  description = "Aurora cluster identifier."
  value       = try(aws_rds_cluster.aurora_mysql[0].id, null)
}

output "aurora_writer_endpoint" {
  description = "Aurora writer endpoint."
  value       = try(aws_rds_cluster.aurora_mysql[0].endpoint, null)
}

output "aurora_reader_endpoint" {
  description = "Aurora reader endpoint."
  value       = try(aws_rds_cluster.aurora_mysql[0].reader_endpoint, null)
}

output "elasticache_replication_group_id" {
  description = "ElastiCache Redis/Valkey replication group ID."
  value       = try(aws_elasticache_replication_group.redis[0].id, null)
}

output "elasticache_cluster_id" {
  description = "ElastiCache Memcached cluster ID."
  value       = try(aws_elasticache_cluster.memcached[0].id, null)
}
