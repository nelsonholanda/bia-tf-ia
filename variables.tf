# Variables for BIA ECS Infrastructure

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
  description = "AWS region"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "AWS region must be in the format 'us-east-1'."
  }
}

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

variable "app_container_name" {
  description = "Name of the application container"
  type        = string
  default     = "bia"
}

variable "app_container_cpu" {
  description = "CPU units allocated to the container (overridden by environment config)"
  type        = number
  default     = 512
}

variable "app_container_memory_reservation" {
  description = "Memory reservation in MB for the container (overridden by environment config)"
  type        = number
  default     = 307
}

variable "app_container_port" {
  description = "Port exposed by the application container"
  type        = number
  default     = 8080
}

variable "ecr_repository_url" {
  description = "URL of the ECR repository containing the application image"
  type        = string
  default     = "194722426008.dkr.ecr.us-east-1.amazonaws.com/bia"
}

variable "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for application logs"
  type        = string
  default     = "/ecs/bia"
}

variable "ec2_key_pair_name" {
  description = "Name of the EC2 key pair for instance access"
  type        = string
  default     = "nholanda"
}

