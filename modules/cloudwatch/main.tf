# CloudWatch Module

resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/bia-${var.environment}"
  retention_in_days = try(var.env_config.log_retention_days, 7)

  tags = merge(var.tags, {
    Name = "/ecs/bia-${var.environment}"
  })
}