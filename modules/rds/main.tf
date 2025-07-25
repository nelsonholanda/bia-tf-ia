# RDS Module for BIA Application

# Local values for processing RDS endpoint
locals {
  # Extract only the hostname from the RDS endpoint, removing port if present
  db_host = regex("^([^:]+)", aws_db_instance.bia.endpoint)[0]
}

# DB Subnet Group
resource "aws_db_subnet_group" "bia" {
  name       = "bia-${var.environment}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = "bia-${var.environment}-subnet-group"
  })
}

# AWS Secrets Manager - Database credentials with standardized naming
resource "aws_secretsmanager_secret" "db_password" {
  name                    = "bia-${var.environment}-secrets"
  description             = "Database credentials for BIA ${var.environment} environment"
  recovery_window_in_days = var.environment == "prod" ? 30 : 0
  
  tags = merge(var.tags, {
    Name        = "bia-${var.environment}-secrets"
    Environment = var.environment
    Purpose     = "RDS-Database-Credentials"
  })
}

# Generate random password for initial setup
resource "random_password" "db_password" {
  length  = 16
  special = true
  upper   = true
  lower   = true
  numeric = true
  # Exclude characters that might cause issues in connection strings
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Initial secret version with generated password (will be updated after RDS creation)
resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
    engine   = "postgres"
    host     = "placeholder-will-be-updated"
    port     = 5432
    dbname   = var.database_name
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# Update secret with actual RDS endpoint after creation
resource "aws_secretsmanager_secret_version" "db_password_updated" {
  secret_id = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
    engine   = "postgres"
    host     = local.db_host
    port     = aws_db_instance.bia.port
    dbname   = aws_db_instance.bia.db_name
  })

  depends_on = [aws_db_instance.bia, aws_secretsmanager_secret_version.db_password]
}

# TODO: Add secret rotation configuration after initial deployment
# This will be implemented in a future update to avoid circular dependencies



resource "aws_db_instance" "bia" {
  identifier     = "bia-${var.environment}-db"
  engine         = "postgres"
  engine_version = "17.4"
  instance_class = "db.t3.micro"

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp2"
  storage_encrypted     = false

  db_name  = var.database_name
  username = var.db_username
  password = random_password.db_password.result

  vpc_security_group_ids = var.security_group_ids
  db_subnet_group_name   = aws_db_subnet_group.bia.name

  multi_az                = var.environment == "prod" ? true : false
  backup_retention_period = var.environment == "prod" ? 7 : 1
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window

  skip_final_snapshot = true
  deletion_protection = false

  tags = merge(var.tags, {
    Name = "bia-${var.environment}-db"
  })


}