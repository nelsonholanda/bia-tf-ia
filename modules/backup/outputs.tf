output "backup_vault_arn" {
  description = "ARN of the backup vault"
  value       = aws_backup_vault.main.arn
}

output "backup_plan_arn" {
  description = "ARN of the backup plan"
  value       = aws_backup_plan.main.arn
}

output "backup_role_arn" {
  description = "ARN of the backup IAM role"
  value       = aws_iam_role.backup.arn
}

output "backup_kms_key_arn" {
  description = "ARN of the backup KMS key"
  value       = var.environment == "prod" ? aws_kms_key.backup[0].arn : null
}

output "cross_region_backup_vault_arn" {
  description = "ARN of the cross-region backup vault"
  value       = var.environment == "prod" && var.env_config.enable_cross_region_backup ? aws_backup_vault.cross_region[0].arn : null
}
