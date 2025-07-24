output "ecs_task_execution_role_arn" {
  description = "ECS task execution role ARN"
  value       = aws_iam_role.ecs_task_execution_role.arn
}

output "ecs_instance_role_arn" {
  description = "ECS instance role ARN"
  value       = aws_iam_role.ecs_instance_role.arn
}

output "ecs_instance_profile_arn" {
  description = "ECS instance profile ARN"
  value       = aws_iam_instance_profile.ecs_instance_profile.arn
}