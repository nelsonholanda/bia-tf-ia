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
      backup_retention_period = 7
      # Backup configuration
      backup_window            = "03:00-04:00"         # UTC - 11PM-12AM EST
      maintenance_window       = "sun:04:00-sun:05:00" # UTC - Sunday 12AM-1AM EST
      copy_tags_to_snapshot    = true
      delete_automated_backups = true
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
      # Backup configuration
      backup_window            = "03:00-04:00"         # UTC - 11PM-12AM EST
      maintenance_window       = "sun:04:00-sun:05:00" # UTC - Sunday 12AM-1AM EST
      copy_tags_to_snapshot    = true
      delete_automated_backups = true
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
      enable_deletion_protection  = false # Disabled for easier management
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

  # Environment-specific naming convention
  resource_name_prefix = "bia-${var.environment}"

  # Standardized resource naming following terraform-best-practices.com
  naming = {
    # Network resources
    vpc                 = "${local.resource_name_prefix}-vpc"
    internet_gateway    = "${local.resource_name_prefix}-igw"
    nat_gateway         = "${local.resource_name_prefix}-nat"
    route_table_public  = "${local.resource_name_prefix}-rt-public"
    route_table_private = "${local.resource_name_prefix}-rt-private"

    # Compute resources
    ecs_cluster         = "${local.resource_name_prefix}-cluster"
    ecs_service         = "${local.resource_name_prefix}-service"
    ecs_task_definition = "${local.resource_name_prefix}-task"
    auto_scaling_group  = "${local.resource_name_prefix}-asg"
    launch_template     = "${local.resource_name_prefix}-lt"

    # Load balancing
    application_load_balancer = "${local.resource_name_prefix}-alb"
    target_group              = "${local.resource_name_prefix}-tg"

    # Database
    rds_instance        = "${local.resource_name_prefix}-db"
    rds_subnet_group    = "${local.resource_name_prefix}-db-subnet-group"
    rds_parameter_group = "${local.resource_name_prefix}-db-params"

    # Security
    security_group_alb = "${local.resource_name_prefix}-sg-alb"
    security_group_ecs = "${local.resource_name_prefix}-sg-ecs"
    security_group_rds = "${local.resource_name_prefix}-sg-rds"
    waf_web_acl        = "${local.resource_name_prefix}-waf"

    # Storage & Backup
    s3_bucket_backup = "${local.resource_name_prefix}-backup"
    backup_vault     = "${local.resource_name_prefix}-vault"
    backup_plan      = "${local.resource_name_prefix}-plan"

    # Monitoring & Logging
    cloudwatch_log_group = "/aws/ecs/${local.resource_name_prefix}"
    cloudwatch_alarm     = "${local.resource_name_prefix}-alarm"

    # IAM
    iam_role_ecs_task_execution = "${local.resource_name_prefix}-ecs-task-execution-role"
    iam_role_ecs_instance       = "${local.resource_name_prefix}-ecs-instance-role"
    iam_role_backup             = "${local.resource_name_prefix}-backup-role"

    # KMS
    kms_key_rds     = "${local.resource_name_prefix}-kms-rds"
    kms_key_secrets = "${local.resource_name_prefix}-kms-secrets"
    kms_key_backup  = "${local.resource_name_prefix}-kms-backup"

    # Secrets
    secret_rds_password = "${local.resource_name_prefix}-rds-password"
  }
}
