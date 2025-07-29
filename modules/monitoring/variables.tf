variable "environment" {
  description = "Environment name"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "alert_email" {
  description = "Email address for alerts"
  type        = string
  default     = ""
}

variable "monitoring_config" {
  description = "Monitoring configuration"
  type = object({
    cpu_alarm_threshold        = number
    memory_alarm_threshold     = number
    disk_alarm_threshold       = number
    enable_detailed_monitoring = bool
  })
}

variable "env_config" {
  description = "Environment-specific configuration"
  type = object({
    log_retention_days = number
  })
}

variable "alb_arn_suffix" {
  description = "ALB ARN suffix for CloudWatch metrics"
  type        = string
}
