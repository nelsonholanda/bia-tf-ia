# 🏗️ BIA Infrastructure - Guia Técnico Completo

## 📋 Visão Geral

Este projeto implementa a infraestrutura completa para a aplicação BIA usando Terraform, incluindo AWS Backup cross-region, security scanning automatizado e práticas GitOps.

## 🚀 Quick Start

### Pré-requisitos
- Terraform >= 1.12.2
- AWS CLI configurado
- Credenciais AWS com permissões adequadas

### Deploy Rápido
```bash
# Ambiente de desenvolvimento
terraform init -backend-config=backend-dev.hcl
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars

# Ambiente de produção
terraform init -backend-config=backend-prod.hcl
terraform plan -var-file=terraform-prod.tfvars
terraform apply -var-file=terraform-prod.tfvars
```

## 🏗️ Arquitetura

### Componentes Principais
- **VPC**: Rede privada com subnets públicas e privadas
- **ECS**: Container orchestration com Auto Scaling
- **RDS**: PostgreSQL com encryption e backup automático
- **ALB**: Application Load Balancer com SSL/TLS
- **WAF**: Web Application Firewall para proteção
- **KMS**: Encryption keys para todos os serviços
- **CloudWatch**: Logs, métricas e alarmes
- **Backup**: Cross-region backup (us-east-1 → sa-east-1)

### Fluxo de Dados
```
Internet → ALB → ECS Tasks → RDS
            ↓
        CloudWatch Logs
            ↓
        AWS Backup → Cross-Region (sa-east-1)
```

## 🔄 AWS Backup Cross-Region

### Configuração
- **Região Principal**: us-east-1
- **Região Backup**: sa-east-1
- **Frequência**: Daily (3 AM UTC) + Weekly (Sunday 5 AM UTC)
- **Retenção**: 30 dias (principal) → 90 dias (cross-region)

### Recursos Incluídos
- RDS instance (tagged com `BackupEnabled=true`)
- Criptografia com KMS keys dedicadas
- Monitoramento via CloudWatch

## 🔒 Security & Compliance

### Security Scanning Pipeline
O projeto inclui scanning automatizado com:
- **tfsec**: Terraform security issues
- **Checkov**: Policy compliance
- **Gitleaks**: Secret detection
- **Snyk**: Dependency vulnerabilities

### Triggers
- Push para branches main/prod/dev
- Pull requests
- Daily scan (6 AM UTC)

### Pre-commit Hooks
```bash
# Instalar
pip install pre-commit
pre-commit install

# Executar
pre-commit run --all-files
```

## 📁 Estrutura do Projeto

```
.
├── main.tf                 # Configuração principal
├── variables.tf            # Variáveis do projeto
├── outputs.tf             # Outputs principais
├── locals.tf              # Valores locais
├── backend-{env}.hcl      # Configuração do backend S3
├── terraform-{env}.tfvars # Variáveis por ambiente
├── deploy.sh              # Script de deploy
├── .pre-commit-config.yaml # Hooks de qualidade
├── .terraform-docs.yml    # Config documentação
├── .github/workflows/     # CI/CD pipelines
│   ├── security-scan.yml  # Security scanning
│   ├── terraform-apply.yml # Deploy automation
│   ├── deploy-dev.yml     # Deploy desenvolvimento
│   ├── deploy-prod.yml    # Deploy produção
│   ├── destroy-dev.yml    # Destroy desenvolvimento
│   └── destroy-prod.yml   # Destroy produção
└── modules/               # Módulos Terraform
    ├── alb/              # Application Load Balancer
    ├── backup/           # AWS Backup cross-region
    ├── cloudwatch/       # Logs e monitoring
    ├── ecs-cluster/      # ECS cluster
    ├── ecs-service/      # ECS service
    ├── iam/              # IAM roles e policies
    ├── kms/              # KMS keys
    ├── rds/              # PostgreSQL database
    ├── security-groups/  # Security groups
    ├── vpc/              # Virtual Private Cloud
    └── waf/              # Web Application Firewall
```

## ⚙️ Configuração por Ambiente

### Desenvolvimento (dev)
- **Instance Type**: t3.micro
- **Multi-AZ**: false
- **Backup**: 7 dias
- **Auto-scaling**: 1-2 instances

### Produção (prod)
- **Instance Type**: t3.small
- **Multi-AZ**: true
- **Backup**: 30 dias + cross-region
- **Auto-scaling**: 2-5 instances
- **Encryption**: All resources
- **Manual approval**: Required para deploy

## 🔧 Modificações Comuns

