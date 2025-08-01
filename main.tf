# Main Terraform configuration for BIA ECS Infrastructure
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.0"
    }
  }

  backend "s3" {
    # Backend configuration will be provided via -backend-config
  }
}

provider "aws" {
  region = var.aws_region
}

# Provider for cross-region backup (sa-east-1)
provider "aws" {
  alias  = "sa_east_1"
  region = "sa-east-1"
}

# Data sources for existing resources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Secrets cleanup is handled by the cleanup-secrets.sh script
# which runs before terraform apply in the deploy.sh script

# KMS Module (for production encryption)
module "kms" {
  source = "./modules/kms"

  environment = var.environment
  tags        = local.common_tags
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  environment = var.environment
  tags        = local.common_tags
  env_config  = local.current_env
}

# IAM Module
module "iam" {
  source = "./modules/iam"

  environment  = var.environment
  tags         = local.common_tags
  cluster_name = var.ecs_cluster_name
}

# Security Groups Module
module "security_groups" {
  source = "./modules/security-groups"

  environment  = var.environment
  tags         = local.common_tags
  vpc_id       = module.vpc.vpc_id
  cluster_name = var.ecs_cluster_name
}

# CloudWatch Module
module "cloudwatch" {
  source = "./modules/cloudwatch"

  environment    = var.environment
  tags           = local.common_tags
  log_group_name = var.cloudwatch_log_group_name
  env_config     = local.current_env
}

# RDS Module
module "rds" {
  source = "./modules/rds"

  environment         = var.environment
  tags                = local.common_tags
  env_config          = local.current_env
  db_identifier       = "bia"
  security_group_ids  = [module.security_groups.bia_rds_sg_id]
  subnet_ids          = module.vpc.private_subnet_ids
  rds_kms_key_arn     = module.kms.rds_kms_key_arn
  secrets_kms_key_arn = module.kms.secrets_kms_key_arn

  depends_on = [
    module.kms
  ]
}



# ALB Module
module "alb" {
  source = "./modules/alb"

  environment        = var.environment
  tags               = local.common_tags
  alb_name           = "alb-bia"
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.subnet_ids
  security_group_ids = [module.security_groups.bia_alb_sg_id]
}

# ECS Cluster Module
module "ecs_cluster" {
  source = "./modules/ecs-cluster"

  environment          = var.environment
  tags                 = local.common_tags
  env_config           = local.current_env
  cluster_name         = var.ecs_cluster_name
  vpc_id               = module.vpc.vpc_id
  subnet_ids           = module.vpc.ecs_subnet_ids
  security_group_id    = module.security_groups.ecs_security_group_id
  instance_profile_arn = module.iam.ecs_instance_profile_arn
  key_name             = var.ec2_key_pair_name

  depends_on = [
    module.vpc,
    module.security_groups,
    module.iam
  ]
}

# ECS Service Module
module "ecs_service" {
  source = "./modules/ecs-service"

  environment                  = var.environment
  tags                         = local.common_tags
  env_config                   = local.current_env
  cluster_id                   = module.ecs_cluster.cluster_id
  cluster_name                 = var.ecs_cluster_name
  service_name                 = var.ecs_service_name
  task_definition_family       = var.ecs_task_definition_family
  container_name               = var.app_container_name
  container_image              = var.ecr_repository_url
  container_cpu                = var.app_container_cpu
  container_memory_reservation = var.app_container_memory_reservation
  container_port               = var.app_container_port
  log_group_name               = module.cloudwatch.log_group_name
  task_execution_role_arn      = module.iam.ecs_task_execution_role_arn
  capacity_provider_name       = module.ecs_cluster.capacity_provider_name
  target_group_arn             = module.alb.target_group_arn

  # Use Secrets Manager for all database credentials
  db_password_secret_arn = module.rds.db_password_secret_arn

  depends_on = [
    module.ecs_cluster,
    module.alb,
    module.iam,
    module.cloudwatch,
    module.rds
  ]
}

# WAF Module (for production protection)
module "waf" {
  source = "./modules/waf"

  environment = var.environment
  tags        = local.common_tags
  alb_arn     = module.alb.alb_arn

  depends_on = [module.alb]
}

# Backup Module (Cross-Region backup to sa-east-1)
module "backup" {
  source = "./modules/backup"

  environment                 = var.environment
  tags                       = local.common_tags
  backup_kms_key_arn         = module.kms.backup_kms_key_arn
  cross_region_kms_key_arn   = module.kms.backup_kms_key_arn # Use same key for cross-region
  rds_instance_arns          = [module.rds.db_instance_arn]
  reports_s3_bucket          = "tf-nh"

  providers = {
    aws.sa_east_1 = aws.sa_east_1
  }

  depends_on = [
    module.kms,
    module.rds
  ]
}
