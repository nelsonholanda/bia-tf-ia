output "rds_kms_key_arn" {
  description = "ARN of the RDS KMS key"
  value       = var.environment == "prod" ? aws_kms_key.rds[0].arn : null
}

output "rds_kms_key_id" {
  description = "ID of the RDS KMS key"
  value       = var.environment == "prod" ? aws_kms_key.rds[0].key_id : null
}

output "secrets_kms_key_arn" {
  description = "ARN of the Secrets Manager KMS key"
  value       = var.environment == "prod" ? aws_kms_key.secrets[0].arn : null
}

output "secrets_kms_key_id" {
  description = "ID of the Secrets Manager KMS key"
  value       = var.environment == "prod" ? aws_kms_key.secrets[0].key_id : null
}