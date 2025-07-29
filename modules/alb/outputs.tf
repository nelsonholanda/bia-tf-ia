output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.bia_alb.arn
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.bia_alb.dns_name
}

output "alb_zone_id" {
  description = "ALB hosted zone ID"
  value       = aws_lb.bia_alb.zone_id
}

output "alb_arn_suffix" {
  description = "ALB ARN suffix for CloudWatch metrics"
  value       = aws_lb.bia_alb.arn_suffix
}

output "target_group_arn" {
  description = "Target group ARN"
  value       = aws_lb_target_group.bia_tg.arn
}