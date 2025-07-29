# RDS Module for BIA Application with Enhanced Security

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

# Generate random password for initial setup
resource "random_password" "db_password" {
  length  = 32 # Increased length for better security
  special = true
  upper   = true
  lower   = true
  numeric = true
  # Exclude characters that might cause issues in connection strings
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# AWS Secrets Manager - Database credentials with standardized naming
resource "aws_secretsmanager_secret" "db_password" {
  name                    = "bia-${var.environment}-db-credentials"
  description             = "Database credentials for BIA ${var.environment} environment"
  recovery_window_in_days = var.environment == "prod" ? 30 : 7
  kms_key_id              = var.secrets_kms_key_arn

  # Force replacement if there are conflicts (helps with orphaned secrets)
  lifecycle {
    create_before_destroy = false
  }

  tags = merge(var.tags, {
    Name        = "bia-${var.environment}-db-credentials"
    Environment = var.environment
    Purpose     = "RDS-Database-Credentials"
    Rotation    = var.environment == "prod" ? "Enabled" : "Disabled"
  })
}

# Initial secret version with generated password (will be updated after RDS creation)
resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    username             = var.db_username
    password             = random_password.db_password.result
    engine               = "postgres"
    host                 = "placeholder-will-be-updated"
    port                 = 5432
    dbname               = var.database_name
    dbInstanceIdentifier = "bia-${var.environment}-db"
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# RDS Instance with enhanced configuration
resource "aws_db_instance" "bia" {
  identifier     = "bia-${var.environment}-db"
  engine         = "postgres"
  engine_version = var.postgres_version
  instance_class = var.env_config.rds_instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3" # Upgraded to gp3 for better performance
  storage_encrypted     = var.environment == "prod" ? true : false
  kms_key_id            = var.rds_kms_key_arn

  db_name  = var.database_name
  username = var.db_username
  password = random_password.db_password.result

  vpc_security_group_ids = var.security_group_ids
  db_subnet_group_name   = aws_db_subnet_group.bia.name

  multi_az                              = var.env_config.multi_az
  backup_retention_period               = var.env_config.backup_retention_period
  performance_insights_enabled          = try(var.env_config.enable_performance_insights, false)
  performance_insights_retention_period = var.environment == "prod" ? 7 : null
  backup_window                         = var.backup_window
  maintenance_window                    = var.maintenance_window

  skip_final_snapshot       = var.environment == "prod" ? false : true
  final_snapshot_identifier = var.environment == "prod" ? "bia-${var.environment}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}" : null
  deletion_protection       = try(var.env_config.enable_deletion_protection, false)

  # Enhanced monitoring
  monitoring_interval = var.environment == "prod" ? 60 : 0
  monitoring_role_arn = var.environment == "prod" ? aws_iam_role.rds_enhanced_monitoring[0].arn : null

  # Enable automated minor version upgrades
  auto_minor_version_upgrade = true

  # Enable logging
  enabled_cloudwatch_logs_exports = ["postgresql"]

  tags = merge(var.tags, {
    Name = "bia-${var.environment}-db"
  })

  depends_on = [aws_db_subnet_group.bia]
}

# Update secret with actual RDS endpoint after creation
resource "aws_secretsmanager_secret_version" "db_password_updated" {
  secret_id = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    username             = var.db_username
    password             = random_password.db_password.result
    engine               = "postgres"
    host                 = local.db_host
    port                 = aws_db_instance.bia.port
    dbname               = aws_db_instance.bia.db_name
    dbInstanceIdentifier = aws_db_instance.bia.identifier
  })

  depends_on = [aws_db_instance.bia, aws_secretsmanager_secret_version.db_password]
}

# IAM Role for RDS Enhanced Monitoring (production only)
resource "aws_iam_role" "rds_enhanced_monitoring" {
  count = var.environment == "prod" ? 1 : 0
  name  = "bia-${var.environment}-rds-enhanced-monitoring"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  count      = var.environment == "prod" ? 1 : 0
  role       = aws_iam_role.rds_enhanced_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# Secret rotation configuration (production only)
resource "aws_secretsmanager_secret_rotation" "db_password" {
  count               = var.environment == "prod" ? 1 : 0
  secret_id           = aws_secretsmanager_secret.db_password.id
  rotation_lambda_arn = var.rotation_lambda_arn

  rotation_rules {
    automatically_after_days = 30
  }

  depends_on = [aws_secretsmanager_secret_version.db_password_updated]
}