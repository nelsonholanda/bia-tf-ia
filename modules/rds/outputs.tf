output "db_instance_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.bia.endpoint
}

output "db_instance_id" {
  description = "RDS instance ID"
  value       = aws_db_instance.bia.id
}

output "db_instance_arn" {
  description = "RDS instance ARN"
  value       = aws_db_instance.bia.arn
}

output "db_password_secret_arn" {
  description = "ARN of the database credentials secret"
  value       = aws_secretsmanager_secret.db_password.arn
}

output "db_password_secret_name" {
  description = "Name of the database credentials secret"
  value       = aws_secretsmanager_secret.db_password.name
}

output "db_password_secret_id" {
  description = "ID of the database credentials secret"
  value       = aws_secretsmanager_secret.db_password.id
}

output "db_host_only" {
  description = "Database host without port (for debugging)"
  value       = regex("^([^:]+)", aws_db_instance.bia.endpoint)[0]
}

output "db_port" {
  description = "Database port"
  value       = aws_db_instance.bia.port
}