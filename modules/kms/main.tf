resource "aws_kms_key" "rds" {
  count                   = var.environment == "prod" ? 1 : 0
  description             = "KMS key for RDS encryption in ${var.environment} environment"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow RDS Service"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:CreateGrant"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "bia-${var.environment}-rds-kms-key"
  })
}

resource "aws_kms_alias" "rds" {
  count         = var.environment == "prod" ? 1 : 0
  name          = "alias/bia-${var.environment}-rds"
  target_key_id = aws_kms_key.rds[0].key_id
}

resource "aws_kms_key" "secrets" {
  count                   = var.environment == "prod" ? 1 : 0
  description             = "KMS key for Secrets Manager encryption in ${var.environment} environment"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow Secrets Manager Service"
        Effect = "Allow"
        Principal = {
          Service = "secretsmanager.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:CreateGrant"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow ECS Task Execution Role"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/bia-${var.environment}-ecsTaskExecutionRole"
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "bia-${var.environment}-secrets-kms-key"
  })
}

resource "aws_kms_alias" "secrets" {
  count         = var.environment == "prod" ? 1 : 0
  name          = "alias/bia-${var.environment}-secrets"
  target_key_id = aws_kms_key.secrets[0].key_id
}

resource "aws_kms_key" "backup" {
  count                   = var.environment == "prod" ? 1 : 0
  description             = "KMS key for AWS Backup encryption in ${var.environment} environment"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow AWS Backup Service"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = [
              "backup.us-east-1.amazonaws.com",
              "backup.sa-east-1.amazonaws.com"
            ]
          }
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "bia-${var.environment}-backup-kms-key"
  })
}

resource "aws_kms_alias" "backup" {
  count         = var.environment == "prod" ? 1 : 0
  name          = "alias/bia-${var.environment}-backup"
  target_key_id = aws_kms_key.backup[0].key_id
}

data "aws_caller_identity" "current" {}
