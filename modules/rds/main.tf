locals {
  db_host = regex("^([^:]+)", aws_db_instance.bia.endpoint)[0]
}

resource "aws_db_subnet_group" "bia" {
  name       = "bia-${var.environment}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = "bia-${var.environment}-subnet-group"
  })
}

resource "aws_secretsmanager_secret" "db_password" {
  name                    = "bia-${var.environment}-secrets"
  description             = "Database credentials for BIA ${var.environment} environment"
  recovery_window_in_days = var.environment == "prod" ? 30 : 7
  kms_key_id              = var.secrets_kms_key_arn

  lifecycle {
    create_before_destroy = false
  }

  tags = merge(var.tags, {
    Name        = "bia-${var.environment}-secrets"
    Environment = var.environment
    Purpose     = "RDS-Database-Credentials"
  })
}

resource "random_password" "db_password" {
  length           = 16
  special          = true
  upper            = true
  lower            = true
  numeric          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

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

resource "aws_secretsmanager_secret_rotation" "db_password" {
  count               = var.environment == "prod" ? 1 : 0
  secret_id           = aws_secretsmanager_secret.db_password.id
  rotation_lambda_arn = aws_lambda_function.rotation_lambda[0].arn

  rotation_rules {
    automatically_after_days = 30
  }

  depends_on = [
    aws_db_instance.bia,
    aws_secretsmanager_secret_version.db_password_updated,
    aws_lambda_function.rotation_lambda
  ]
}

resource "aws_lambda_function" "rotation_lambda" {
  count         = var.environment == "prod" ? 1 : 0
  filename      = data.archive_file.rotation_lambda_zip[0].output_path
  function_name = "bia-${var.environment}-secret-rotation"
  role          = aws_iam_role.rotation_lambda_role[0].arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  timeout       = 30

  source_code_hash = data.archive_file.rotation_lambda_zip[0].output_base64sha256

  environment {
    variables = {
      SECRETS_MANAGER_ENDPOINT = "https://secretsmanager.${data.aws_region.current.id}.amazonaws.com"
    }
  }

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = var.security_group_ids
  }

  tags = merge(var.tags, {
    Name = "bia-${var.environment}-secret-rotation"
  })
}

data "archive_file" "rotation_lambda_zip" {
  count       = var.environment == "prod" ? 1 : 0
  type        = "zip"
  output_path = "/tmp/rotation_lambda.zip"

  source {
    content = templatefile("${path.module}/rotation_lambda.py", {
      db_instance_identifier = aws_db_instance.bia.identifier
    })
    filename = "lambda_function.py"
  }
}

resource "aws_iam_role" "rotation_lambda_role" {
  count = var.environment == "prod" ? 1 : 0
  name  = "bia-${var.environment}-rotation-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "rotation_lambda_policy" {
  count = var.environment == "prod" ? 1 : 0
  name  = "bia-${var.environment}-rotation-lambda-policy"
  role  = aws_iam_role.rotation_lambda_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue",
          "secretsmanager:UpdateSecretVersionStage"
        ]
        Resource = aws_secretsmanager_secret.db_password.arn
      },
      {
        Effect = "Allow"
        Action = [
          "rds:ModifyDBInstance",
          "rds:DescribeDBInstances"
        ]
        Resource = aws_db_instance.bia.arn
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = var.secrets_kms_key_arn
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_lambda_permission" "allow_secrets_manager" {
  count         = var.environment == "prod" ? 1 : 0
  statement_id  = "AllowExecutionFromSecretsManager"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rotation_lambda[0].function_name
  principal     = "secretsmanager.amazonaws.com"
}





resource "aws_db_instance" "bia" {
  identifier     = "bia-${var.environment}-db"
  engine         = "postgres"
  engine_version = "17.4"
  instance_class = "db.t3.micro"

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp2"
  storage_encrypted     = var.environment == "prod" ? true : false
  kms_key_id            = var.rds_kms_key_arn

  db_name  = var.database_name
  username = var.db_username
  password = random_password.db_password.result

  vpc_security_group_ids = var.security_group_ids
  db_subnet_group_name   = aws_db_subnet_group.bia.name

  multi_az                     = var.env_config.multi_az
  backup_retention_period      = var.env_config.backup_retention_period
  performance_insights_enabled = try(var.env_config.enable_performance_insights, false)
  backup_window                = try(var.env_config.backup_window, var.backup_window)
  maintenance_window           = try(var.env_config.maintenance_window, var.maintenance_window)

  delete_automated_backups = try(var.env_config.delete_automated_backups, true)
  copy_tags_to_snapshot    = try(var.env_config.copy_tags_to_snapshot, true)

  skip_final_snapshot       = var.environment == "prod" ? false : true
  final_snapshot_identifier = var.environment == "prod" ? "bia-${var.environment}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}" : null
  deletion_protection       = try(var.env_config.enable_deletion_protection, false)

  tags = merge(var.tags, {
    Name          = "bia-${var.environment}-db"
    Environment   = var.environment
    BackupEnabled = "true"
  })


}
