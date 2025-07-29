# Local values for environment-specific configurations
locals {
  environment = var.environment

  # Environment-specific configurations
  env_config = {
    dev = {
      # Network Configuration
      vpc_cidr           = "10.0.0.0/16"
      availability_zones = 3
      # Instance Configuration
      instance_type           = "t3.micro"
      rds_instance_class      = "db.t3.micro"
      container_cpu           = 1024
      container_memory        = 512 # Increased for better performance
      multi_az                = false
      backup_retention_period = 7 # Increased from 1 day
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
      # Development-specific settings
      enable_container_insights   = true # Now enabled for dev too
      enable_deletion_protection  = false
      enable_final_snapshot       = false
      log_retention_days          = 7
      enable_performance_insights = false
      # Cost optimization
      enable_spot_instances    = true
      spot_allocation_strategy = "diversified"
    }
    prod = {
      # Network Configuration
      vpc_cidr           = "10.1.0.0/16" # Different CIDR for prod
      availability_zones = 3
      # Instance Configuration
      instance_type           = "t3.small"    # Upgraded for production
      rds_instance_class      = "db.t3.small" # Upgraded for production
      container_cpu           = 1024
      container_memory        = 1024 # Increased for production
      multi_az                = true # High availability for production
      backup_retention_period = 30   # Extended backup retention
      # ECS Tasks Auto Scaling - Conservative for production
      task_min_capacity      = 2    # Minimum 2 tasks for HA
      task_max_capacity      = 20   # Higher max for production load
      task_desired_capacity  = 2    # Start with 2 tasks for HA
      cpu_scale_target       = 60.0 # Lower threshold for faster scaling
      cpu_scale_out_cooldown = 600  # Longer cooldown for stability
      cpu_scale_in_cooldown  = 900  # Even longer for scale-in
      # EC2 Instances Auto Scaling
      instance_min_capacity     = 2 # Minimum 2 instances for HA
      instance_max_capacity     = 6 # Higher max for production
      instance_desired_capacity = 2 # Start with 2 instances for HA
      use_private_subnets       = true
      create_nat_gateway        = true
      # Production-specific settings
      enable_container_insights   = true
      enable_deletion_protection  = false # Disabled for easier management
      enable_final_snapshot       = true
      log_retention_days          = 30
      enable_performance_insights = true
      # Security enhancements
      enable_waf       = true
      enable_guardduty = true
      enable_config    = true
      # Backup settings
      enable_backup              = true
      backup_retention_days      = 365
      enable_cross_region_backup = true
      # Cost optimization disabled for prod
      enable_spot_instances = false
    }
  }

  # Current environment configuration
  current_env = local.env_config[local.environment]

  # Network calculations
  public_subnet_cidrs = [
    for i in range(local.current_env.availability_zones) :
    cidrsubnet(local.current_env.vpc_cidr, 8, i)
  ]

  private_subnet_cidrs = [
    for i in range(local.current_env.availability_zones) :
    cidrsubnet(local.current_env.vpc_cidr, 8, i + 10)
  ]

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
    # Additional production tags
    BusinessUnit      = var.environment == "prod" ? "Production" : "Development"
    MaintenanceWindow = var.environment == "prod" ? "Sunday-02:00-04:00" : "Anytime"
    MonitoringLevel   = var.environment == "prod" ? "Critical" : "Standard"
  }

  # Environment-specific naming
  name_prefix = "bia-${var.environment}"

  # Monitoring configuration
  monitoring_config = {
    cpu_alarm_threshold        = var.environment == "prod" ? 70 : 80
    memory_alarm_threshold     = var.environment == "prod" ? 80 : 85
    disk_alarm_threshold       = var.environment == "prod" ? 80 : 90
    enable_detailed_monitoring = var.environment == "prod" ? true : false
  }
}
