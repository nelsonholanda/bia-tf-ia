# Project Structure

## Root Directory
- **main.tf**: Primary Terraform configuration with module calls
- **variables.tf**: Input variables with validation rules
- **outputs.tf**: Output values from infrastructure
- **locals.tf**: Environment-specific configurations and common tags
- **terraform.tfvars**: Development environment variables
- **terraform-prod.tfvars**: Production environment variables
- **terraform.tfvars.example**: Template for variable configuration

## Backend Configuration
- **backend-dev.hcl**: S3 backend config for development
- **backend-prod.hcl**: S3 backend config for production

## Deployment
- **deploy.sh**: Main deployment script with environment handling
- **.terraform.lock.hcl**: Provider version locks

## Modules Directory Structure
Each module follows consistent organization:
```
modules/<service>/
├── main.tf      # Resource definitions
├── variables.tf # Module input variables
├── outputs.tf   # Module outputs
└── data.tf      # Data sources (when needed)
```

### Available Modules
- **alb/**: Application Load Balancer configuration
- **cloudwatch/**: Logging and monitoring setup
- **ecs-cluster/**: ECS cluster with capacity providers
- **ecs-service/**: ECS service, task definition, and auto-scaling
- **iam/**: IAM roles and policies
- **kms/**: KMS keys for encryption (production)
- **rds/**: PostgreSQL database with secrets management
- **security-groups/**: Network security rules
- **vpc/**: Virtual Private Cloud with subnets and routing
- **waf/**: Web Application Firewall (production)

## Environment Configuration Pattern
- Environment-specific settings defined in `locals.tf`
- Two-tier configuration: `dev` and `prod`
- Resource sizing and features vary by environment
- Common tagging strategy applied across all resources

## Naming Conventions
- Resources: `bia-{environment}-{service}`
- Tags: Consistent across all resources with environment-specific values
- Modules: Lowercase with hyphens for separation
- Variables: Snake_case with descriptive names

## File Organization Rules
- Keep root files focused on orchestration
- Module files contain implementation details
- Environment configs centralized in locals.tf
- Secrets handled through AWS Secrets Manager
- No hardcoded values in Terraform files