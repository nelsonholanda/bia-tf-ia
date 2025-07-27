variable "environment" {
  description = "Environment name (dev or prod)"
  type        = string
}

variable "tags" {
  description = "Tags to be applied to resources"
  type        = map(string)
  default     = {}
}

variable "alb_arn" {
  description = "ARN of the Application Load Balancer"
  type        = string
}