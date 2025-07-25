# Local values for environment-specific configurations
locals {
  environment = var.environment

  # Environment-specific configurations
  env_config = {
    dev = {
      instance_type             = "t3.micro"
      rds_instance_class        = "db.t3.micro"
      container_cpu             = 1024
      container_memory          = 307
      multi_az                  = false
      backup_retention_period   = 1
      # ECS Tasks Auto Scaling
      task_min_capacity         = 1
      task_max_capacity         = 10
      task_desired_capacity     = 1
      cpu_scale_target          = 70.0
      cpu_scale_out_cooldown    = 300
      cpu_scale_in_cooldown     = 600
      # EC2 Instances Auto Scaling
      instance_min_capacity     = 1
      instance_max_capacity     = 4
      instance_desired_capacity = 1
      use_private_subnets       = false
      create_nat_gateway        = false
    }
    prod = {
      instance_type             = "t3.micro"
      rds_instance_class        = "db.t3.micro"
      container_cpu             = 1024
      container_memory          = 307
      multi_az                  = false
      backup_retention_period   = 7
      # ECS Tasks Auto Scaling
      task_min_capacity         = 1
      task_max_capacity         = 10
      task_desired_capacity     = 1
      cpu_scale_target          = 70.0
      cpu_scale_out_cooldown    = 300
      cpu_scale_in_cooldown     = 600
      # EC2 Instances Auto Scaling
      instance_min_capacity     = 1
      instance_max_capacity     = 4
      instance_desired_capacity = 1
      use_private_subnets       = true
      create_nat_gateway        = true
    }
  }

  # Current environment configuration
  current_env = local.env_config[local.environment]

  # Common tags applied to all resources
  common_tags = {
    Environment = var.environment
    Owner       = "Nelson Holanda"
    Project     = "BIA"
    ManagedBy   = "Terraform"
  }

  # Environment-specific naming
  name_prefix = "bia-${var.environment}"
}