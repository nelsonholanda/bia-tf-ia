variable "environment" {
  description = "Environment name"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "env_config" {
  description = "Environment-specific configuration"
  type = object({
    rds_instance_class          = string
    multi_az                    = bool
    backup_retention_period     = number
    enable_performance_insights = optional(bool, false)
    enable_deletion_protection  = optional(bool, false)
  })
}

variable "db_identifier" {
  description = "Database identifier"
  type        = string
  default     = "bia"
}

variable "database_name" {
  description = "Name of the database"
  type        = string
  default     = "bia"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "postgres"
}

variable "postgres_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "15.8" # More stable version
}

variable "allocated_storage" {
  description = "Initial allocated storage in GB"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum allocated storage in GB"
  type        = number
  default     = 100
}

variable "backup_window" {
  description = "Backup window"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Maintenance window"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "security_group_ids" {
  description = "List of security group IDs"
  type        = list(string)
}

variable "subnet_ids" {
  description = "List of subnet IDs for DB subnet group"
  type        = list(string)
}

variable "rds_kms_key_arn" {
  description = "ARN of the KMS key for RDS encryption"
  type        = string
  default     = null
}

variable "secrets_kms_key_arn" {
  description = "ARN of the KMS key for Secrets Manager encryption"
  type        = string
  default     = null
}

variable "rotation_lambda_arn" {
  description = "ARN of the Lambda function for secret rotation"
  type        = string
  default     = null
}
