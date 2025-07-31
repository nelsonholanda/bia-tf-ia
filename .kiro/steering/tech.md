# Technology Stack

## Infrastructure as Code
- **Terraform**: Version >= 1.0 with AWS provider ~> 6.5.0
- **Backend**: S3 with object locking (no DynamoDB required)
- **State management**: Environment-specific backends (`backend-dev.hcl`, `backend-prod.hcl`)

## AWS Services
- **Compute**: ECS with EC2 capacity providers
- **Database**: RDS PostgreSQL with automated backups (7 days dev, 30 days prod)
- **Networking**: VPC with public/private subnets, ALB, NAT Gateway (prod only)
- **Security**: WAF (prod), KMS encryption (prod), Secrets Manager, Security Groups
- **Monitoring**: CloudWatch Logs, CloudWatch Metrics, Container Insights (prod)
- **Storage**: S3 for Terraform state
- **Backup**: Daily automated backups with point-in-time recovery

## Common Commands

### Deployment
```bash
# Development environment
./deploy.sh dev plan
./deploy.sh dev apply
./deploy.sh dev destroy

# Production environment  
./deploy.sh prod plan
./deploy.sh prod apply
./deploy.sh prod destroy
```

### Manual Terraform Operations
```bash
# Initialize with specific backend
terraform init -backend-config=backend-dev.hcl
terraform init -backend-config=backend-prod.hcl

# Plan with environment variables
terraform plan -var="environment=dev"
terraform plan -var-file=terraform-prod.tfvars

# Apply with auto-approve
terraform apply -var="environment=dev" -auto-approve
terraform apply -var-file=terraform-prod.tfvars -auto-approve
```

### State Management
```bash
# List resources in state
terraform state list

# Force unlock if needed
terraform force-unlock <LOCK_ID>

# Import existing resources
terraform import <resource_type>.<name> <resource_id>
```

### AWS CLI Operations
```bash
# Check S3 bucket versioning
aws s3api get-bucket-versioning --bucket tf-nh

# Clean up orphaned secrets
aws secretsmanager list-secrets --include-planned-deletion
aws secretsmanager delete-secret --secret-id <ARN> --force-delete-without-recovery
```

## Build System
- **Deploy script**: `deploy.sh` handles environment switching and cleanup
- **Automatic cleanup**: Orphaned secrets are cleaned before deployment
- **Environment validation**: Script validates environment and action parameters
- **State locking**: Uses S3 object locking for concurrent access protection