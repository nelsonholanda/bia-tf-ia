# 🚀 BIA - Infraestrutura Terraform

Infraestrutura como código para a aplicação BIA usando Terraform, com suporte a múltiplos ambientes e recursos avançados de monitoramento, backup e segurança.

## 🎯 Visão Geral

### Arquitetura Implementada

- **Ambientes**: Desenvolvimento (dev) e Produção (prod)
- **Compute**: Amazon ECS com Auto Scaling
- **Database**: Amazon RDS PostgreSQL com Multi-AZ (prod)
- **Load Balancer**: Application Load Balancer (ALB)
- **Monitoring**: CloudWatch + SNS + Dashboard personalizado
- **Backup**: AWS Backup com cross-region (prod)
- **Security**: WAF (prod), KMS, Secrets Manager, VPC Endpoints

### Recursos por Ambiente

| Componente | Desenvolvimento | Produção |
|------------|----------------|----------|
| **VPC CIDR** | 10.0.0.0/16 | 10.1.0.0/16 |
| **Subnets** | 6 (3 pub + 3 priv) | 6 (3 pub + 3 priv) |
| **NAT Gateways** | 0 | 3 (Multi-AZ) |
| **RDS Instance** | db.t3.micro | db.t3.small (Multi-AZ) |
| **ECS Tasks** | 1-10 | 2-20 (HA) |
| **Backup Retention** | 7 dias | 365 dias |
| **Monitoring** | 7 alarmes | 8 alarmes |
| **WAF** | ❌ Desabilitado | ✅ Habilitado |
| **KMS** | ❌ Desabilitado | ✅ Habilitado |

## 📁 Estrutura do Projeto

```
bia-kiro-tf/
├── 📄 main.tf                           # Configuração principal
├── 📄 variables.tf                      # Variáveis do projeto
├── 📄 outputs.tf                        # Outputs do projeto
├── 📄 locals.tf                         # Configurações por ambiente
├── 📄 terraform.tfvars                  # Variáveis dev
├── 📄 terraform-prod.tfvars             # Variáveis prod
├── 📄 terraform.tfvars.example          # Exemplo de configuração
├── 📄 backend-dev.hcl                   # Backend S3 dev
├── 📄 backend-prod.hcl                  # Backend S3 prod
├── 📄 ops-config.yaml                   # Configuração operacional
├── 🔧 deploy.sh                         # Script de deploy
├── 🔧 setup-dynamodb-lock.sh            # Setup state lock
├── 📁 modules/                          # Módulos Terraform
│   ├── vpc/                             # Rede virtual (melhorado)
│   ├── iam/                             # Roles e políticas
│   ├── security-groups/                 # Grupos de segurança
│   ├── kms/                             # Chaves de criptografia
│   ├── rds/                             # Banco PostgreSQL (melhorado)
│   ├── alb/                             # Load Balancer
│   ├── ecs-cluster/                     # Cluster ECS
│   ├── ecs-service/                     # Serviços ECS
│   ├── cloudwatch/                      # Logs básicos
│   ├── waf/                             # Web Application Firewall
│   ├── monitoring/                      # 🆕 Monitoramento avançado
│   └── backup/                          # 🆕 Estratégia de backup
├── 📁 scripts/                          # Scripts operacionais
│   ├── health-check.sh                  # Verificação de saúde
│   ├── backup-report.sh                 # Relatório de backups
│   └── test-backup-recovery.sh          # Teste de recovery
├── 📁 .github/workflows/                # GitHub Actions
└── 📁 docs/                             # Documentação
    ├── TECHNICAL_OPERATIONS_MANUAL.md   # Manual técnico completo
    ├── IMPROVEMENTS_SUMMARY.md          # Resumo das melhorias
    ├── IMPLEMENTATION_COMPLETE.md       # Status da implementação
    └── QUICK_REFERENCE.md               # Referência rápida
```

## 🚀 Como Usar

### 1. Configuração Inicial

```bash
# Clonar o repositório
git clone <repository-url>
cd bia-kiro-tf
git checkout aws-tf

# Configurar AWS CLI
aws configure

# Configurar DynamoDB para state locking
./setup-dynamodb-lock.sh
```

### 2. Deploy para Desenvolvimento

```bash
# Deploy para desenvolvimento
./deploy.sh dev apply

# Verificar saúde da infraestrutura
./scripts/health-check.sh dev
```

### 3. Deploy para Produção

```bash
# Atualizar email de alertas
vim terraform-prod.tfvars
# Alterar: alert_email = "seu-email@exemplo.com"

# Deploy para produção
./deploy.sh prod apply

# Verificar saúde da infraestrutura
./scripts/health-check.sh prod
```

## 📊 Monitoramento e Operações

### Dashboards CloudWatch
- **Desenvolvimento**: [BIA-dev-Dashboard](https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=BIA-dev-Dashboard)
- **Produção**: [BIA-prod-Dashboard](https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=BIA-prod-Dashboard)

### Scripts Operacionais

```bash
# Verificação completa de saúde
./scripts/health-check.sh [dev|prod]

# Relatório de backups
./scripts/backup-report.sh [dev|prod] [days]

# Teste de recovery (dry-run)
./scripts/test-backup-recovery.sh [dev|prod] true
```

### Comandos Essenciais

```bash
# Validar configuração
terraform validate

# Planejar mudanças
terraform plan -var="environment=dev"
terraform plan -var-file=terraform-prod.tfvars

# Ver outputs
terraform output

# Verificar alarmes
aws cloudwatch describe-alarms --state-value ALARM
```

## 🔒 Segurança

### Recursos de Segurança Implementados

