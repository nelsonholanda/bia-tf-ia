# IAM Module for ECS

# ECS Task Execution Role
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "bia-${var.environment}-ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags

  lifecycle {
    prevent_destroy = false
  }
}

# Attach AWS managed policy for ECS task execution
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Instance Role
resource "aws_iam_role" "ecs_instance_role" {
  name = "bia-${var.environment}-ecsInstanceRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags

  lifecycle {
    prevent_destroy = false
  }
}

# Attach AWS managed policy for ECS instance
resource "aws_iam_role_policy_attachment" "ecs_instance_role_policy" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# Attach AWS managed policy for SSM (Systems Manager)
resource "aws_iam_role_policy_attachment" "ecs_instance_ssm_policy" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Custom policy for Parameter Store and Secrets Manager access
resource "aws_iam_policy" "ecs_secrets_policy" {
  name        = "bia-${var.environment}-ecs-secrets-policy"
  description = "Policy for ECS tasks to access Parameter Store and Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = [
          "arn:aws:ssm:*:*:parameter/bia/${var.environment}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          "arn:aws:secretsmanager:*:*:secret:bia/${var.environment}/*"
        ]
      }
    ]
  })

  tags = var.tags
}

# Attach custom policy to ECS task execution role
resource "aws_iam_role_policy_attachment" "ecs_task_execution_secrets_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_secrets_policy.arn
}

# ECS Instance Profile
resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "bia-${var.environment}-ecsInstanceProfile"
  role = aws_iam_role.ecs_instance_role.name

  tags = var.tags

  lifecycle {
    prevent_destroy = false
  }
}
