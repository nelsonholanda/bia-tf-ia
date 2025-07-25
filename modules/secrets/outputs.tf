output "parameter_store_paths" {
  description = "Parameter Store paths for database configuration"
  value = {
    rds_endpoint = aws_ssm_parameter.rds_endpoint.name
    db_port      = aws_ssm_parameter.db_port.name
    db_user      = aws_ssm_parameter.db_user.name
  }
}