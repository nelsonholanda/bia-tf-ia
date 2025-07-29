# Monitoring Module for BIA Application

# SNS Topic for alerts
resource "aws_sns_topic" "alerts" {
  name = "bia-${var.environment}-alerts"

  tags = merge(var.tags, {
    Name = "bia-${var.environment}-alerts"
  })
}

# SNS Topic subscription (email)
resource "aws_sns_topic_subscription" "email_alerts" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "BIA-${var.environment}-Dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ServiceName", "bia-${var.environment}-service", "ClusterName", "bia-${var.environment}-cluster"],
            [".", "MemoryUtilization", ".", ".", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "ECS Service Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", "bia-${var.environment}-db"],
            [".", "DatabaseConnections", ".", "."],
            [".", "FreeableMemory", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "RDS Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.alb_arn_suffix],
            [".", "RequestCount", ".", "."],
            [".", "HTTPCode_Target_2XX_Count", ".", "."],
            [".", "HTTPCode_Target_4XX_Count", ".", "."],
            [".", "HTTPCode_Target_5XX_Count", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "ALB Metrics"
          period  = 300
        }
      }
    ]
  })
}

# ECS Service CPU Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "ecs_high_cpu" {
  alarm_name          = "bia-${var.environment}-ecs-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.monitoring_config.cpu_alarm_threshold
  alarm_description   = "This metric monitors ECS service CPU utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    ServiceName = "bia-${var.environment}-service"
    ClusterName = "bia-${var.environment}-cluster"
  }

  tags = var.tags
}

# ECS Service Memory Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "ecs_high_memory" {
  alarm_name          = "bia-${var.environment}-ecs-high-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.monitoring_config.memory_alarm_threshold
  alarm_description   = "This metric monitors ECS service memory utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    ServiceName = "bia-${var.environment}-service"
    ClusterName = "bia-${var.environment}-cluster"
  }

  tags = var.tags
}

# RDS CPU Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "rds_high_cpu" {
  alarm_name          = "bia-${var.environment}-rds-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.monitoring_config.cpu_alarm_threshold
  alarm_description   = "This metric monitors RDS CPU utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = "bia-${var.environment}-db"
  }

  tags = var.tags
}

# RDS Free Storage Space Alarm
resource "aws_cloudwatch_metric_alarm" "rds_low_storage" {
  alarm_name          = "bia-${var.environment}-rds-low-storage"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "2000000000" # 2GB in bytes
  alarm_description   = "This metric monitors RDS free storage space"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = "bia-${var.environment}-db"
  }

  tags = var.tags
}

# ALB Target Response Time Alarm
resource "aws_cloudwatch_metric_alarm" "alb_high_response_time" {
  alarm_name          = "bia-${var.environment}-alb-high-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Average"
  threshold           = "2.0" # 2 seconds
  alarm_description   = "This metric monitors ALB target response time"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  tags = var.tags
}

# ALB 5XX Error Rate Alarm
resource "aws_cloudwatch_metric_alarm" "alb_high_5xx_errors" {
  alarm_name          = "bia-${var.environment}-alb-high-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors ALB 5XX error count"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  tags = var.tags
}

# ECS Service Task Count Alarm (for production)
resource "aws_cloudwatch_metric_alarm" "ecs_low_task_count" {
  count               = var.environment == "prod" ? 1 : 0
  alarm_name          = "bia-${var.environment}-ecs-low-task-count"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "RunningTaskCount"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "2"
  alarm_description   = "This metric monitors ECS service running task count"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    ServiceName = "bia-${var.environment}-service"
    ClusterName = "bia-${var.environment}-cluster"
  }

  tags = var.tags
}

# Log Group for custom application logs
resource "aws_cloudwatch_log_group" "application_logs" {
  name              = "/aws/ecs/bia-${var.environment}/application"
  retention_in_days = var.env_config.log_retention_days

  tags = merge(var.tags, {
    Name = "/aws/ecs/bia-${var.environment}/application"
  })
}

# Custom metric filter for application errors
resource "aws_cloudwatch_log_metric_filter" "application_errors" {
  name           = "bia-${var.environment}-application-errors"
  log_group_name = aws_cloudwatch_log_group.application_logs.name
  pattern        = "[timestamp, request_id, level=\"ERROR\", ...]"

  metric_transformation {
    name      = "ApplicationErrors"
    namespace = "BIA/${var.environment}"
    value     = "1"
  }
}

# Application Error Rate Alarm
resource "aws_cloudwatch_metric_alarm" "application_error_rate" {
  alarm_name          = "bia-${var.environment}-application-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ApplicationErrors"
  namespace           = "BIA/${var.environment}"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.environment == "prod" ? "5" : "10"
  alarm_description   = "This metric monitors application error rate"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  tags = var.tags
}
