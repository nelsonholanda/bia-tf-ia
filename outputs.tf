# Outputs

output "aws_account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  description = "AWS Region"
  value       = data.aws_region.current.id
}

# VPC Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

# ECS Outputs
output "cluster_id" {
  description = "ECS cluster ID"
  value       = module.ecs_cluster.cluster_id
}

output "cluster_arn" {
  description = "ECS cluster ARN"
  value       = module.ecs_cluster.cluster_arn
}

output "service_id" {
  description = "ECS service ID"
  value       = module.ecs_service.service_id
}

output "service_arn" {
  description = "ECS service ARN"
  value       = module.ecs_service.service_arn
}

output "task_definition_arn" {
  description = "Task definition ARN"
  value       = module.ecs_service.task_definition_arn
}

# ALB Outputs
output "alb_dns_name" {
  description = "ALB DNS name"
  value       = module.alb.alb_dns_name
}

output "alb_arn" {
  description = "ALB ARN"
  value       = module.alb.alb_arn
}

output "alb_target_group_arn" {
  description = "ALB target group ARN"
  value       = module.alb.target_group_arn
}

# RDS Outputs
output "rds_endpoint" {
  description = "RDS endpoint"
  value       = module.rds.db_instance_endpoint
  sensitive   = true
}

# Security Group Outputs
output "security_group_ids" {
  description = "Security group IDs"
  value = {
    bia_dev = module.security_groups.bia_dev_sg_id
    bia_rds = module.security_groups.bia_rds_sg_id
    bia_alb = module.security_groups.bia_alb_sg_id
    bia_ec2 = module.security_groups.bia_ec2_sg_id
  }
}