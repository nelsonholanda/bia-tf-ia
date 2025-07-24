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
      min_capacity              = 1
      max_capacity              = 10
      desired_capacity          = 1
      memory_scale_target       = 80.0
      memory_scale_out_cooldown = 300
      memory_scale_in_cooldown  = 600
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
      min_capacity              = 1
      max_capacity              = 10
      desired_capacity          = 1
      memory_scale_target       = 75.0
      memory_scale_out_cooldown = 300
      memory_scale_in_cooldown  = 600
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