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
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_public_subnet_ids" {
  description = "List of IDs of the public subnets"
  value       = module.vpc.subnet_ids
}

output "vpc_private_subnet_ids" {
  description = "List of IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

# ECS Outputs
output "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  value       = module.ecs_cluster.cluster_id
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = module.ecs_cluster.cluster_arn
}

output "ecs_service_id" {
  description = "ID of the ECS service"
  value       = module.ecs_service.service_id
}

output "ecs_service_arn" {
  description = "ARN of the ECS service"
  value       = module.ecs_service.service_arn
}

output "ecs_task_definition_arn" {
  description = "ARN of the ECS task definition"
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
output "rds_instance_endpoint" {
  description = "Connection endpoint for the RDS instance"
  value       = module.rds.db_instance_endpoint
  sensitive   = true
}

output "rds_instance_kms_key_arn" {
  description = "ARN of the KMS key used for RDS encryption"
  value       = module.kms.rds_kms_key_arn
  sensitive   = true
}

# Security Group Outputs
output "security_group_ids" {
  description = "Map of security group IDs by purpose"
  value = {
    ecs_service = module.security_groups.bia_dev_sg_id
    rds_database = module.security_groups.bia_rds_sg_id
    alb_load_balancer = module.security_groups.bia_alb_sg_id
    ec2_instances = module.security_groups.bia_ec2_sg_id
  }
}

# Secrets Manager Outputs
output "rds_credentials_secret_name" {
  description = "Name of the RDS credentials secret in AWS Secrets Manager"
  value       = module.rds.db_password_secret_name
  sensitive   = true
}

# WAF Outputs
output "waf_web_acl_arn" {
  description = "ARN of the WAF Web ACL (production environment only)"
  value       = var.environment == "prod" ? module.waf.web_acl_arn : null
}

