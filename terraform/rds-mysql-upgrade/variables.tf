variable "aws_region" {
  description = "AWS region containing the target RDS instance"
  type        = string
}

variable "db_instance_identifier" {
  description = "RDS DB instance identifier"
  type        = string
}

variable "source_engine_version" {
  description = "Expected source/current MySQL engine version"
  type        = string
}

variable "target_engine_version" {
  description = "Desired target MySQL engine version"
  type        = string
}

variable "allow_major_version_upgrade" {
  description = "Allow major version upgrade in RDS"
  type        = bool
  default     = true
}

variable "apply_immediately" {
  description = "Apply immediately instead of waiting for maintenance window"
  type        = bool
  default     = false
}
