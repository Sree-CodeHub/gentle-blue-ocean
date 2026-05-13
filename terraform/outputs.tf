output "db_instance_identifier" {
  description = "RDS instance identifier."
  value       = aws_db_instance.mysql.id
}

output "db_instance_address" {
  description = "RDS instance DNS address."
  value       = aws_db_instance.mysql.address
}

output "db_instance_endpoint" {
  description = "RDS instance endpoint."
  value       = aws_db_instance.mysql.endpoint
}

output "db_instance_port" {
  description = "RDS instance port."
  value       = aws_db_instance.mysql.port
}

output "db_name" {
  description = "Initial database name."
  value       = aws_db_instance.mysql.db_name
}

output "db_subnet_group_name" {
  description = "RDS subnet group name."
  value       = aws_db_subnet_group.mysql.name
}

output "db_security_group_ids" {
  description = "Security group IDs attached to the RDS instance."
  value       = local.security_group_ids
}

