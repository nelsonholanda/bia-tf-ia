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

variable "cluster_name" {
  description = "ECS cluster name"
  type        = string
  default     = "bia-cluster"
}

variable "service_name" {
  description = "ECS service name"
  type        = string
  default     = "bia-service"
}

variable "task_definition_family" {
  description = "Task definition family name"
  type        = string
  default     = "bia-task"
}

variable "container_name" {
  description = "Container name"
  type        = string
  default     = "bia"
}

variable "container_cpu" {
  description = "Container CPU units (will be overridden by environment config)"
  type        = number
  default     = 512
}

variable "container_memory_reservation" {
  description = "Container memory reservation in MB (will be overridden by environment config)"
  type        = number
  default     = 307
}

variable "container_port" {
  description = "Container port"
  type        = number
  default     = 8080
}

variable "ecr_repository_url" {
  description = "ECR repository URL (external, not managed by Terraform)"
  type        = string
  default     = "194722426008.dkr.ecr.us-east-1.amazonaws.com/bia"
}

variable "log_group_name" {
  description = "CloudWatch log group name"
  type        = string
  default     = "/ecs/bia"
}

variable "key_name" {
  description = "EC2 Key Pair name"
  type        = string
  default     = "nholanda"
}

