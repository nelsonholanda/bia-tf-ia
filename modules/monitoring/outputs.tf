output "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = aws_sns_topic.alerts.arn
}

output "dashboard_url" {
  description = "URL of the CloudWatch dashboard"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

output "application_log_group_name" {
  description = "Name of the application log group"
  value       = aws_cloudwatch_log_group.application_logs.name
}

output "alarm_names" {
  description = "List of CloudWatch alarm names"
  value = [
    aws_cloudwatch_metric_alarm.ecs_high_cpu.alarm_name,
    aws_cloudwatch_metric_alarm.ecs_high_memory.alarm_name,
    aws_cloudwatch_metric_alarm.rds_high_cpu.alarm_name,
    aws_cloudwatch_metric_alarm.rds_low_storage.alarm_name,
    aws_cloudwatch_metric_alarm.alb_high_response_time.alarm_name,
    aws_cloudwatch_metric_alarm.alb_high_5xx_errors.alarm_name,
    aws_cloudwatch_metric_alarm.application_error_rate.alarm_name
  ]
}
