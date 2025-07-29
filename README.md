# BIA - HCP Terraform Cloud

Infraestrutura BIA rodando exclusivamente no **HCP Terraform Cloud**.

## 🚀 Setup

### 1. Configurar Variáveis no HCP Terraform

**Workspace**: https://app.terraform.io/app/SevenCl0ud/workspaces/SevenCloud_Challange/variables

**Environment Variables** (sensitive):
```
AWS_ACCESS_KEY_ID = sua-access-key
AWS_SECRET_ACCESS_KEY = sua-secret-key
AWS_DEFAULT_REGION = us-east-1
```

**Terraform Variables**:
```
environment = "dev"
cluster_name = "bia-dev-cluster"
service_name = "bia-dev-service"
task_definition_family = "bia-dev-task"
log_group_name = "/ecs/bia-dev"
aws_region = "us-east-1"
postgres_version = "15.8"
key_name = "nholanda"
```

### 2. Deploy

**Via HCP UI**: https://app.terraform.io/app/SevenCl0ud/workspaces/SevenCloud_Challange
- Actions → Start new plan → Confirm & Apply

**Via CLI**:
```bash
terraform plan
terraform apply
```

## � Dev/Prod

Para alternar entre ambientes, mude apenas:
- `environment` = "dev" ou "prod"
- `cluster_name` = "bia-dev-cluster" ou "bia-prod-cluster"
- `service_name` = "bia-dev-service" ou "bia-prod-service"
- `task_definition_family` = "bia-dev-task" ou "bia-prod-task"
- `log_group_name` = "/ecs/bia-dev" ou "/ecs/bia-prod"

## 🏗️ Arquitetura

- **VPC** com subnets públicas/privadas
- **ECS Cluster** com Auto Scaling
- **Application Load Balancer**
- **RDS PostgreSQL**
- **Security Groups**
- **CloudWatch Logs**
- **KMS + WAF** (apenas prod)

## 📋 Variáveis Obrigatórias

| Variável | Tipo | Exemplo |
|----------|------|---------|
| `AWS_ACCESS_KEY_ID` | Environment (sensitive) | `AKIA...` |
| `AWS_SECRET_ACCESS_KEY` | Environment (sensitive) | `xyz...` |
| `AWS_DEFAULT_REGION` | Environment | `us-east-1` |
| `environment` | Terraform | `dev` |
| `cluster_name` | Terraform | `bia-dev-cluster` |