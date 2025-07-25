variable "environment" {
  description = "Environment name (dev or prod)"
  type        = string
}

variable "tags" {
  description = "Tags to be applied to resources"
  type        = map(string)
  default     = {}
}

variable "env_config" {
  description = "Environment-specific configuration"
  type        = any
}

variable "cluster_id" {
  description = "ECS cluster ID"
  type        = string
}

variable "service_name" {
  description = "ECS service name"
  type        = string
}

variable "task_definition_family" {
  description = "Task definition family name"
  type        = string
}

variable "container_name" {
  description = "Container name"
  type        = string
}

variable "container_image" {
  description = "Container image URL"
  type        = string
}

variable "container_cpu" {
  description = "Container CPU units (will be overridden by env_config)"
  type        = number
}

variable "container_memory_reservation" {
  description = "Container memory reservation in MB (will be overridden by env_config)"
  type        = number
}

variable "container_port" {
  description = "Container port"
  type        = number
}

variable "log_group_name" {
  description = "CloudWatch log group name"
  type        = string
}

variable "task_execution_role_arn" {
  description = "Task execution role ARN"
  type        = string
}

variable "capacity_provider_name" {
  description = "ECS capacity provider name"
  type        = string
}

variable "target_group_arn" {
  description = "ALB target group ARN"
  type        = string
}

variable "parameter_store_paths" {
  description = "Parameter Store paths for database configuration"
  type = object({
    rds_endpoint = string
    db_port      = string
    db_user      = string
  })
}

variable "db_password_secret_arn" {
  description = "ARN of the database password secret in Secrets Manager"
  type        = string
}

variable "cluster_name" {
  description = "ECS cluster name (for auto scaling resource ID)"
  type        = string
}

