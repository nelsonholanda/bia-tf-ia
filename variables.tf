# Variables for BIA ECS Infrastructure
# Following terraform-best-practices.com naming conventions

# =============================================================================
# GENERAL CONFIGURATION
# =============================================================================

variable "environment" {
  description = "Environment name (dev or prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be either 'dev' or 'prod'."
  }
}

variable "aws_region" {
  description = "AWS region for primary resources"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "AWS region must be in the format 'us-east-1'."
  }
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "bia"
}

# =============================================================================
# ECS CONFIGURATION
# =============================================================================

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = "bia-cluster"
}

variable "ecs_service_name" {
  description = "Name of the ECS service"
  type        = string
  default     = "bia-service"
}

variable "ecs_task_definition_family" {
  description = "Family name for the ECS task definition"
  type        = string
  default     = "bia-task"
}

# =============================================================================
# APPLICATION CONFIGURATION
# =============================================================================

variable "app_container_name" {
  description = "Name of the application container"
  type        = string
  default     = "bia"
}

variable "app_container_cpu" {
  description = "CPU units allocated to the container (overridden by environment config)"
  type        = number
  default     = 512

  validation {
    condition     = var.app_container_cpu >= 256
    error_message = "Container CPU must be at least 256 units."
  }
}

variable "app_container_memory_reservation" {
  description = "Memory reservation in MB for the container (overridden by environment config)"
  type        = number
  default     = 307

  validation {
    condition     = var.app_container_memory_reservation >= 128
    error_message = "Container memory reservation must be at least 128 MB."
  }
}

variable "app_container_port" {
  description = "Port exposed by the application container"
  type        = number
  default     = 8080

  validation {
    condition     = var.app_container_port > 0 && var.app_container_port <= 65535
    error_message = "Container port must be between 1 and 65535."
  }
}

variable "ecr_repository_url" {
  description = "URL of the ECR repository containing the application image"
  type        = string
  default     = "194722426008.dkr.ecr.us-east-1.amazonaws.com/bia"

  validation {
    condition     = can(regex("^[0-9]+\\.dkr\\.ecr\\.[a-z0-9-]+\\.amazonaws\\.com/.+$", var.ecr_repository_url))
    error_message = "ECR repository URL must be in the correct format."
  }
}

# =============================================================================
# MONITORING & LOGGING
# =============================================================================

variable "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for application logs"
  type        = string
  default     = "/ecs/bia"

  validation {
    condition     = can(regex("^/[a-zA-Z0-9/_-]+$", var.cloudwatch_log_group_name))
    error_message = "CloudWatch log group name must start with '/' and contain valid characters."
  }
}

# =============================================================================
# INFRASTRUCTURE ACCESS
# =============================================================================

variable "ec2_key_pair_name" {
  description = "Name of the EC2 key pair for instance access"
  type        = string
  default     = "nholanda"

  validation {
    condition     = length(var.ec2_key_pair_name) > 0
    error_message = "EC2 key pair name cannot be empty."
  }
}

