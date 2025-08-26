terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 6.5.0"
      configuration_aliases = [aws.sa_east_1]
    }
  }
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_backup_vault" "main" {
  count = var.environment == "prod" ? 1 : 0

  name        = "${var.environment}-backup-vault"
  kms_key_arn = var.backup_kms_key_arn

  tags = merge(var.tags, {
    Name = "${var.environment}-backup-vault"
    Type = "BackupVault"
  })
}

resource "aws_backup_vault" "cross_region" {
  count = var.environment == "prod" ? 1 : 0

  provider = aws.sa_east_1

  name        = "${var.environment}-backup-vault-cross-region"
  kms_key_arn = var.cross_region_kms_key_arn

  tags = merge(var.tags, {
    Name   = "${var.environment}-backup-vault-cross-region"
    Type   = "BackupVaultCrossRegion"
    Region = "sa-east-1"
  })
}

resource "aws_iam_role" "backup" {
  count = var.environment == "prod" ? 1 : 0

  name = "${var.environment}-aws-backup-role"

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

resource "aws_iam_role_policy_attachment" "backup_service_role" {
  count = var.environment == "prod" ? 1 : 0

  role       = aws_iam_role.backup[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "backup_restore_role" {
  count = var.environment == "prod" ? 1 : 0

  role       = aws_iam_role.backup[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

resource "aws_iam_role_policy" "backup_cross_region" {
  count = var.environment == "prod" ? 1 : 0

  name = "${var.environment}-backup-cross-region-policy"
  role = aws_iam_role.backup[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "backup:CopyIntoBackupVault",
          "backup:CreateBackupPlan",
          "backup:CreateBackupSelection",
          "backup:DescribeBackupJob",
          "backup:DescribeBackupVault",
          "backup:DescribeCopyJob",
          "backup:GetBackupPlan",
          "backup:GetBackupSelection",
          "backup:ListBackupJobs",
          "backup:ListBackupPlans",
          "backup:ListBackupSelections",
          "backup:ListBackupVaults",
          "backup:ListCopyJobs",
          "backup:ListRecoveryPoints",
          "backup:StartBackupJob",
          "backup:StartCopyJob",
          "backup:StopBackupJob",
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:GenerateDataKey",
          "kms:ReEncrypt*"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_backup_plan" "daily" {
  count = var.environment == "prod" ? 1 : 0

  name = "${var.environment}-daily-backup-plan"

  rule {
    rule_name         = "daily_backup_rule"
    target_vault_name = aws_backup_vault.main[0].name
    schedule          = var.backup_schedule
    start_window      = var.backup_start_window
    completion_window = var.backup_completion_window

    recovery_point_tags = merge(var.tags, {
      BackupType = "Daily"
      Region     = data.aws_region.current.id
    })

    lifecycle {
      cold_storage_after = var.backup_cold_storage_after
      delete_after       = var.backup_retention_days
    }

    copy_action {
      destination_vault_arn = aws_backup_vault.cross_region[0].arn

      lifecycle {
        cold_storage_after = var.cross_region_cold_storage_after
        delete_after       = var.cross_region_retention_days
      }
    }
  }

  rule {
    rule_name         = "weekly_backup_rule"
    target_vault_name = aws_backup_vault.main[0].name
    schedule          = var.weekly_backup_schedule
    start_window      = var.backup_start_window
    completion_window = var.backup_completion_window

    recovery_point_tags = merge(var.tags, {
      BackupType = "Weekly"
      Region     = data.aws_region.current.id
    })

    lifecycle {
      cold_storage_after = var.weekly_cold_storage_after
      delete_after       = var.weekly_retention_days
    }

    copy_action {
      destination_vault_arn = aws_backup_vault.cross_region[0].arn

      lifecycle {
        cold_storage_after = var.weekly_cross_region_cold_storage_after
        delete_after       = var.weekly_cross_region_retention_days
      }
    }
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-daily-backup-plan"
    Type = "BackupPlan"
  })
}

resource "aws_backup_selection" "rds" {
  count = var.environment == "prod" ? 1 : 0

  iam_role_arn = aws_iam_role.backup[0].arn
  name         = "${var.environment}-rds-backup-selection"
  plan_id      = aws_backup_plan.daily[0].id

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "Environment"
    value = var.environment
  }

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "BackupEnabled"
    value = "true"
  }

  resources = var.rds_instance_arns

  depends_on = [
    aws_iam_role_policy_attachment.backup_service_role,
    aws_iam_role_policy_attachment.backup_restore_role,
    aws_iam_role_policy.backup_cross_region
  ]
}

resource "aws_cloudwatch_event_rule" "backup_events" {
  count = var.environment == "prod" ? 1 : 0

  name        = "${var.environment}-backup-events"
  description = "Capture backup job state changes"

  event_pattern = jsonencode({
    source      = ["aws.backup"]
    detail-type = ["Backup Job State Change", "Copy Job State Change"]
    detail = {
      state = ["COMPLETED", "FAILED", "EXPIRED"]
    }
  })

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "backup_events" {
  count = var.environment == "prod" ? 1 : 0

  name              = "/aws/backup/${var.environment}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.backup_kms_key_arn

  tags = merge(var.tags, {
    Name = "${var.environment}-backup-logs"
    Type = "BackupLogs"
  })
}

resource "aws_cloudwatch_log_metric_filter" "backup_failures" {
  count = var.environment == "prod" ? 1 : 0

  name           = "${var.environment}-backup-failures"
  log_group_name = aws_cloudwatch_log_group.backup_events[0].name
  pattern        = "[timestamp, request_id, event_type=\"FAILED\"]"

  metric_transformation {
    name      = "BackupFailures"
    namespace = "AWS/Backup/Custom"
    value     = "1"

    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "backup_failures" {
  count = var.environment == "prod" ? 1 : 0

  alarm_name          = "${var.environment}-backup-failures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "BackupFailures"
  namespace           = "AWS/Backup/Custom"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors backup failures"
  alarm_actions       = var.alarm_sns_topic_arns

  tags = var.tags
}

resource "aws_backup_report_plan" "compliance" {
  count = var.environment == "prod" ? 1 : 0

  name        = "${var.environment}-backup-compliance-report"
  description = "Daily backup compliance report"

  report_delivery_channel {
    s3_bucket_name = var.reports_s3_bucket
    s3_key_prefix  = "backup-reports/${var.environment}/"
    formats        = ["CSV", "JSON"]
  }

  report_setting {
    report_template = "BACKUP_JOB_REPORT"

    framework_arns       = []
    number_of_frameworks = 0
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-backup-compliance-report"
    Type = "BackupReport"
  })
}
