variable "aws_region" {
  description = "AWS region where the RDS instance will be created."
  type        = string
  default     = "eu-west-2"
}

variable "resource_type" {
  description = "Type of AWS data service to manage."
  type        = string
  default     = "rds-mysql"

  validation {
    condition     = contains(["rds-mysql", "aurora-mysql", "elasticache-redis", "elasticache-memcached"], var.resource_type)
    error_message = "resource_type must be one of: rds-mysql, aurora-mysql, elasticache-redis, elasticache-memcached."
  }
}

variable "resource_identifier" {
  description = "Identifier for the AWS data service. Defaults to db_identifier for backward compatibility."
  type        = string
  default     = null
}

variable "db_identifier" {
  description = "Unique identifier for the RDS instance."
  type        = string
  default     = "jenkins-rds-mysql"
}

variable "db_name" {
  description = "Initial MySQL database name."
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Master username for the MySQL instance."
  type        = string
  default     = "adminuser"
}

variable "db_password" {
  description = "Optional master password for the MySQL instance. Required only when manage_master_user_password is false."
  type        = string
  default     = null
  sensitive   = true
}

variable "manage_master_user_password" {
  description = "Whether AWS Secrets Manager should manage the RDS master password."
  type        = bool
  default     = true
}

variable "db_port" {
  description = "MySQL listener port."
  type        = number
  default     = 3306
}

variable "engine_version" {
  description = "Engine version for the selected resource type."
  type        = string
  default     = "8.0"
}

variable "instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Initial allocated storage in GB."
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum storage in GB for autoscaling."
  type        = number
  default     = 100
}

variable "storage_type" {
  description = "RDS storage type."
  type        = string
  default     = "gp3"
}

variable "aurora_engine_mode" {
  description = "Aurora engine mode."
  type        = string
  default     = "provisioned"
}

variable "aurora_instance_count" {
  description = "Number of Aurora cluster instances."
  type        = number
  default     = 1
}

variable "aurora_allocated_storage" {
  description = "Optional allocated storage for Aurora cluster types that support it."
  type        = number
  default     = null
}

variable "aurora_storage_type" {
  description = "Optional Aurora storage type, such as aurora or aurora-iopt1."
  type        = string
  default     = ""
}

variable "cache_engine" {
  description = "ElastiCache engine for elasticache-redis resource type, such as redis or valkey."
  type        = string
  default     = "redis"
}

variable "cache_node_type" {
  description = "ElastiCache node type."
  type        = string
  default     = "cache.t3.micro"
}

variable "cache_num_nodes" {
  description = "Number of ElastiCache nodes."
  type        = number
  default     = 1
}

variable "cache_port" {
  description = "Optional ElastiCache port. Defaults to 6379 for Redis/Valkey and 11211 for Memcached."
  type        = number
  default     = null
}

variable "cache_parameter_group_name" {
  description = "Optional ElastiCache parameter group name."
  type        = string
  default     = ""
}

variable "cache_automatic_failover_enabled" {
  description = "Whether automatic failover is enabled for Redis/Valkey replication groups with more than one node."
  type        = bool
  default     = false
}

variable "cache_multi_az_enabled" {
  description = "Whether Multi-AZ is enabled for Redis/Valkey replication groups with more than one node."
  type        = bool
  default     = false
}

variable "cache_at_rest_encryption_enabled" {
  description = "Whether ElastiCache at-rest encryption is enabled."
  type        = bool
  default     = true
}

variable "cache_transit_encryption_enabled" {
  description = "Whether ElastiCache in-transit encryption is enabled."
  type        = bool
  default     = false
}

variable "cache_snapshot_retention_limit" {
  description = "Number of days to retain ElastiCache Redis/Valkey snapshots."
  type        = number
  default     = 0
}

variable "storage_encrypted" {
  description = "Whether storage encryption is enabled."
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "VPC ID for the RDS security group."
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the RDS subnet group."
  type        = list(string)
}

variable "create_security_group" {
  description = "Whether Terraform should create a security group for the RDS instance."
  type        = bool
  default     = true
}

variable "additional_security_group_ids" {
  description = "Existing security group IDs to attach to the RDS instance."
  type        = list(string)
  default     = []
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to connect to MySQL."
  type        = list(string)
  default     = []
}

variable "allowed_source_security_group_ids" {
  description = "Source security group IDs allowed to connect to MySQL."
  type        = list(string)
  default     = []
}

variable "publicly_accessible" {
  description = "Whether the RDS instance receives a public IP."
  type        = bool
  default     = false
}

variable "multi_az" {
  description = "Whether to deploy the RDS instance as Multi-AZ."
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Backup retention period in days."
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "Preferred backup window."
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Preferred maintenance window."
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "auto_minor_version_upgrade" {
  description = "Whether minor engine upgrades are applied automatically."
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Whether deletion protection is enabled."
  type        = bool
  default     = false
}

variable "apply_immediately" {
  description = "Whether changes are applied immediately instead of during the maintenance window."
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Whether to skip the final DB snapshot on destroy."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags to apply to created resources."
  type        = map(string)
  default     = {}
}
