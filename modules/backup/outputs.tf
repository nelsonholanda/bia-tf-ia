# AWS Backup Module Outputs

output "backup_vault_name" {
  description = "Name of the primary backup vault"
  value       = var.environment == "prod" ? aws_backup_vault.main[0].name : null
}

output "backup_vault_arn" {
  description = "ARN of the primary backup vault"
  value       = var.environment == "prod" ? aws_backup_vault.main[0].arn : null
}

output "cross_region_backup_vault_name" {
  description = "Name of the cross-region backup vault"
  value       = var.environment == "prod" ? aws_backup_vault.cross_region[0].name : null
}

output "cross_region_backup_vault_arn" {
  description = "ARN of the cross-region backup vault"
  value       = var.environment == "prod" ? aws_backup_vault.cross_region[0].arn : null
}

output "backup_plan_id" {
  description = "ID of the backup plan"
  value       = var.environment == "prod" ? aws_backup_plan.daily[0].id : null
}

output "backup_plan_arn" {
  description = "ARN of the backup plan"
  value       = var.environment == "prod" ? aws_backup_plan.daily[0].arn : null
}

output "backup_role_arn" {
  description = "ARN of the backup IAM role"
  value       = var.environment == "prod" ? aws_iam_role.backup[0].arn : null
}

output "backup_selection_id" {
  description = "ID of the backup selection"
  value       = var.environment == "prod" ? aws_backup_selection.rds[0].id : null
}

output "backup_log_group_name" {
  description = "Name of the backup CloudWatch log group"
  value       = var.environment == "prod" ? aws_cloudwatch_log_group.backup_events[0].name : null
}

output "backup_log_group_arn" {
  description = "ARN of the backup CloudWatch log group"
  value       = var.environment == "prod" ? aws_cloudwatch_log_group.backup_events[0].arn : null
}

output "backup_alarm_name" {
  description = "Name of the backup failure alarm"
  value       = var.environment == "prod" ? aws_cloudwatch_metric_alarm.backup_failures[0].alarm_name : null
}

output "backup_report_plan_name" {
  description = "Name of the backup report plan"
  value       = var.environment == "prod" ? aws_backup_report_plan.compliance[0].name : null
}
