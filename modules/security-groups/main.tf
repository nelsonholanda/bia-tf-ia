# Security Groups Module

# Security Group for ECS
resource "aws_security_group" "bia_dev" {
  name        = "bia-${var.environment}-ecs"
  description = "Security group for BIA ${var.environment} environment"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "bia-${var.environment}-ecs"
  })
}

# Security Group for RDS
resource "aws_security_group" "bia_rds" {
  name        = "bia-${var.environment}-rds"
  description = "Security group for BIA RDS database in ${var.environment}"
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL from ECS instances"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.bia_ec2.id]
  }

  # Remove egress rule - RDS doesn't need outbound access
  tags = merge(var.tags, {
    Name = "bia-${var.environment}-rds"
  })
}

# Security Group for ALB
resource "aws_security_group" "bia_alb" {
  name        = "bia-${var.environment}-alb"
  description = "Security group for BIA Application Load Balancer in ${var.environment}"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "bia-${var.environment}-alb"
  })
}

# Security Group for EC2 instances
resource "aws_security_group" "bia_ec2" {
  name        = "bia-${var.environment}-ec2"
  description = "Security group for BIA EC2 instances in ${var.environment}"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Dynamic ports from ALB"
    from_port       = 32768
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.bia_alb.id]
  }

  egress {
    description = "HTTPS to internet for ECR/S3"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "HTTP to internet for package updates"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "PostgreSQL to RDS"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["172.16.0.0/20"]  # VPC CIDR for prod
  }

  tags = merge(var.tags, {
    Name = "bia-${var.environment}-ec2"
  })
}