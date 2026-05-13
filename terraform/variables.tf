variable "aws_region" {
  description = "AWS region where the RDS instance will be created."
  type        = string
  default     = "us-east-1"
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
  description = "MySQL engine version."
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
