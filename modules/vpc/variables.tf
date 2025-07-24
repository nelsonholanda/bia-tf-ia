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

variable "vpc_id" {
  description = "VPC ID to import (opcional)"
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "Public subnet IDs to import (opcional)"
  type        = list(string)
  default     = []
}

variable "private_subnet_ids" {
  description = "Private subnet IDs to import (opcional)"
  type        = list(string)
  default     = []
}