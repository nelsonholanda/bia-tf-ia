locals {
  environment = var.environment

  env_config = {
    dev = {
      instance_type             = "t3.micro"
      rds_instance_class        = "db.t3.micro"
      container_cpu             = 1024
      container_memory          = 307
      multi_az                  = false
      backup_retention_period   = 7
      backup_window             = "03:00-04:00"
      maintenance_window        = "sun:04:00-sun:05:00"
      copy_tags_to_snapshot     = true
      delete_automated_backups  = true
      task_min_capacity         = 1
      task_max_capacity         = 10
      task_desired_capacity     = 1
      cpu_scale_target          = 70.0
      cpu_scale_out_cooldown    = 300
      cpu_scale_in_cooldown     = 600
      instance_min_capacity     = 1
      instance_max_capacity     = 4
      instance_desired_capacity = 1
      use_private_subnets       = false
      create_nat_gateway        = false
    }
    prod = {
      instance_type               = "t3.micro"
      rds_instance_class          = "db.t3.micro"
      container_cpu               = 1024
      container_memory            = 307
      multi_az                    = true
      backup_retention_period     = 30
      backup_window               = "03:00-04:00"
      maintenance_window          = "sun:04:00-sun:05:00"
      copy_tags_to_snapshot       = true
      delete_automated_backups    = true
      task_min_capacity           = 1
      task_max_capacity           = 20
      task_desired_capacity       = 1
      cpu_scale_target            = 60.0
      cpu_scale_out_cooldown      = 600
      cpu_scale_in_cooldown       = 900
      instance_min_capacity       = 1
      instance_max_capacity       = 4
      instance_desired_capacity   = 1
      use_private_subnets         = true
      create_nat_gateway          = true
      enable_container_insights   = true
      enable_deletion_protection  = false
      enable_final_snapshot       = true
      log_retention_days          = 30
      enable_performance_insights = true
    }
  }

  current_env = local.env_config[local.environment]


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

  resource_name_prefix = "bia-${var.environment}"

  naming = {
    vpc                 = "${local.resource_name_prefix}-vpc"
    internet_gateway    = "${local.resource_name_prefix}-igw"
    nat_gateway         = "${local.resource_name_prefix}-nat"
    route_table_public  = "${local.resource_name_prefix}-rt-public"
    route_table_private = "${local.resource_name_prefix}-rt-private"

    ecs_cluster         = "${local.resource_name_prefix}-cluster"
    ecs_service         = "${local.resource_name_prefix}-service"
    ecs_task_definition = "${local.resource_name_prefix}-task"
    auto_scaling_group  = "${local.resource_name_prefix}-asg"
    launch_template     = "${local.resource_name_prefix}-lt"

    application_load_balancer = "${local.resource_name_prefix}-alb"
    target_group              = "${local.resource_name_prefix}-tg"

    rds_instance        = "${local.resource_name_prefix}-db"
    rds_subnet_group    = "${local.resource_name_prefix}-db-subnet-group"
    rds_parameter_group = "${local.resource_name_prefix}-db-params"

    security_group_alb = "${local.resource_name_prefix}-sg-alb"
    security_group_ecs = "${local.resource_name_prefix}-sg-ecs"
    security_group_rds = "${local.resource_name_prefix}-sg-rds"
    waf_web_acl        = "${local.resource_name_prefix}-waf"

    s3_bucket_backup = "${local.resource_name_prefix}-backup"
    backup_vault     = "${local.resource_name_prefix}-vault"
    backup_plan      = "${local.resource_name_prefix}-plan"

    cloudwatch_log_group = "/aws/ecs/${local.resource_name_prefix}"
    cloudwatch_alarm     = "${local.resource_name_prefix}-alarm"

    iam_role_ecs_task_execution = "${local.resource_name_prefix}-ecs-task-execution-role"
    iam_role_ecs_instance       = "${local.resource_name_prefix}-ecs-instance-role"
    iam_role_backup             = "${local.resource_name_prefix}-backup-role"

    kms_key_rds     = "${local.resource_name_prefix}-kms-rds"
    kms_key_secrets = "${local.resource_name_prefix}-kms-secrets"
    kms_key_backup  = "${local.resource_name_prefix}-kms-backup"

    secret_rds_password = "${local.resource_name_prefix}-rds-password"
  }
}
