# Local values for environment-specific configurations
locals {
  environment = var.environment

  # Environment-specific configurations
  env_config = {
    dev = {
      instance_type           = "t3.micro"
      rds_instance_class      = "db.t3.micro"
      container_cpu           = 1024
      container_memory        = 307
      multi_az                = false
      backup_retention_period = 1
      # ECS Tasks Auto Scaling
      task_min_capacity      = 1
      task_max_capacity      = 10
      task_desired_capacity  = 1
      cpu_scale_target       = 70.0
      cpu_scale_out_cooldown = 300
      cpu_scale_in_cooldown  = 600
      # EC2 Instances Auto Scaling
      instance_min_capacity     = 1
      instance_max_capacity     = 4
      instance_desired_capacity = 1
      use_private_subnets       = false
      create_nat_gateway        = false
    }
    prod = {
      instance_type           = "t3.micro"    # Upgraded for production
      rds_instance_class      = "db.t3.micro" # Upgraded for production
      container_cpu           = 1024
      container_memory        = 307  # Increased for production
      multi_az                = true # High availability for production
      backup_retention_period = 30   # Extended backup retention
      # ECS Tasks Auto Scaling - Conservative for production
      task_min_capacity      = 1    # Minimum 1 task for cost optimization
      task_max_capacity      = 20   # Higher max for production load
      task_desired_capacity  = 1    # Start with 1 task
      cpu_scale_target       = 60.0 # Lower threshold for faster scaling
      cpu_scale_out_cooldown = 600  # Longer cooldown for stability
      cpu_scale_in_cooldown  = 900  # Even longer for scale-in
      # EC2 Instances Auto Scaling
      instance_min_capacity     = 1 # Minimum 1 instance for cost optimization
      instance_max_capacity     = 4 # Higher max for production
      instance_desired_capacity = 1 # Start with 1 instance
      use_private_subnets       = true
      create_nat_gateway        = true
      # Production-specific settings
      enable_container_insights   = true
      enable_deletion_protection  = true
      enable_final_snapshot       = true
      log_retention_days          = 30
      enable_performance_insights = true
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
    CostCenter  = "Engineering"
    Application = "BIA"
    Backup      = var.environment == "prod" ? "Required" : "Optional"
    Compliance  = var.environment == "prod" ? "SOC2" : "Development"
    DataClass   = var.environment == "prod" ? "Confidential" : "Internal"
  }

  # Environment-specific naming
  name_prefix = "bia-${var.environment}"
}
