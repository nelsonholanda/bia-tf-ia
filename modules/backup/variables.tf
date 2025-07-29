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
    backup_retention_days      = number
    enable_cross_region_backup = optional(bool, false)
  })
}

variable "rds_instance_arn" {
  description = "ARN of the RDS instance to backup"
  type        = string
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for backup notifications"
  type        = string
}
