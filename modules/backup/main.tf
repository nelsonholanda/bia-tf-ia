# Backup Module for BIA Application

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.5.0"
      configuration_aliases = [aws.backup_region]
    }
  }
}

# KMS Key for backup encryption
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

# IAM Role for AWS Backup
resource "aws_iam_role" "backup" {
  name = "bia-${var.environment}-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Attach AWS managed policy for backup service
resource "aws_iam_role_policy_attachment" "backup_service_role" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

# Attach AWS managed policy for restore operations
resource "aws_iam_role_policy_attachment" "backup_restore_role" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

# AWS Backup Vault
resource "aws_backup_vault" "main" {
  name        = "bia-${var.environment}-backup-vault"
  kms_key_arn = var.environment == "prod" ? aws_kms_key.backup[0].arn : null

  tags = merge(var.tags, {
    Name = "bia-${var.environment}-backup-vault"
  })
}

# AWS Backup Plan
resource "aws_backup_plan" "main" {
  name = "bia-${var.environment}-backup-plan"

  # Daily backup rule
  rule {
    rule_name         = "daily_backup"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 5 ? * * *)" # 5 AM UTC daily

    start_window      = 60  # 1 hour
    completion_window = 300 # 5 hours

    lifecycle {
      cold_storage_after = var.environment == "prod" ? 30 : null
      delete_after       = var.env_config.backup_retention_days
    }

    recovery_point_tags = merge(var.tags, {
      BackupType = "Daily"
    })
  }

  # Weekly backup rule (production only)
  dynamic "rule" {
    for_each = var.environment == "prod" ? [1] : []
    content {
      rule_name         = "weekly_backup"
      target_vault_name = aws_backup_vault.main.name
      schedule          = "cron(0 3 ? * SUN *)" # 3 AM UTC every Sunday

      start_window      = 60  # 1 hour
      completion_window = 300 # 5 hours

      lifecycle {
        cold_storage_after = 90
        delete_after       = 365 # 1 year retention for weekly backups
      }

      recovery_point_tags = merge(var.tags, {
        BackupType = "Weekly"
      })
    }
  }

  tags = var.tags
}

# Backup Selection for RDS
resource "aws_backup_selection" "rds" {
  iam_role_arn = aws_iam_role.backup.arn
  name         = "bia-${var.environment}-rds-backup-selection"
  plan_id      = aws_backup_plan.main.id

  resources = [
    var.rds_instance_arn
  ]

  condition {
    string_equals {
      key   = "aws:ResourceTag/Backup"
      value = var.environment == "prod" ? "Required" : "Optional"
    }
  }
}

# Cross-region backup (production only)
resource "aws_backup_vault" "cross_region" {
  count       = var.environment == "prod" && var.env_config.enable_cross_region_backup ? 1 : 0
  name        = "bia-${var.environment}-backup-vault-cross-region"
  kms_key_arn = aws_kms_key.backup[0].arn

  # Use a different region for cross-region backup
  provider = aws.backup_region

  tags = merge(var.tags, {
    Name = "bia-${var.environment}-backup-vault-cross-region"
  })
}

# Cross-region backup plan (production only)
resource "aws_backup_plan" "cross_region" {
  count = var.environment == "prod" && var.env_config.enable_cross_region_backup ? 1 : 0
  name  = "bia-${var.environment}-backup-plan-cross-region"

  provider = aws.backup_region

  rule {
    rule_name         = "cross_region_backup"
    target_vault_name = aws_backup_vault.cross_region[0].name
    schedule          = "cron(0 6 ? * * *)" # 6 AM UTC daily

    start_window      = 60  # 1 hour
    completion_window = 300 # 5 hours

    lifecycle {
      cold_storage_after = 30
      delete_after       = 90 # 3 months retention for cross-region
    }

    copy_action {
      destination_vault_arn = aws_backup_vault.main.arn

      lifecycle {
        cold_storage_after = 30
        delete_after       = 365
      }
    }

    recovery_point_tags = merge(var.tags, {
      BackupType = "CrossRegion"
    })
  }

  tags = var.tags
}

# Backup vault notifications
resource "aws_backup_vault_notifications" "main" {
  backup_vault_name = aws_backup_vault.main.name
  sns_topic_arn     = var.sns_topic_arn
  backup_vault_events = [
    "BACKUP_JOB_STARTED",
    "BACKUP_JOB_COMPLETED",
    "BACKUP_JOB_FAILED",
    "RESTORE_JOB_STARTED",
    "RESTORE_JOB_COMPLETED",
    "RESTORE_JOB_FAILED"
  ]
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}
