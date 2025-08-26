resource "aws_ecs_task_definition" "main" {
  family                   = "bia-${var.environment}-task"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  execution_role_arn       = var.task_execution_role_arn

  container_definitions = jsonencode([
    {
      name              = var.container_name
      image             = var.container_image
      cpu               = var.environment == "dev" ? 512 : 1024
      memoryReservation = var.environment == "dev" ? 307 : 512
      essential         = true

      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = 0
          protocol      = "tcp"
          name          = "porta-${var.container_port}"
          appProtocol   = "http"
        }
      ]

      secrets = [
        {
          name      = "DB_HOST"
          valueFrom = "${var.db_password_secret_arn}:host::"
        },
        {
          name      = "DB_PORT"
          valueFrom = "${var.db_password_secret_arn}:port::"
        },
        {
          name      = "DB_USER"
          valueFrom = "${var.db_password_secret_arn}:username::"
        },
        {
          name      = "DB_PWD"
          valueFrom = "${var.db_password_secret_arn}:password::"
        },
        {
          name      = "DB_NAME"
          valueFrom = "${var.db_password_secret_arn}:dbname::"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = var.log_group_name
          "awslogs-create-group"  = "true"
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }

  tags = var.tags

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_ecs_service" "main" {
  name            = "bia-${var.environment}-service"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = var.env_config.task_desired_capacity

  capacity_provider_strategy {
    capacity_provider = var.capacity_provider_name
    weight            = 1
    base              = 0
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  enable_execute_command = false

  tags = var.tags

  depends_on = [var.target_group_arn]

  lifecycle {
    prevent_destroy       = false
    create_before_destroy = false
  }
}

resource "aws_appautoscaling_target" "ecs_tasks_target" {
  max_capacity       = var.env_config.task_max_capacity
  min_capacity       = var.env_config.task_min_capacity
  resource_id        = "service/bia-${var.environment}-cluster/bia-${var.environment}-service"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  depends_on = [aws_ecs_service.main]

  lifecycle {
    prevent_destroy       = false
    create_before_destroy = false
  }
}

resource "aws_appautoscaling_policy" "ecs_cpu_policy" {
  name               = "bia-${var.environment}-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_tasks_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_tasks_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_tasks_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.env_config.cpu_scale_target
    scale_out_cooldown = var.env_config.cpu_scale_out_cooldown
    scale_in_cooldown  = var.env_config.cpu_scale_in_cooldown
  }

  depends_on = [aws_appautoscaling_target.ecs_tasks_target]
}

