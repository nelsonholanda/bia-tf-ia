# 🔄 Estratégia de Backup Cross-Region AWS

## 📋 **Visão Geral**

Este documento descreve a implementação da estratégia de backup cross-region para o ambiente de produção da aplicação BIA, com replicação automática de backups entre `us-east-1` (região principal) e `sa-east-1` (região de backup).

## 🏗️ **Arquitetura de Backup Cross-Region**

```
┌─────────────────────────────────────────────────────────────────┐
│                    REGIÃO PRINCIPAL (us-east-1)                 │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌──────────────────┐  ┌─────────────────┐ │
│  │   RDS Instance  │  │  Backup Vault    │  │  KMS Key (US)   │ │
│  │   bia-prod-db   │─▶│  prod-backup-    │─▶│  Encryption     │ │
│  │                 │  │  vault           │  │                 │ │
│  └─────────────────┘  └──────────────────┘  └─────────────────┘ │
│                               │                                 │
│                               ▼                                 │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                 Backup Plan                                 │ │
│  │  • Daily: 3:00 AM UTC (Retention: 30 dias)                 │ │
│  │  • Weekly: Sunday 5:00 AM UTC (Retention: 90 dias)         │ │
│  └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                                │
                                │ Cross-Region Copy
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                   REGIÃO BACKUP (sa-east-1)                     │
├─────────────────────────────────────────────────────────────────┤
│  ┌──────────────────┐  ┌─────────────────┐                     │
│  │  Backup Vault    │  │  KMS Key (BR)   │                     │
│  │  prod-backup-    │─▶│  Encryption     │                     │
│  │  vault-cross-    │  │                 │                     │
│  │  region          │  │                 │                     │
│  └──────────────────┘  └─────────────────┘                     │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                Cross-Region Retention                       │ │
│  │  • Daily Copies: 90 dias                                   │ │
│  │  • Weekly Copies: 365 dias (1 ano)                        │ │
│  └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## 📊 **Configurações de Backup**

### **📅 Agendamento de Backups**

| Tipo | Frequência | Horário (UTC) | Região Principal | Cross-Region |
|------|------------|---------------|------------------|--------------|
| **Daily** | Diário | 03:00 | 30 dias | 90 dias |
| **Weekly** | Domingos | 05:00 | 90 dias | 365 dias |

### **🕐 Janelas de Execução**

- **Start Window**: 60 minutos
- **Completion Window**: 120 minutos
- **Cold Storage**: 30 dias (daily), 7 dias (weekly)

## 🔐 **Segurança e Criptografia**

### **Chaves KMS**

```hcl
# Região Principal (us-east-1)
resource "aws_kms_key" "backup" {
  description             = "KMS key for AWS Backup encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

# Cross-Region (sa-east-1)
# Utiliza a mesma chave replicada
```

### **IAM Policies**

O módulo de backup implementa as seguintes políticas:

- **AWSBackupServiceRolePolicyForBackup**
- **AWSBackupServiceRolePolicyForRestores**
- **Política customizada para cross-region**

## 🎯 **Seleção de Recursos**

### **Tags para Backup**

Os recursos são selecionados para backup baseado nas seguintes tags:

```hcl
selection_tag {
  type  = "STRINGEQUALS"
  key   = "Environment"
  value = "prod"
}

selection_tag {
  type  = "STRINGEQUALS"
  key   = "BackupEnabled"
  value = "true"
}
```

### **Recursos Incluídos**

- **RDS Instance**: `bia-prod-db`
- **Tags aplicadas**:
  - `Environment = "prod"`
  - `BackupEnabled = "true"`

## 📈 **Monitoramento e Alertas**

### **CloudWatch Events**

- **Backup Job State Change**
- **Copy Job State Change**
- **Estados monitorados**: COMPLETED, FAILED, EXPIRED

### **Métricas Customizadas**

```hcl
# Métrica para falhas de backup
metric_transformation {
  name      = "BackupFailures"
  namespace = "AWS/Backup/Custom"
  value     = "1"
}
```

### **Alarmes**

- **Alarm Name**: `prod-backup-failures`
- **Threshold**: > 0 falhas
- **Period**: 5 minutos
- **Evaluation**: 1 período

## 📋 **Relatórios de Compliance**

### **Backup Report Plan**

- **Formato**: CSV, JSON
- **Bucket S3**: `tf-nh`
- **Prefix**: `backup-reports/prod/`
- **Template**: `BACKUP_JOB_REPORT`

## 🚀 **Implementação**

### **Módulos Terraform**

```hcl
module "backup" {
  source = "./modules/backup"

  environment                 = var.environment
  tags                       = local.common_tags
  backup_kms_key_arn         = module.kms.backup_kms_key_arn
  cross_region_kms_key_arn   = module.kms.backup_kms_key_arn
  rds_instance_arns          = [module.rds.db_instance_arn]
  reports_s3_bucket          = "tf-nh"

  providers = {
    aws.sa_east_1 = aws.sa_east_1
  }
}
```

### **Validação**

```bash
# Inicializar com novo módulo
terraform init -backend-config=backend-prod.hcl

# Validar configuração
terraform validate

# Planejar deployment
terraform plan -var-file=terraform-prod.tfvars

# Aplicar apenas em produção
terraform apply -var-file=terraform-prod.tfvars
```

## 🔍 **Operações de Backup**

### **Comandos AWS CLI**

```bash
# Listar backup vaults
aws backup list-backup-vaults --region us-east-1
aws backup list-backup-vaults --region sa-east-1

# Listar recovery points
aws backup list-recovery-points-by-backup-vault \
  --backup-vault-name prod-backup-vault \
  --region us-east-1

# Verificar jobs de backup
aws backup list-backup-jobs --region us-east-1

# Verificar jobs de cópia cross-region
aws backup list-copy-jobs --region us-east-1
```

### **Restore de Backup**

```bash
# Restore de recovery point
aws backup start-restore-job \
  --recovery-point-arn <recovery-point-arn> \
  --metadata \
    DBInstanceIdentifier=bia-prod-db-restored,\
    Engine=postgres \
    --iam-role-arn <backup-role-arn> \
    --region us-east-1
```

## 📊 **Custos Estimados**

### **Breakdown de Custos (Mensal)**

| Componente | Estimativa (USD) | Descrição |
|------------|------------------|-----------|
| Backup Storage (us-east-1) | $5-10 | ~50GB dados + logs |
| Cross-Region Storage (sa-east-1) | $8-15 | Replicação + retenção estendida |
| KMS Operations | $1-2 | Encrypt/Decrypt operations |
| **Total Estimado** | **$14-27** | Varia com volume de dados |

### **Otimizações de Custo**

- **Cold Storage**: Move para IA após 30 dias (daily) / 7 dias (weekly)
- **Lifecycle Policies**: Deleção automática após períodos definidos
- **Compressed Backups**: RDS comprime automaticamente

## 🔧 **Troubleshooting**

### **Problemas Comuns**

#### **1. Backup Job Failed**

```bash
# Verificar logs
aws logs describe-log-groups --log-group-name-prefix "/aws/backup"

# Verificar IAM permissions
aws iam get-role --role-name prod-aws-backup-role
```

#### **2. Cross-Region Copy Failed**

```bash
# Verificar conectividade entre regiões
aws backup describe-backup-vault \
  --backup-vault-name prod-backup-vault-cross-region \
  --region sa-east-1

# Verificar KMS permissions
aws kms describe-key --key-id <backup-kms-key-id> --region sa-east-1
```

#### **3. Tags Missing**

```bash
# Verificar tags no RDS
aws rds describe-db-instances \
  --db-instance-identifier bia-prod-db \
  --query 'DBInstances[0].TagList'
```

## 📚 **Referências**

### **Documentação AWS**

- [AWS Backup Developer Guide](https://docs.aws.amazon.com/aws-backup/latest/devguide/)
- [Cross-Region Backup](https://docs.aws.amazon.com/aws-backup/latest/devguide/cross-region-backup.html)
- [RDS Backup Best Practices](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_CommonTasks.BackupRestore.html)

### **Terraform Resources**

- [aws_backup_vault](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_vault)
- [aws_backup_plan](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_plan)
- [aws_backup_selection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_selection)

---

**Última atualização**: Janeiro 2025  
**Versão**: 1.0.0  
**Autor**: Nelson Holanda  
**Status**: ✅ Implementado e Testado  
**Ambiente**: Produção (us-east-1 → sa-east-1)
