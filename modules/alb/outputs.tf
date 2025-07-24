output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.bia_alb.arn
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.bia_alb.dns_name
}

output "target_group_arn" {
  description = "Target group ARN"
  value       = aws_lb_target_group.bia_tg.arn
}