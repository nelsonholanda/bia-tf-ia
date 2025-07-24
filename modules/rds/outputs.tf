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