- **Secrets Manager**: Gestão segura de credenciais com rotação automática (prod)
- **KMS**: Criptografia de dados em repouso (prod)
- **WAF**: Proteção contra ataques web (prod)
- **VPC Endpoints**: Tráfego privado para S3 e ECR
- **Security Groups**: Regras restritivas por camada
- **Multi-AZ**: Alta disponibilidade em produção

### Gestão de Secrets

```bash
# Listar secrets
aws secretsmanager list-secrets --query 'SecretList[?contains(Name, `bia`)].Name'

# Rotacionar secret manualmente
aws secretsmanager rotate-secret --secret-id bia-prod-db-credentials
```

## 💾 Backup e Recovery

### Estratégia de Backup

- **Desenvolvimento**: Backup diário, retenção 7 dias
- **Produção**: Backup diário + semanal, retenção 365 dias, cross-region

### Verificar Backups

```bash
# Relatório completo de backups
./scripts/backup-report.sh prod 7

# Listar recovery points
aws backup list-recovery-points-by-backup-vault --backup-vault-name bia-prod-backup-vault
```

### Teste de Recovery

```bash
# Teste em modo dry-run (recomendado)
./scripts/test-backup-recovery.sh prod true

# Teste real (cria instância temporária)
./scripts/test-backup-recovery.sh prod false
```

## 🔧 Troubleshooting

### Problemas Comuns

1. **Deploy falha com "Secret Already Exists"**
   ```bash
   aws secretsmanager delete-secret --secret-id <arn> --force-delete-without-recovery
   ```

2. **ECS Tasks não iniciam**
   ```bash
   aws ecs describe-services --cluster bia-prod-cluster --services bia-prod-service
   ```

3. **RDS Connection Issues**
   ```bash
   aws rds describe-db-instances --db-instance-identifier bia-prod-db
   ```

Para troubleshooting detalhado, consulte: [Manual Técnico](docs/TECHNICAL_OPERATIONS_MANUAL.md)

## 📋 Documentação

- **[Manual Técnico](docs/TECHNICAL_OPERATIONS_MANUAL.md)**: Guia completo de operações
- **[Referência Rápida](docs/QUICK_REFERENCE.md)**: Comandos essenciais
- **[Resumo das Melhorias](docs/IMPROVEMENTS_SUMMARY.md)**: Detalhes das implementações
- **[Status da Implementação](docs/IMPLEMENTATION_COMPLETE.md)**: Estado atual do projeto

## 🏷️ Tags Padrão

Todos os recursos são taggeados automaticamente:

```hcl
tags = {
  Project         = "BIA"
  Owner           = "Nelson Holanda"
  ManagedBy       = "Terraform"
  Environment     = var.environment
  CostCenter      = "Engineering"
  Application     = "BIA"
  BusinessUnit    = "Production/Development"
  MonitoringLevel = "Critical/Standard"
  Backup          = "Required/Optional"
  Compliance      = "SOC2/Development"
  DataClass       = "Confidential/Internal"
}
```

## 💰 Otimização de Custos

### Recursos Implementados

- **VPC Endpoints**: Redução de custos de data transfer
- **Spot Instances**: Configurado para desenvolvimento
- **Auto Scaling**: Dimensionamento automático baseado em demanda
- **Storage GP3**: Melhor custo-benefício para RDS

### Monitoramento de Custos

```bash
# Verificar custos dos últimos 7 dias
aws ce get-cost-and-usage \
  --time-period Start=$(date -d '7 days ago' +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity DAILY \
  --metrics BlendedCost
```

## 🆘 Suporte e Contatos

### Níveis de Severidade

| Severidade | Descrição | Tempo de Resposta |
|------------|-----------|-------------------|
| **Crítica** | Aplicação indisponível | Imediato |
| **Alta** | Performance degradada | 1 hora |
| **Média** | Problemas menores | 4 horas |
| **Baixa** | Melhorias/Otimizações | 1-2 dias |

### Contatos

- **Infraestrutura**: Nelson Holanda
- **Aplicação**: Equipe de Desenvolvimento
- **AWS Support**: Caso Enterprise
- **Emergência**: Plantão 24/7

## 🔄 CI/CD

O projeto inclui workflows do GitHub Actions para:

- **Deploy Manual Dev**: Permite deploy manual para desenvolvimento
- **Deploy Manual Prod**: Permite deploy manual para produção

## 📈 Melhorias Implementadas (Branch aws-tf)

### 🆕 Novos Recursos

- **Módulo de Monitoramento**: 7-8 alarmes CloudWatch + Dashboard
- **Módulo de Backup**: AWS Backup com cross-region (prod)
- **VPC Endpoints**: S3 e ECR para otimização de custos
- **Scripts Operacionais**: Health check, backup report, recovery test

### 🔧 Melhorias Existentes

- **Rede Dinâmica**: Data sources para AZs, CIDRs padronizados
- **Segurança Aprimorada**: Secrets de 32 chars, rotação automática
- **RDS Melhorado**: GP3 storage, enhanced monitoring
- **Tags Expandidas**: BusinessUnit, MonitoringLevel, MaintenanceWindow

## 📝 Contribuição

1. Criar branch para mudanças
2. Testar em ambiente de desenvolvimento
3. Executar scripts de validação
4. Criar Pull Request
5. Aguardar revisão e aprovação

## 📄 Licença

Este projeto é propriedade de Nelson Holanda e destinado ao uso interno da aplicação BIA.

---

**🎉 Versão 2.0 - Implementação Completa com Recursos Avançados**

*Para informações detalhadas sobre operações, consulte o [Manual Técnico](docs/TECHNICAL_OPERATIONS_MANUAL.md)*