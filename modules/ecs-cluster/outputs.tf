output "cluster_id" {
  description = "ECS cluster ID"
  value       = aws_ecs_cluster.main.id
}

output "cluster_arn" {
  description = "ECS cluster ARN"
  value       = aws_ecs_cluster.main.arn
}

output "capacity_provider_name" {
  description = "ECS capacity provider name"
  value       = aws_ecs_capacity_provider.main.name
}

output "auto_scaling_group_name" {
  description = "Auto Scaling Group name"
  value       = aws_autoscaling_group.ecs.name
}

output "launch_template_id" {
  description = "Launch template ID"
  value       = aws_launch_template.ecs.id
}