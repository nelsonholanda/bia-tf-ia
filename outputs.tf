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

output "vpc_cidr_block" {
  description = "VPC CIDR block"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "availability_zones" {
  description = "Availability zones used"
  value       = module.vpc.availability_zones
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

output "alb_zone_id" {
  description = "ALB hosted zone ID"
  value       = module.alb.alb_zone_id
}

# RDS Outputs
output "rds_endpoint" {
  description = "RDS endpoint"
  value       = module.rds.db_instance_endpoint
  sensitive   = true
}

output "rds_instance_arn" {
  description = "RDS instance ARN"
  value       = module.rds.db_instance_arn
}

output "rds_kms_key_arn" {
  description = "ARN of the RDS KMS key"
  value       = module.kms.rds_kms_key_arn
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

# Secrets Outputs
output "db_password_secret_name" {
  description = "Name of the database password secret in Secrets Manager"
  value       = module.rds.db_password_secret_name
  sensitive   = true
}

output "db_password_secret_arn" {
  description = "ARN of the database password secret in Secrets Manager"
  value       = module.rds.db_password_secret_arn
  sensitive   = true
}

# WAF Outputs
output "waf_web_acl_arn" {
  description = "ARN of the WAF Web ACL (production only)"
  value       = var.environment == "prod" ? module.waf.web_acl_arn : null
}

# CloudWatch Outputs
output "log_group_name" {
  description = "CloudWatch log group name"
  value       = module.cloudwatch.log_group_name
}

# Application URLs
output "application_url" {
  description = "Application URL (ALB DNS name)"
  value       = "http://${module.alb.alb_dns_name}"
}

# Environment Summary
output "environment_summary" {
  description = "Summary of the deployed environment"
  value = {
    environment        = var.environment
    vpc_cidr           = module.vpc.vpc_cidr_block
    availability_zones = length(module.vpc.availability_zones)
    container_insights = local.current_env.enable_container_insights
    multi_az           = local.current_env.multi_az
    waf_enabled        = var.environment == "prod"
    kms_enabled        = var.environment == "prod"
  }
}

