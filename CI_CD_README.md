# 🚀 CI/CD Pipeline Documentation

[![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-2088FF?logo=github-actions&logoColor=white)](https://github.com/features/actions)
[![Terraform](https://img.shields.io/badge/Terraform-1.6.6+-623CE4?logo=terraform&logoColor=white)](https://www.terraform.io/)

## 📋 Overview

Este projeto implementa um pipeline CI/CD robusto e seguro para Terraform com foco em:
- **Segurança**: Confirmações obrigatórias e validações
- **Confiabilidade**: Terraform 1.6.6 com init -reconfigure
- **Simplicidade**: Workflows claros e funcionais
- **Debugging**: Logs detalhados e verificações

## 🔄 Workflows Implementados

### 1. **Deploy Development** (`.github/workflows/deploy-dev.yml`)

**Trigger**: Manual (workflow_dispatch) com confirmação obrigatória

```yaml
on:
  workflow_dispatch:
    inputs:
      confirm:
        description: 'Type "DEPLOY-DEV" to confirm deployment'
        required: true
        type: string
```

**Funcionalidades**:
- 🔒 **Confirmação obrigatória**: "DEPLOY-DEV"
- 🔧 **Terraform 1.6.6**: Versão estável e compatível
- 📋 **Processo completo**: Init → Plan → Apply → Outputs
- 🚀 **Validação**: Verificação pós-deployment
- 📊 **Outputs**: Recursos criados exibidos

**Fluxo de Execução**:
1. Validação da confirmação
2. Checkout do código
3. Setup Terraform 1.6.6
4. Configuração AWS credentials
5. Terraform init -reconfigure
6. Terraform plan
7. Terraform apply
8. Exibição dos outputs

### 2. **Deploy Production** (`.github/workflows/deploy-prod.yml`)

**Trigger**: Push para branch `prod`

```yaml
on:
  push:
    branches: [ prod ]
    paths:
      - '**.tf'
      - '**.hcl'
      - 'modules/**'
```

**Funcionalidades**:
- 🚀 **Deploy automático**: Execução imediata
- 🔧 **Terraform 1.6.6**: Com validação e verificação de versão
- 📋 **Processo robusto**: Init → Validate → Plan → Apply → Outputs
- ✅ **Validação completa**: Múltiplas verificações
- 📊 **Outputs detalhados**: Recursos criados exibidos

**Fluxo de Execução**:
1. Checkout do código
2. Setup Terraform 1.6.6
3. Verificação da versão do Terraform
4. Configuração AWS credentials
5. Terraform init -reconfigure
6. Terraform validate
7. Terraform plan
8. Terraform apply
9. Exibição dos outputs

### 3. **Destroy Development** (`.github/workflows/destroy-dev.yml`)

**Trigger**: Manual (workflow_dispatch) com confirmação obrigatória

```yaml
on:
  workflow_dispatch:
    inputs:
      confirm:
        description: 'Type "DESTROY-DEV" to confirm destruction'
        required: true
        type: string
```

**Funcionalidades**:
- 🔒 **Confirmação obrigatória**: "DESTROY-DEV"
- 🔧 **Terraform 1.6.6**: Com init -reconfigure
- 🗑️ **Terraform destroy**: Remoção completa
- ✅ **Verificação pós-destruição**: Validação de recursos AWS

**Verificações Pós-Destruição**:
- ECS Cluster status
- RDS Instance status
- Confirmação de recursos removidos

### 4. **Destroy Production** (`.github/workflows/destroy-prod.yml`)

**Trigger**: Manual (workflow_dispatch) com confirmação obrigatória

```yaml
on:
  workflow_dispatch:
    inputs:
      confirm:
        description: 'Type "DESTROY-PRODUCTION" to confirm destruction'
        required: true
        type: string
```

**Funcionalidades**:
- 🔒 **Confirmação obrigatória**: "DESTROY-PRODUCTION"
- ⚠️ **Avisos de segurança**: Alertas adicionais para produção
- 🔧 **Terraform 1.6.6**: Com init -reconfigure
- 🗑️ **Terraform destroy**: Remoção completa
- ✅ **Verificação pós-destruição**: Validação de recursos AWS

**Segurança Adicional**:
- Confirmação específica para produção
- Avisos sobre impacto da destruição
- Verificação dupla de recursos críticos

## 🔧 Configuração

### **GitHub Secrets Necessários**

| Secret | Descrição | Exemplo |
|--------|-----------|----------|
| `AWS_ACCESS_KEY_ID` | AWS Access Key | `AKIA...` |
| `AWS_SECRET_ACCESS_KEY` | AWS Secret Key | `wJalr...` |

### **Backend Configuration**

```hcl
# backend-prod.hcl
bucket  = "tf-nh"
key     = "kiro-tf-bia/prod/terraform.tfstate"
region  = "us-east-1"
encrypt = true
```

**Características**:
- **S3 Bucket**: `tf-nh` para armazenamento de state
- **Encryption**: Habilitada para segurança
- **State Isolation**: Separado por ambiente (dev/prod)
- **No DynamoDB Locking**: Simplificado para confiabilidade

## 📋 Best Practices Implementadas

### **Deployments**
1. ✅ **Dev**: Manual com confirmação "DEPLOY-DEV"
2. ✅ **Prod**: Automático após push para branch prod
3. ✅ **Validação**: Sempre executar pós-deployment
4. ✅ **Monitoramento**: Verificar logs e métricas
5. ✅ **Rollback**: Plano de reversão documentado

### **Destroy Operations**
1. ✅ **Sempre manual**: Nunca automático
2. ✅ **Confirmação obrigatória**: Diferentes por ambiente
3. ✅ **Verificação pós-destruição**: Validar recursos removidos
4. ✅ **Avisos de segurança**: Especialmente para produção
5. ✅ **Backup**: Verificar backups antes da destruição

### **Security**
1. ✅ **Secrets**: Nunca hardcoded, sempre via GitHub Secrets
2. ✅ **Permissions**: Mínimas necessárias
3. ✅ **Confirmações**: Obrigatórias para operações críticas
4. ✅ **Logs**: Não expor informações sensíveis
5. ✅ **Terraform Version**: Fixada para consistência

## 🚨 Troubleshooting

### **Terraform Version Issues**
```bash
# Verificar versão local
terraform version

# Deve ser 1.6.6 ou superior
# Workflows usam exatamente 1.6.6
```

**Solução**: Atualizar Terraform local ou usar mesma versão dos workflows

### **Plan Failures**
```bash
# Verificar backend
terraform init -reconfigure -backend-config=backend-prod.hcl

# Validar configuração
terraform validate

# Debug plan
terraform plan -var="environment=prod" -detailed-exitcode
```

**Causas Comuns**:
- Backend não configurado
- Credenciais AWS inválidas
- Variáveis não definidas
- Recursos já existentes

### **Backend Issues**
```bash
# Verificar se bucket S3 existe
aws s3 ls s3://tf-nh

# Verificar permissões
aws s3api get-bucket-policy --bucket tf-nh

# Reconfigurar backend se necessário
terraform init -reconfigure -backend-config=backend-prod.hcl
```

**Soluções**:
- Criar bucket S3 se não existir
- Verificar permissões IAM
- Usar -reconfigure para forçar reconfiguração

### **GitHub Actions Failures**

#### **Erro: "unsupported checkable object kind"**
✅ **Status**: **RESOLVIDO** com Terraform 1.6.6

**Causa**: Incompatibilidade da versão 1.5.0 com validações
**Solução**: Atualização para 1.6.6 em todos os workflows

#### **Erro: "Backend configuration changed"**
```bash
# Usar -reconfigure nos workflows
terraform init -reconfigure -backend-config=backend-prod.hcl
```

#### **Erro: "Access Denied"**
- Verificar GitHub Secrets configurados
- Verificar permissões IAM da AWS
- Verificar região AWS (us-east-1)

### **Debugging Workflows**

1. **Verificar logs detalhados** no GitHub Actions
2. **Terraform version step** mostra versão usada
3. **Terraform validate step** detecta erros de configuração
4. **AWS credentials** verificadas automaticamente
5. **Outputs step** mostra recursos criados/modificados

## 📊 Monitoring e Alertas

### **Workflow Monitoring**
- **GitHub Actions**: Logs detalhados de cada step
- **Notifications**: Configurar para falhas
- **Status badges**: Adicionar ao README
- **Metrics**: Tempo de execução e taxa de sucesso

### **Infrastructure Monitoring**
- **CloudWatch**: Logs e métricas dos recursos
- **AWS Config**: Compliance e mudanças
- **Cost Explorer**: Monitoramento de custos
- **Security Hub**: Alertas de segurança

## 📞 Support

Para problemas com CI/CD:

1. **Verificar workflow logs** no GitHub Actions
2. **Executar validação local** com `./validate-local.sh`
3. **Verificar configurações de backend**
4. **Consultar troubleshooting** acima
5. **Verificar GitHub Secrets** configurados
6. **Testar credenciais AWS** localmente

---

**Versão**: 2.3 - Pipeline Otimizado e Documentado  
**Última atualização**: 27 de Janeiro de 2025  
**Terraform Version**: 1.6.6  
**Status**: ✅ Funcionando perfeitamente