### 1. Alterar Configuração de Backup
```hcl
# modules/backup/variables.tf
variable "backup_retention_days" {
  default = 30  # Altere aqui
}
```

### 2. Modificar Auto-scaling
```hcl
# terraform-{env}.tfvars
instance_min_capacity = 1
instance_max_capacity = 3
instance_desired_capacity = 2
```

### 3. Adicionar Nova Variável
```hcl
# variables.tf
variable "nova_variavel" {
  description = "Descrição da variável"
  type        = string
  default     = "valor_padrao"
}

# terraform-{env}.tfvars
nova_variavel = "valor_ambiente"
```

### 4. Criar Novo Módulo
```bash
mkdir modules/novo-modulo
cd modules/novo-modulo

# Criar arquivos base
touch main.tf variables.tf outputs.tf

# Adicionar ao main.tf principal
module "novo_modulo" {
  source = "./modules/novo-modulo"
  # configurações...
}
```

## 🚨 Troubleshooting

### Problemas Comuns

#### 1. Backend S3 não encontrado
```bash
# Verificar se bucket existe
aws s3 ls s3://tf-nh

# Criar se necessário
aws s3 mb s3://tf-nh
```

#### 2. Erro de credenciais
```bash
# Verificar credenciais
aws sts get-caller-identity

# Configurar se necessário
aws configure
```

#### 3. State lock
```bash
# Verificar locks ativos (S3 object locking)
aws s3api head-object --bucket tf-nh --key bia-prod/terraform.tfstate

# Force unlock (CUIDADO!)
terraform force-unlock <LOCK_ID>

# Verificar configuração do bucket
aws s3api get-object-lock-configuration --bucket tf-nh
```

#### 4. Backup falhou
```bash
# Verificar backup jobs
aws backup list-backup-jobs --region us-east-1

# Verificar logs
aws logs describe-log-groups --log-group-name-prefix "/aws/backup"
```

## 📊 Custos Estimados (Mensal)

| Serviço | Dev | Prod | Descrição |
|---------|-----|------|-----------|
| **ECS** | $10 | $25 | Container runtime |
| **RDS** | $15 | $45 | PostgreSQL database |
| **ALB** | $18 | $18 | Load balancer |
| **Backup** | $2 | $15 | Cross-region backup |
| **Other** | $5 | $15 | CloudWatch, KMS, etc |
| **Total** | **$50** | **$118** | Estimativa mensal |

## 🔐 Secrets Management

### AWS Secrets Manager
- Database credentials: `bia-{env}-secrets`
- Auto-rotation: Configurado para RDS
- KMS encryption: Chaves dedicadas por ambiente

### Variáveis Sensíveis
```bash
# Nunca commitar secrets
# Usar terraform.tfvars (local) ou
# AWS Secrets Manager / Parameter Store
```

## 📈 Monitoramento

### CloudWatch Alarms
- CPU utilization > 70%
- Database connections > 80%
- Backup failures
- Health check failures

### Logs
- ECS task logs: `/aws/ecs/bia-{env}`
- ALB access logs: S3 bucket
- Backup logs: `/aws/backup/{env}`

## 🔄 CI/CD Pipeline

### GitHub Actions
- **security-scan.yml**: Security scanning contínuo
- **terraform-apply.yml**: Deploy automatizado
- **deploy-{env}.yml**: Deploy específico por ambiente
- **destroy-{env}.yml**: Destroy resources

### Secrets Necessários
```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
INFRACOST_API_KEY (opcional)
SNYK_TOKEN (opcional)
```

## 📝 Desenvolvimento

### Workflow
1. **Fork/Clone** do repositório
2. **Criar branch** para feature
3. **Modificar** código
4. **Testar** localmente
5. **Commit** com pre-commit hooks
6. **Push** para trigger CI/CD
7. **Pull Request** para review
8. **Merge** após aprovação

### Best Practices
- Use semantic commits (feat:, fix:, docs:)
- Teste em ambiente dev primeiro
- Execute pre-commit hooks
- Mantenha documentação atualizada
- Use terraform fmt antes de commit

## 🆘 Suporte

### Contatos
- **Infra Team**: Nelson Holanda
- **Repository**: https://github.com/nelsonholanda/bia-tf-ia

### Logs Úteis
```bash
# Terraform debug
export TF_LOG=DEBUG
terraform plan

# AWS CLI debug
aws --debug s3 ls

# Pre-commit debug
pre-commit run --all-files --verbose
```

---

**Última atualização**: Janeiro 2025  
**Versão**: 3.0.0  
**Status**: ✅ Produção Ready
