# 📖 Manual Técnico de Operações - BIA Infrastructure

**Versão:** 2.0  
**Data:** 29 de Julho de 2025  
**Branch:** aws-tf  
**Autor:** Amazon Q - AWS Assistant

---

## 📋 Índice

1. [Visão Geral](#-visão-geral)
2. [Pré-requisitos](#-pré-requisitos)
3. [Estrutura do Projeto](#-estrutura-do-projeto)
4. [Operações Básicas](#-operações-básicas)
5. [Monitoramento e Alertas](#-monitoramento-e-alertas)
6. [Backup e Recovery](#-backup-e-recovery)
7. [Troubleshooting](#-troubleshooting)
8. [Manutenção](#-manutenção)
9. [Segurança](#-segurança)
10. [Referências](#-referências)

---

## 🎯 Visão Geral

### Arquitetura Implementada

A infraestrutura BIA utiliza uma arquitetura multi-ambiente com as seguintes características:

- **Ambientes**: Desenvolvimento (dev) e Produção (prod)
- **Compute**: Amazon ECS com Auto Scaling
- **Database**: Amazon RDS PostgreSQL
- **Load Balancer**: Application Load Balancer (ALB)
- **Monitoring**: CloudWatch + SNS + Dashboard
- **Backup**: AWS Backup com cross-region (prod)
- **Security**: WAF (prod), KMS, Secrets Manager

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

---

## 🔧 Pré-requisitos

### Ferramentas Necessárias

```bash
# Terraform
terraform --version  # >= 1.0

# AWS CLI
aws --version        # >= 2.0

# Git
git --version       # >= 2.0
```

### Configuração AWS

```bash
# Configurar credenciais
aws configure

# Verificar acesso
aws sts get-caller-identity
```

### Permissões IAM Necessárias

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "ecs:*",
        "rds:*",
        "elasticloadbalancing:*",
        "cloudwatch:*",
        "sns:*",
        "secretsmanager:*",
        "kms:*",
        "backup:*",
        "wafv2:*",
        "s3:*",
        "dynamodb:*"
      ],
      "Resource": "*"
    }
  ]
}
```

---

## 📁 Estrutura do Projeto

```
bia-kiro-tf/
├── 📄 main.tf                           # Configuração principal
├── 📄 variables.tf                      # Variáveis do projeto
├── 📄 outputs.tf                        # Outputs do projeto
├── 📄 locals.tf                         # Configurações por ambiente
├── 📄 terraform.tfvars                  # Variáveis dev
├── 📄 terraform-prod.tfvars             # Variáveis prod
├── 📄 backend-dev.hcl                   # Backend S3 dev
├── 📄 backend-prod.hcl                  # Backend S3 prod
├── 🔧 deploy.sh                         # Script de deploy
├── 🔧 setup-dynamodb-lock.sh            # Setup state lock
├── 📁 modules/                          # Módulos Terraform
│   ├── vpc/                             # Rede virtual
│   ├── iam/                             # Roles e políticas
│   ├── security-groups/                 # Grupos de segurança
│   ├── kms/                             # Chaves de criptografia
│   ├── rds/                             # Banco PostgreSQL
│   ├── alb/                             # Load Balancer
│   ├── ecs-cluster/                     # Cluster ECS
│   ├── ecs-service/                     # Serviços ECS
│   ├── cloudwatch/                      # Logs básicos
│   ├── waf/                             # Web Application Firewall
│   ├── monitoring/                      # 🆕 Monitoramento avançado
│   └── backup/                          # 🆕 Estratégia de backup
├── 📁 .github/workflows/                # GitHub Actions
└── 📋 docs/                             # Documentação
    ├── TECHNICAL_OPERATIONS_MANUAL.md   # Este manual
    ├── IMPROVEMENTS_SUMMARY.md          # Resumo melhorias
    └── IMPLEMENTATION_COMPLETE.md       # Status implementação
```

---

## 🚀 Operações Básicas

### 1. Deploy Inicial

#### Desenvolvimento
```bash
# 1. Clonar repositório
git clone <repository-url>
cd bia-kiro-tf
git checkout aws-tf

# 2. Configurar DynamoDB para state locking
./setup-dynamodb-lock.sh

# 3. Deploy desenvolvimento
./deploy.sh dev apply
```

#### Produção
```bash
# 1. Atualizar email de alertas
vim terraform-prod.tfvars
# Alterar: alert_email = "seu-email@exemplo.com"

# 2. Deploy produção
./deploy.sh prod apply
```

### 2. Comandos Básicos

```bash
# Validar configuração
terraform validate

# Planejar mudanças
terraform plan -var="environment=dev"
terraform plan -var-file=terraform-prod.tfvars

# Aplicar mudanças
./deploy.sh dev apply
./deploy.sh prod apply

# Destruir recursos (CUIDADO!)
./deploy.sh dev destroy
./deploy.sh prod destroy
```

### 3. Verificar Status

```bash
# Listar recursos
terraform state list

# Ver outputs
terraform output

# Status específico
terraform show
```

---

## 📊 Monitoramento e Alertas

### CloudWatch Alarms Configurados

#### Desenvolvimento (7 alarmes)
1. **bia-dev-ecs-high-cpu** - CPU ECS > 80%
2. **bia-dev-ecs-high-memory** - Memory ECS > 85%
3. **bia-dev-rds-high-cpu** - CPU RDS > 80%
4. **bia-dev-rds-low-storage** - Storage RDS < 2GB
5. **bia-dev-alb-high-response-time** - Response time > 2s
6. **bia-dev-alb-high-5xx-errors** - 5XX errors > 10
7. **bia-dev-application-error-rate** - App errors > 10

#### Produção (8 alarmes)
1. **bia-prod-ecs-high-cpu** - CPU ECS > 70%
2. **bia-prod-ecs-high-memory** - Memory ECS > 80%
3. **bia-prod-rds-high-cpu** - CPU RDS > 70%
4. **bia-prod-rds-low-storage** - Storage RDS < 2GB
5. **bia-prod-alb-high-response-time** - Response time > 2s
6. **bia-prod-alb-high-5xx-errors** - 5XX errors > 10
7. **bia-prod-application-error-rate** - App errors > 5
8. **bia-prod-ecs-low-task-count** - Tasks < 2 (HA)

### Dashboard CloudWatch

Acesse o dashboard em:
```
https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=BIA-{environment}-Dashboard
```

### Configurar Notificações

```bash
# 1. Confirmar subscription SNS
aws sns confirm-subscription \
  --topic-arn $(terraform output sns_topic_arn) \
  --token <token-do-email>

# 2. Testar notificação
aws sns publish \
  --topic-arn $(terraform output sns_topic_arn) \
  --message "Teste de notificação BIA"
```

### Logs Importantes

```bash
# Logs ECS
aws logs describe-log-groups --log-group-name-prefix "/ecs/bia"

# Logs aplicação
aws logs tail /aws/ecs/bia-{environment}/application --follow

# Logs RDS
aws logs describe-log-groups --log-group-name-prefix "/aws/rds"
```

---

## 💾 Backup e Recovery

### Estratégia de Backup

#### Desenvolvimento
- **Frequência**: Diário (5 AM UTC)
- **Retenção**: 7 dias
- **Localização**: us-east-1
- **Encryption**: Padrão AWS

#### Produção
- **Frequência**: Diário (5 AM UTC) + Semanal (3 AM UTC Domingo)
- **Retenção**: 365 dias (diário), 1 ano (semanal)
- **Localização**: us-east-1 + us-west-2 (cross-region)
- **Encryption**: KMS Customer Managed

### Verificar Backups

```bash
# Listar backup vaults
aws backup list-backup-vaults

# Listar recovery points
aws backup list-recovery-points-by-backup-vault \
  --backup-vault-name bia-{environment}-backup-vault

# Status do backup plan
aws backup get-backup-plan \
  --backup-plan-id $(terraform output backup_plan_arn | cut -d'/' -f2)
```

### Restaurar Backup

```bash
# 1. Listar recovery points disponíveis
aws backup list-recovery-points-by-backup-vault \
  --backup-vault-name bia-prod-backup-vault

# 2. Iniciar restore job
aws backup start-restore-job \
  --recovery-point-arn <recovery-point-arn> \
  --metadata '{
    "DBInstanceIdentifier": "bia-prod-db-restored",
    "DBInstanceClass": "db.t3.small"
  }' \
  --iam-role-arn $(terraform output backup_role_arn)
```

### Teste de Recovery

```bash
# Script de teste mensal (executar em produção)
#!/bin/bash
RECOVERY_POINT=$(aws backup list-recovery-points-by-backup-vault \
  --backup-vault-name bia-prod-backup-vault \
  --query 'RecoveryPoints[0].RecoveryPointArn' --output text)

aws backup start-restore-job \
  --recovery-point-arn $RECOVERY_POINT \
  --metadata '{
    "DBInstanceIdentifier": "bia-prod-db-test-restore",
    "DBInstanceClass": "db.t3.micro"
  }' \
  --iam-role-arn $(terraform output backup_role_arn)
```

---

## 🔍 Troubleshooting

### Problemas Comuns

#### 1. Deploy Falha com "Secret Already Exists"

```bash
# Problema: Secret órfão no Secrets Manager
# Solução: Limpar secrets órfãos
aws secretsmanager list-secrets --include-planned-deletion \
  --query 'SecretList[?contains(Name, `bia-{environment}`)].ARN' --output text

# Forçar deleção
aws secretsmanager delete-secret \
  --secret-id <secret-arn> \
  --force-delete-without-recovery
```

#### 2. ECS Tasks Não Iniciam

```bash
# Verificar logs do ECS
aws ecs describe-services \
  --cluster bia-{environment}-cluster \
  --services bia-{environment}-service

# Verificar task definition
aws ecs describe-task-definition \
  --task-definition bia-{environment}-task

# Logs detalhados
aws logs tail /ecs/bia --follow
```

#### 3. RDS Connection Issues

```bash
# Verificar security groups
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=bia-{environment}-rds"

# Testar conectividade
aws rds describe-db-instances \
  --db-instance-identifier bia-{environment}-db

# Verificar secrets
aws secretsmanager get-secret-value \
  --secret-id bia-{environment}-db-credentials
```

#### 4. ALB Health Check Failures

```bash
# Verificar target group
aws elbv2 describe-target-health \
  --target-group-arn $(terraform output alb_target_group_arn)

# Verificar ALB
aws elbv2 describe-load-balancers \
  --load-balancer-arns $(terraform output alb_arn)
```

### Logs de Debug

```bash
# Habilitar debug Terraform
export TF_LOG=DEBUG
terraform plan

# Logs AWS CLI
aws logs create-log-group --log-group-name /aws/terraform/debug
```

### Comandos de Diagnóstico

```bash
# Status geral da infraestrutura
./scripts/health-check.sh

# Verificar custos
aws ce get-cost-and-usage \
  --time-period Start=2025-07-01,End=2025-07-31 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE
```

---

## 🔧 Manutenção

### Tarefas Diárias

```bash
# 1. Verificar alarmes
aws cloudwatch describe-alarms \
  --state-value ALARM \
  --query 'MetricAlarms[?contains(AlarmName, `bia`)].AlarmName'

# 2. Verificar backup status
aws backup list-backup-jobs \
  --by-state COMPLETED \
  --max-results 5

# 3. Verificar logs de erro
aws logs filter-log-events \
  --log-group-name /ecs/bia \
  --filter-pattern "ERROR"
```

### Tarefas Semanais

```bash
# 1. Atualizar dependências
terraform init -upgrade

# 2. Verificar security groups
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=bia-*" \
  --query 'SecurityGroups[].{Name:GroupName,Rules:IpPermissions}'

# 3. Revisar custos
aws ce get-cost-and-usage \
  --time-period Start=$(date -d '7 days ago' +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity DAILY \
  --metrics BlendedCost
```

### Tarefas Mensais

```bash
# 1. Teste de recovery
./scripts/test-backup-recovery.sh

# 2. Atualização de secrets
aws secretsmanager rotate-secret \
  --secret-id bia-prod-db-credentials

# 3. Review de security
aws config get-compliance-summary
```

### Atualizações de Versão

```bash
# 1. Atualizar versão PostgreSQL
vim locals.tf
# Alterar postgres_version = "15.9"

# 2. Aplicar em dev primeiro
./deploy.sh dev apply

# 3. Testar aplicação
curl http://$(terraform output alb_dns_name)/health

# 4. Aplicar em prod
./deploy.sh prod apply
```

---

## 🔒 Segurança

### Gestão de Secrets

```bash
# Listar secrets
aws secretsmanager list-secrets \
  --query 'SecretList[?contains(Name, `bia`)].Name'

# Rotacionar secret manualmente
aws secretsmanager rotate-secret \
  --secret-id bia-prod-db-credentials

# Verificar rotação automática
aws secretsmanager describe-secret \
  --secret-id bia-prod-db-credentials \
  --query 'RotationRules'
```

### Auditoria de Segurança

```bash
# 1. Verificar KMS keys
aws kms list-keys --query 'Keys[].KeyId'

# 2. Verificar WAF rules (produção)
aws wafv2 list-web-acls --scope REGIONAL

# 3. Verificar VPC Flow Logs
aws ec2 describe-flow-logs

# 4. Verificar GuardDuty findings
aws guardduty list-findings \
  --detector-id $(aws guardduty list-detectors --query 'DetectorIds[0]' --output text)
```

### Compliance Checks

```bash
# 1. Verificar encryption at rest
aws rds describe-db-instances \
  --query 'DBInstances[].StorageEncrypted'

# 2. Verificar backup encryption
aws backup describe-backup-vault \
  --backup-vault-name bia-prod-backup-vault \
  --query 'EncryptionKeyArn'

# 3. Verificar SSL/TLS
aws elbv2 describe-listeners \
  --load-balancer-arn $(terraform output alb_arn)
```

---

## 📚 Referências

### Scripts Úteis

#### health-check.sh
```bash
#!/bin/bash
echo "=== BIA Infrastructure Health Check ==="
echo "Environment: $1"

# ECS Service
aws ecs describe-services \
  --cluster bia-$1-cluster \
  --services bia-$1-service \
  --query 'services[0].{Status:status,Running:runningCount,Desired:desiredCount}'

# RDS Status
aws rds describe-db-instances \
  --db-instance-identifier bia-$1-db \
  --query 'DBInstances[0].{Status:DBInstanceStatus,MultiAZ:MultiAZ}'

# ALB Status
aws elbv2 describe-target-health \
  --target-group-arn $(terraform output alb_target_group_arn) \
  --query 'TargetHealthDescriptions[].{Target:Target.Id,Health:TargetHealth.State}'
```

#### backup-report.sh
```bash
#!/bin/bash
echo "=== Backup Report ==="
aws backup list-backup-jobs \
  --by-state COMPLETED \
  --max-results 10 \
  --query 'BackupJobs[].[BackupJobId,ResourceArn,CreationDate,CompletionDate]' \
  --output table
```

### Comandos de Emergência

```bash
# Parar todos os serviços ECS
aws ecs update-service \
  --cluster bia-prod-cluster \
  --service bia-prod-service \
  --desired-count 0

# Habilitar maintenance mode no ALB
aws elbv2 modify-target-group \
  --target-group-arn $(terraform output alb_target_group_arn) \
  --health-check-path /maintenance

# Backup manual imediato
aws backup start-backup-job \
  --backup-vault-name bia-prod-backup-vault \
  --resource-arn $(terraform output rds_instance_arn) \
  --iam-role-arn $(terraform output backup_role_arn)
```

### Contatos de Suporte

- **Infraestrutura**: Nelson Holanda
- **Aplicação**: Equipe de Desenvolvimento
- **AWS Support**: Caso Enterprise
- **Emergência**: Plantão 24/7

---

## 📞 Suporte e Escalação

### Níveis de Severidade

#### Severidade 1 (Crítica)
- Aplicação indisponível
- Perda de dados
- Breach de segurança

**Ação**: Contato imediato + AWS Support

#### Severidade 2 (Alta)
- Performance degradada
- Funcionalidades limitadas
- Alarmes críticos

**Ação**: Investigação em 1 hora

#### Severidade 3 (Média)
- Problemas menores
- Alarmes informativos
- Manutenção planejada

**Ação**: Investigação em 4 horas

#### Severidade 4 (Baixa)
- Melhorias
- Documentação
- Otimizações

**Ação**: Próximo ciclo de desenvolvimento

---

**📋 Este manual deve ser atualizado a cada mudança na infraestrutura.**

*Última atualização: 29 de Julho de 2025*  
*Versão: 2.0*  
*Autor: Amazon Q - AWS Assistant*
