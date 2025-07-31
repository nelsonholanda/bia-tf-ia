# 🚀 BIA - Infraestrutura Terraform

Infraestrutura como código para a aplicação BIA usando Terraform, com suporte a múltiplos ambientes (desenvolvimento e produção).

## 🏗️ Arquitetura

### Ambientes Suportados

| Componente | Desenvolvimento | Produção |
|------------|----------------|----------|
| **VPC CIDR** | 172.16.0.0/20 | 172.16.0.0/20 |
| **RDS Instance** | db.t3.micro | db.t3.small |
| **Multi-AZ** | ❌ Desabilitado | ✅ Habilitado |
| **WAF** | ❌ Desabilitado | ✅ Habilitado |
| **KMS** | ❌ Desabilitado | ✅ Habilitado |
| **Container Insights** | ❌ Desabilitado | ✅ Habilitado |
| **Backup Retention** | 7 dias | 30 dias |

## 📁 Estrutura do Projeto

```
bia-kiro-tf/
├── 📄 main.tf                       # Configuração principal
├── 📄 variables.tf                  # Variáveis do projeto
├── 📄 outputs.tf                    # Outputs do projeto
├── 📄 locals.tf                     # Configurações locais por ambiente
├── 📄 terraform.tfvars              # Variáveis para desenvolvimento
├── 📄 terraform-prod.tfvars         # Variáveis para produção
├── 📄 terraform.tfvars.example      # Exemplo de configuração
├── 📄 backend-dev.hcl               # Backend S3 para dev
├── 📄 backend-prod.hcl              # Backend S3 para prod
├── 🔧 deploy.sh                     # Script de deploy
├── 📄 ARCHITECTURE.md               # Documentação da arquitetura
├── 📄 MIGRATION-S3-LOCKING.md       # Documentação da migração S3
├── 📄 BACKUP-STRATEGY.md            # Estratégia de backup e recuperação

├── 📁 modules/                      # Módulos Terraform
│   ├── alb/                         # Application Load Balancer
│   ├── cloudwatch/                  # Logs e monitoramento
│   ├── ecs-cluster/                 # Cluster ECS
│   ├── ecs-service/                 # Serviços ECS
│   ├── iam/                         # Roles e políticas IAM
│   ├── kms/                         # Chaves de criptografia
│   ├── rds/                         # Banco de dados PostgreSQL
│   ├── security-groups/             # Grupos de segurança
│   ├── vpc/                         # Rede virtual
│   └── waf/                         # Web Application Firewall
└── 📁 .github/workflows/            # GitHub Actions
    ├── deploy-dev.yml               # Deploy manual dev
    └── deploy-prod.yml              # Deploy manual prod
```

## 🚀 Como Usar

### 1. Configuração Inicial

```bash
# Clonar o repositório
git clone <repository-url>
cd bia-kiro-tf

# Configurar AWS CLI
aws configure

# Verificar se o bucket S3 existe e tem versionamento habilitado
aws s3api get-bucket-versioning --bucket tf-nh
```

### 2. Deploy para Desenvolvimento

```bash
# Deploy para desenvolvimento (recomendado - com limpeza automática)
./deploy.sh dev apply

# Ou deploy manual (se necessário)
terraform init -backend-config=backend-dev.hcl
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

### 3. Deploy para Produção

```bash
# Deploy para produção (recomendado - com limpeza automática)
./deploy.sh prod apply

# Ou deploy manual (se necessário)
terraform init -backend-config=backend-prod.hcl
terraform plan -var-file=terraform-prod.tfvars
terraform apply -var-file=terraform-prod.tfvars
```

## 🔧 Configuração

### Variáveis de Ambiente

As principais configurações são definidas em `locals.tf`:

```hcl
# Desenvolvimento
dev = {
  container_memory        = 256
  multi_az                = false
  backup_retention_period = 1
  task_min_capacity      = 1
  task_max_capacity      = 3
}

# Produção
prod = {
  container_memory        = 307
  multi_az                = true
  backup_retention_period = 30
  task_min_capacity      = 1
  task_max_capacity      = 20
}
```

### Backend Configuration

O projeto usa S3 para armazenar o state do Terraform com S3 object locking para controle de concorrência:

- **Desenvolvimento**: `backend-dev.hcl`
- **Produção**: `backend-prod.hcl`

### State Locking

O projeto utiliza S3 object locking nativo, eliminando a necessidade de DynamoDB:

- **Bucket**: `tf-nh`
- **Dev State**: `kiro-tf-bia/dev/terraform.tfstate`
- **Prod State**: `kiro-tf-bia/prod/terraform.tfstate`

**Benefícios da migração para S3-only:**
- ✅ Redução de custos (sem DynamoDB)
- ✅ Simplificação da infraestrutura
- ✅ Locking nativo do S3
- ✅ Menor complexidade de configuração

## 🏷️ Tags Padrão

Todos os recursos são taggeados automaticamente:

```hcl
tags = {
  Project      = "BIA"
  Owner        = "Nelson Holanda"
  ManagedBy    = "Terraform"
  Environment  = var.environment
  CostCenter   = "Engineering"
  Application  = "BIA"
  Backup       = "Required" (prod only)
  Compliance   = "SOC2" (prod only)
  DataClass    = "Confidential" (prod only)
}
```

## 🔒 Segurança

### Desenvolvimento
- Security groups restritivos
- Secrets Manager para credenciais
- Logs centralizados no CloudWatch

### Produção
- Todas as funcionalidades de desenvolvimento +
- WAF com regras de proteção
- Criptografia KMS para dados sensíveis
- Multi-AZ para alta disponibilidade
- Backup estendido (30 dias)

## 📊 Monitoramento

- **CloudWatch Logs**: Logs centralizados dos containers
- **CloudWatch Metrics**: Métricas de CPU, memória e rede
- **Auto Scaling**: Baseado em CPU (60% threshold)
- **Health Checks**: ALB monitora saúde dos containers

## 🔄 CI/CD

O projeto inclui workflows do GitHub Actions para:

- **Deploy Manual Dev**: Permite deploy manual para desenvolvimento
- **Deploy Manual Prod**: Permite deploy manual para produção

## 🆘 Troubleshooting

### Problemas Comuns

#### State Lock Issues
```bash
# Se houver problemas de lock, verificar:
terraform force-unlock <LOCK_ID>

# Verificar estado do backend
terraform init -backend-config=backend-<env>.hcl
```

#### Secrets Manager
```bash
# Limpar secrets órfãos
aws secretsmanager list-secrets --include-planned-deletion
aws secretsmanager delete-secret --secret-id <ARN> --force-delete-without-recovery
```

#### Recursos Órfãos
```bash
# Verificar recursos não gerenciados
aws ecs list-clusters
aws rds describe-db-instances
```

### Documentação Adicional
1. **Arquitetura**: Ver `ARCHITECTURE.md`
2. **Migração S3**: Ver `MIGRATION-S3-LOCKING.md`
3. **Backup Strategy**: Ver `BACKUP-STRATEGY.md`
4. **Logs**: GitHub Actions workflows
5. **Módulos**: Documentação em cada módulo

## 📝 Contribuição

1. Criar branch para mudanças
2. Testar em ambiente de desenvolvimento
3. Criar Pull Request
4. Aguardar revisão e aprovação

## 📄 Licença

Este projeto é propriedade de Nelson Holanda e destinado ao uso interno da aplicação BIA.