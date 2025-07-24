variable "environment" {
  description = "Environment name (dev or prod)"
  type        = string
}

variable "tags" {
  description = "Tags to be applied to resources"
  type        = map(string)
  default     = {}
}

variable "cluster_name" {
  description = "ECS cluster name"
  type        = string
}