# Data sources for RDS module

# Check for existing secrets that might conflict
data "aws_secretsmanager_secrets" "existing" {
  filter {
    name   = "name"
    values = ["bia-${var.environment}-secrets"]
  }
}

# Get current AWS account and region info
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}