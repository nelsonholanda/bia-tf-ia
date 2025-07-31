# AWS Backup Module Variables

variable "environment" {
  description = "Environment name (dev/prod)"
  type        = string
}

variable "tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default     = {}
}

variable "backup_kms_key_arn" {
  description = "KMS key ARN for backup encryption in primary region"
  type        = string
}

variable "cross_region_kms_key_arn" {
  description = "KMS key ARN for backup encryption in cross region (sa-east-1)"
  type        = string
}

variable "rds_instance_arns" {
  description = "List of RDS instance ARNs to backup"
  type        = list(string)
  default     = []
}

# Backup Schedule Configuration
variable "backup_schedule" {
  description = "Cron expression for backup schedule"
  type        = string
  default     = "cron(0 3 ? * * *)" # Daily at 3 AM UTC
}

variable "weekly_backup_schedule" {
  description = "Cron expression for weekly backup schedule"
  type        = string
  default     = "cron(0 5 ? * SUN *)" # Weekly on Sunday at 5 AM UTC
}

variable "backup_start_window" {
  description = "The amount of time in minutes before beginning a backup"
  type        = number
  default     = 60
}

variable "backup_completion_window" {
  description = "The amount of time AWS Backup attempts a backup before canceling the job and returning an error"
  type        = number
  default     = 120
}

# Backup Retention Configuration
variable "backup_retention_days" {
  description = "Number of days to retain backups in primary region"
  type        = number
  default     = 30
}

variable "cross_region_retention_days" {
  description = "Number of days to retain backups in cross region"
  type        = number
  default     = 90
}

variable "weekly_retention_days" {
  description = "Number of days to retain weekly backups in primary region"
  type        = number
  default     = 90
}

variable "weekly_cross_region_retention_days" {
  description = "Number of days to retain weekly backups in cross region"
  type        = number
  default     = 365
}

# Cold Storage Configuration
variable "backup_cold_storage_after" {
  description = "Number of days after which to move backups to cold storage"
  type        = number
  default     = 30
}

variable "cross_region_cold_storage_after" {
  description = "Number of days after which to move cross-region backups to cold storage"
  type        = number
  default     = 30
}

variable "weekly_cold_storage_after" {
  description = "Number of days after which to move weekly backups to cold storage"
  type        = number
  default     = 7
}

variable "weekly_cross_region_cold_storage_after" {
  description = "Number of days after which to move weekly cross-region backups to cold storage"
  type        = number
  default     = 30
}

# Monitoring Configuration
variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
}

variable "alarm_sns_topic_arns" {
  description = "List of SNS topic ARNs for backup failure alarms"
  type        = list(string)
  default     = []
}

variable "reports_s3_bucket" {
  description = "S3 bucket name for backup reports"
  type        = string
  default     = ""
}
