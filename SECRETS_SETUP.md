# 🔐 Configuração de Secrets - BIA Infrastructure

## 📋 Visão Geral

Este documento descreve como configurar os secrets necessários para o funcionamento da infraestrutura BIA. Os secrets são gerenciados pelo AWS Secrets Manager e incluem credenciais de banco de dados e outras informações sensíveis.

## 🔑 Secrets Necessários

### **1. Database Credentials (Automático)**
- **Nome**: `bia-{environment}-secrets`
- **Descrição**: Credenciais do banco PostgreSQL
- **Conteúdo**: Gerado automaticamente pelo Terraform
- **Criptografia**: KMS (produção) / AWS Managed (desenvolvimento)

### **2. Application Secrets (Manual)**
Se sua aplicação precisar de secrets adicionais, configure manualmente:

```bash
# Exemplo de secret adicional
aws secretsmanager create-secret \
  --name "bia-prod-app-secrets" \
  --description "Application secrets for BIA prod environment" \
  --secret-string '{
    "api_key": "your-api-key",
    "jwt_secret": "your-jwt-secret",
    "external_service_token": "your-token"
  }'
```

## 🚀 Configuração Automática

Os secrets de banco de dados são criados automaticamente pelo Terraform:

### **Desenvolvimento**
```bash
# Inicializar Terraform
terraform init -backend-config=backend-dev.hcl -reconfigure

# Aplicar configuração (cria secrets automaticamente)
terraform apply
```

### **Produção**
```bash
# Inicializar Terraform
terraform init -backend-config=backend-prod.hcl -reconfigure

# Aplicar configuração (cria secrets automaticamente)
terraform apply -var-file=terraform-prod.tfvars
```

## 🔍 Verificação de Secrets

### **Listar Secrets Existentes**
```bash
# Listar todos os secrets do projeto
aws secretsmanager list-secrets \
  --query 'SecretList[?contains(Name, `bia`)].{Name:Name,Description:Description}' \
  --output table
```

### **Verificar Conteúdo do Secret**
```bash
# Ver metadados (sem revelar o conteúdo)
aws secretsmanager describe-secret --secret-id bia-prod-secrets

# Ver conteúdo (cuidado - informação sensível)
aws secretsmanager get-secret-value --secret-id bia-prod-secrets \
  --query 'SecretString' --output text | jq .
```

### **Verificar Criptografia**
```bash
# Verificar chave KMS usada (produção)
aws secretsmanager describe-secret --secret-id bia-prod-secrets \
  --query 'KmsKeyId' --output text
```

## 🔄 Rotação de Secrets

### **Rotação Automática (Recomendado)**
```bash
# Configurar rotação automática para 30 dias
aws secretsmanager rotate-secret \
  --secret-id bia-prod-secrets \
  --rotation-rules AutomaticallyAfterDays=30
```

### **Rotação Manual**
```bash
# Gerar nova senha
NEW_PASSWORD=$(openssl rand -base64 32)

# Atualizar secret
aws secretsmanager update-secret \
  --secret-id bia-prod-secrets \
  --secret-string "{
    \"username\": \"bia_user\",
    \"password\": \"$NEW_PASSWORD\",
    \"engine\": \"postgres\",
    \"host\": \"bia-prod-db.cluster-xyz.us-east-1.rds.amazonaws.com\",
    \"port\": 5432,
    \"dbname\": \"bia\"
  }"

# Reiniciar serviço ECS para usar nova senha
aws ecs update-service \
  --cluster bia-prod-cluster \
  --service bia-prod-service \
  --force-new-deployment
```

## 🔒 Segurança e Boas Práticas

### **Permissões IAM**
As seguintes permissões são configuradas automaticamente:
- ECS Task Execution Role pode ler secrets
- KMS permite descriptografia via Secrets Manager
- Logs não expõem conteúdo dos secrets

### **Criptografia**
- **Desenvolvimento**: AWS Managed Keys
- **Produção**: Customer Managed KMS Keys com rotação automática

### **Auditoria**
```bash
# Verificar acessos aos secrets
aws logs filter-log-events \
  --log-group-name /aws/secretsmanager/bia-prod-secrets \
  --start-time $(date -d '24 hours ago' +%s)000
```

### **Monitoramento**
```bash
# Criar alarme para acessos não autorizados
aws cloudwatch put-metric-alarm \
  --alarm-name "BIA-Secrets-Unauthorized-Access" \
  --alarm-description "Alert on unauthorized secret access" \
  --metric-name "SecretRetrievals" \
  --namespace "AWS/SecretsManager" \
  --statistic Sum \
  --period 300 \
  --threshold 10 \
  --comparison-operator GreaterThanThreshold
```

## 🚨 Troubleshooting

### **Problema: ECS não consegue acessar secrets**
```bash
# Verificar permissões da role
aws iam get-role-policy \
  --role-name bia-prod-ecsTaskExecutionRole \
  --policy-name bia-prod-ecs-secrets-policy

# Verificar se secret existe
aws secretsmanager describe-secret --secret-id bia-prod-secrets

# Verificar logs do ECS
aws logs filter-log-events \
  --log-group-name /ecs/bia-prod \
  --filter-pattern "ERROR"
```

### **Problema: Secret não encontrado**
```bash
# Verificar se foi criado pelo Terraform
terraform state list | grep secretsmanager

# Recriar se necessário
terraform apply -var-file=terraform-prod.tfvars -target=module.rds.aws_secretsmanager_secret.db_password
```

### **Problema: Permissões KMS**
```bash
# Verificar política da chave KMS
aws kms get-key-policy \
  --key-id alias/bia-prod-secrets \
  --policy-name default

# Testar descriptografia
aws kms decrypt \
  --ciphertext-blob fileb://encrypted-data \
  --query Plaintext \
  --output text | base64 -d
```

## 📋 Checklist de Configuração

### **Desenvolvimento**
- [ ] Terraform aplicado com sucesso
- [ ] Secret `bia-dev-secrets` criado
- [ ] ECS consegue acessar o secret
- [ ] Aplicação conecta ao banco de dados

### **Produção**
- [ ] Terraform aplicado com sucesso
- [ ] Secret `bia-prod-secrets` criado
- [ ] Chave KMS configurada
- [ ] ECS consegue acessar o secret
- [ ] Aplicação conecta ao banco de dados
- [ ] Rotação automática configurada (opcional)
- [ ] Monitoramento configurado

## 🔗 Referências

- [AWS Secrets Manager Documentation](https://docs.aws.amazon.com/secretsmanager/)
- [ECS Secrets Management](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/specifying-sensitive-data.html)
- [KMS Key Policies](https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html)

---

**Versão**: 2.0  
**Última atualização**: 28 de Julho de 2025  
**Mantido por**: Nelson Holanda