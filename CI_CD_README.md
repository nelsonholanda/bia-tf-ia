# 🚀 CI/CD Pipeline Documentation

## 📋 Overview

Este projeto implementa um pipeline CI/CD simplificado para Terraform com foco em segurança e controle de deployments.

## 🔄 Workflows Implementados

### 1. **Deploy Development** (`.github/workflows/deploy-dev.yml`)
**Trigger:** Manual (workflow_dispatch) com confirmação obrigatória

**Funcionalidades:**
- 🔒 Confirmação obrigatória "DEPLOY-DEV"
- 🔧 Terraform 1.6.6 com init -reconfigure
- 📋 Terraform plan e apply
- 🚀 Deploy com validação pós-deployment
- 📊 Outputs dos recursos criados

### 2. **Deploy Production** (`.github/workflows/deploy-prod.yml`)
**Trigger:** Push para branch `prod`

**Funcionalidades:**
- 🚀 Deploy automático em produção
- 🔧 Terraform 1.6.6 com validação e verificação de versão
- 📋 Terraform init -reconfigure, validate, plan e apply
- ✅ Validação pós-deployment
- 📊 Outputs dos recursos criados

### 3. **Destroy Development** (`.github/workflows/destroy-dev.yml`)
**Trigger:** Manual (workflow_dispatch) com confirmação obrigatória

**Funcionalidades:**
- 🔒 Confirmação obrigatória "DESTROY-DEV"
- 🔧 Terraform 1.6.6 com init -reconfigure
- 🗑️ Terraform destroy
- ✅ Verificação pós-destruição de recursos AWS

### 4. **Destroy Production** (`.github/workflows/destroy-prod.yml`)
**Trigger:** Manual (workflow_dispatch) com confirmação obrigatória

**Funcionalidades:**
- 🔒 Confirmação obrigatória "DESTROY-PRODUCTION"
- ⚠️ Avisos de segurança adicionais
- 🔧 Terraform 1.6.6 com init -reconfigure
- 🗑️ Terraform destroy
- ✅ Verificação pós-destruição de recursos AWS

## 🔧 Configuration

### **GitHub Secrets Necessários:**
- `AWS_ACCESS_KEY_ID` - AWS Access Key
- `AWS_SECRET_ACCESS_KEY` - AWS Secret Key

### **Backend Configuration:**
- **S3 Bucket**: `tf-nh`
- **Encryption**: Habilitada
- **State Locking**: Não configurado (sem DynamoDB)

## 📋 Best Practices

### **Deployments:**
1. ✅ Dev: Manual com confirmação "DEPLOY-DEV"
2. ✅ Prod: Automático após push para branch prod
3. ✅ Sempre validar pós-deployment
4. ✅ Monitorar logs e métricas

### **Destroy Operations:**
1. ✅ Sempre manual com confirmação
2. ✅ Verificação pós-destruição
3. ✅ Confirmações diferentes por ambiente
4. ✅ Avisos de segurança para produção

## 🚨 Troubleshooting

### **Terraform Version Issues:**
```bash
# Verificar versão local
terraform version

# Usar mesma versão dos workflows
terraform version # Deve ser 1.6.6 ou superior
```

### **Plan Failures:**
```bash
# Verificar backend
terraform init -reconfigure -backend-config=backend-prod.hcl

# Validar configuração
terraform validate

# Debug plan
terraform plan -var="environment=prod" -detailed-exitcode
```

### **Backend Issues:**
```bash
# Verificar se bucket S3 existe
aws s3 ls s3://tf-nh

# Reconfigurar backend se necessário
terraform init -reconfigure -backend-config=backend-prod.hcl
```

### **GitHub Actions Failures:**
```bash
# Verificar logs do workflow
# Procurar por erros como "unsupported checkable object kind"
# Verificar se a versão do Terraform está correta (1.6.6)
```

## 📞 Support

Para problemas com CI/CD:
1. Verificar workflow logs no GitHub Actions
2. Executar validação local com `./validate-local.sh`
3. Verificar configurações de backend
4. Consultar documentação do Terraform