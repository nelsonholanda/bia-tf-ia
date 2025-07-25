# Secrets and Parameter Store Module

# Parameter Store - Database Configuration
resource "aws_ssm_parameter" "rds_endpoint" {
  name        = var.environment == "dev" ? "rdsendpointdev" : "rdsendpointprod"
  type        = "String"
  value       = var.db_endpoint
  description = "RDS endpoint for BIA ${var.environment} environment"

  tags = merge(var.tags, {
    Name = "bia-${var.environment}-rds-endpoint"
  })
}

resource "aws_ssm_parameter" "db_port" {
  name        = "portdb"
  type        = "String"
  value       = "5432"
  description = "Database port for BIA application"

  tags = merge(var.tags, {
    Name = "bia-db-port"
  })
}

resource "aws_ssm_parameter" "db_user" {
  name        = "userdb"
  type        = "String"
  value       = var.db_username
  description = "Database username for BIA application"

  tags = merge(var.tags, {
    Name = "bia-db-user"
  })
}