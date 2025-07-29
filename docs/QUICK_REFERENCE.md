# 🚀 BIA Infrastructure - Referência Rápida

## 📋 Comandos Essenciais

### Deploy e Gestão
```bash
# Deploy desenvolvimento
./deploy.sh dev apply

# Deploy produção
./deploy.sh prod apply

# Destruir ambiente (CUIDADO!)
./deploy.sh dev destroy
./deploy.sh prod destroy

# Validar configuração
terraform validate

# Planejar mudanças
terraform plan -var="environment=dev"
terraform plan -var-file=terraform-prod.tfvars
```

### Monitoramento
```bash
# Health check completo
./scripts/health-check.sh dev
./scripts/health-check.sh prod

# Relatório de backup
./scripts/backup-report.sh prod 7

# Teste de recovery (dry-run)
./scripts/test-backup-recovery.sh prod true

# Verificar alarmes ativos
aws cloudwatch describe-alarms --state-value ALARM
```

### Logs e Debug
```bash
# Logs ECS
aws logs tail /ecs/bia --follow

# Logs aplicação
aws logs tail /aws/ecs/bia-prod/application --follow

# Status do serviço ECS
aws ecs describe-services --cluster bia-prod-cluster --services bia-prod-service
```

---

## 🔧 Troubleshooting Rápido

### Problema: Deploy falha com "Secret Already Exists"
```bash
# Listar secrets órfãos
aws secretsmanager list-secrets --include-planned-deletion

# Forçar deleção
aws secretsmanager delete-secret --secret-id <arn> --force-delete-without-recovery
```

### Problema: ECS Tasks não iniciam
```bash
# Verificar logs do ECS
aws ecs describe-services --cluster bia-prod-cluster --services bia-prod-service

# Verificar task definition
aws ecs describe-task-definition --task-definition bia-prod-task
```

### Problema: RDS Connection Issues
```bash
# Verificar security groups
aws ec2 describe-security-groups --filters "Name=group-name,Values=bia-prod-rds"

# Testar conectividade
aws rds describe-db-instances --db-instance-identifier bia-prod-db
```

---

## 📊 URLs Importantes

### Dashboards
- **Dev**: https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=BIA-dev-Dashboard
- **Prod**: https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=BIA-prod-Dashboard

### Consoles AWS
- **Backup**: https://console.aws.amazon.com/backup/home?region=us-east-1#/backupvaults
- **ECS**: https://console.aws.amazon.com/ecs/home?region=us-east-1#/clusters
- **RDS**: https://console.aws.amazon.com/rds/home?region=us-east-1#databases:

---

## 🔒 Informações de Segurança

### Secrets Manager
```bash
# Listar secrets
aws secretsmanager list-secrets --query 'SecretList[?contains(Name, `bia`)].Name'

# Rotacionar secret
aws secretsmanager rotate-secret --secret-id bia-prod-db-credentials
```

### KMS Keys
```bash
# Listar chaves
aws kms list-keys --query 'Keys[].KeyId'

# Verificar política de chave
aws kms get-key-policy --key-id <key-id> --policy-name default
```

---

## 💾 Backup e Recovery

### Verificar Backups
```bash
# Listar recovery points
aws backup list-recovery-points-by-backup-vault --backup-vault-name bia-prod-backup-vault

# Status dos jobs de backup
aws backup list-backup-jobs --by-state COMPLETED --max-results 5
```

### Recovery de Emergência
```bash
# Backup manual imediato
aws backup start-backup-job \
  --backup-vault-name bia-prod-backup-vault \
  --resource-arn $(terraform output rds_instance_arn) \
  --iam-role-arn $(terraform output backup_role_arn)
```

---

## 🚨 Comandos de Emergência

### Parar Aplicação
```bash
# Reduzir tasks para 0
aws ecs update-service \
  --cluster bia-prod-cluster \
  --service bia-prod-service \
  --desired-count 0
```

### Habilitar Maintenance Mode
```bash
# Modificar health check do ALB
aws elbv2 modify-target-group \
  --target-group-arn $(terraform output alb_target_group_arn) \
  --health-check-path /maintenance
```

### Verificar Custos
```bash
# Custos dos últimos 7 dias
aws ce get-cost-and-usage \
  --time-period Start=$(date -d '7 days ago' +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity DAILY \
  --metrics BlendedCost
```

---

## 📱 Contatos de Emergência

| Severidade | Contato | Tempo de Resposta |
|------------|---------|-------------------|
| **Crítica** | Nelson Holanda + AWS Support | Imediato |
| **Alta** | Equipe de Infraestrutura | 1 hora |
| **Média** | Equipe de Desenvolvimento | 4 horas |
| **Baixa** | Próximo ciclo | 1-2 dias |

---

## 🔍 Verificações de Rotina

### Diárias
- [ ] Verificar alarmes: `aws cloudwatch describe-alarms --state-value ALARM`
- [ ] Status dos serviços: `./scripts/health-check.sh prod`
- [ ] Logs de erro: `aws logs filter-log-events --log-group-name /ecs/bia --filter-pattern "ERROR"`

### Semanais
- [ ] Relatório de backup: `./scripts/backup-report.sh prod 7`
- [ ] Revisão de custos: `aws ce get-cost-and-usage`
- [ ] Atualização de dependências: `terraform init -upgrade`

### Mensais
- [ ] Teste de recovery: `./scripts/test-backup-recovery.sh prod false`
- [ ] Rotação de secrets: `aws secretsmanager rotate-secret`
- [ ] Auditoria de segurança: Revisar security groups e políticas

---

## 📋 Checklist de Deploy

### Pré-Deploy
- [ ] Código revisado e aprovado
- [ ] Terraform validate passou
- [ ] Plan revisado e aprovado
- [ ] Backup recente confirmado

### Deploy
- [ ] Deploy em dev primeiro
- [ ] Testes funcionais passaram
- [ ] Health check OK
- [ ] Deploy em prod
- [ ] Monitoramento ativo

### Pós-Deploy
- [ ] Aplicação funcionando
- [ ] Alarmes não disparados
- [ ] Logs sem erros críticos
- [ ] Performance dentro do esperado

---

*Última atualização: 29 de Julho de 2025*  
*Para informações detalhadas, consulte: TECHNICAL_OPERATIONS_MANUAL.md*
