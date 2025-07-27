# 🚀 BIA ECS Infrastructure

Este projeto contém a infraestrutura como código (IaC) para o sistema BIA usando Terraform na AWS com suporte a múltiplos ambientes e CI/CD automatizado.

## 🏗️ Arquitetura

A infraestrutura é composta por:

- **VPC** com subnets públicas e privadas Multi-AZ
- **ECS Cluster** com Auto Scaling de instâncias EC2
- **ECS Service** com Auto Scaling de tasks baseado em CPU
- **Application Load Balancer (ALB)** para distribuição de tráfego
- **RDS PostgreSQL 17.4** Multi-AZ para produção
- **WAF** para proteção contra ataques web (produção)
- **KMS** para criptografia de dados em repouso
- **Secrets Manager** para gerenciamento seguro de credenciais
- **CloudWatch** para logs e monitoramento
- **IAM** roles e policies com menor privilégio
- **Security Groups** para controle de acesso granular

## 📁 Estrutura do Projeto

```
├── main.tf                      # Configuração principal
├── variables.tf                 # Variáveis do projeto
├── locals.tf                   # Configurações por ambiente
├── outputs.tf                  # Outputs do Terraform
├── backend-dev.hcl             # Backend S3 para dev
├── backend-prod.hcl            # Backend S3 para prod
├── deploy.sh                   # Script de deploy
├── setup-secrets.sh            # Script para secrets
├── validate-local.sh           # Validação local
├── .github/workflows/          # GitHub Actions
│   ├── deploy-dev.yml          # Deploy manual dev
│   ├── deploy-prod.yml         # Deploy automático prod
│   ├── destroy-dev.yml         # Destroy manual dev
│   └── destroy-prod.yml        # Destroy manual prod
└── modules/                    # Módulos Terraform
    ├── vpc/                    # VPC e networking
    ├── ecs-cluster/            # ECS Cluster
    ├── ecs-service/            # ECS Service
    ├── alb/                    # Load Balancer
    ├── rds/                    # Database
    ├── waf/                    # Web Application Firewall
    ├── kms/                    # Key Management Service
    ├── iam/                    # Identity and Access Management
    ├── security-groups/        # Security Groups
    └── cloudwatch/             # Monitoring
```

## 🚀 Quick Start

### 1. **Configurar Credenciais AWS**
```bash
# Configure suas credenciais AWS
aws configure
```

### 2. **Configurar Secrets**
```bash
# Execute o script de setup de secrets
./setup-secrets.sh dev    # Para desenvolvimento
./setup-secrets.sh prod   # Para produção
```

### 3. **Deploy Local**
```bash
# Deploy para desenvolvimento
./deploy.sh dev

# Deploy para produção
./deploy.sh prod
```

### 4. **Validação Local**
```bash
# Validar configuração
./validate-local.sh dev
```

## 🔄 CI/CD Workflows

### **Deploy Development**
- **Trigger**: Manual com confirmação "DEPLOY-DEV"
- **Terraform**: v1.6.6 com init -reconfigure
- **Processo**: Init → Plan → Apply → Validate

### **Deploy Production**
- **Trigger**: Automático no push para branch `prod`
- **Terraform**: v1.6.6 com validação completa
- **Processo**: Init → Validate → Plan → Apply → Validate

### **Destroy Operations**
- **Dev**: Manual com confirmação "DESTROY-DEV"
- **Prod**: Manual com confirmação "DESTROY-PRODUCTION"
- **Verificação**: Validação pós-destruição de recursos AWS

## 🔧 Configuração por Ambiente

### **Desenvolvimento (dev)**
- **VPC CIDR**: `172.16.48.0/20`
- **RDS**: Single-AZ, db.t3.micro
- **ECS**: 1-4 instâncias, t3.micro
- **Backup**: 1 dia de retenção
- **KMS**: Desabilitado

### **Produção (prod)**
- **VPC CIDR**: `172.16.0.0/20`
- **RDS**: Multi-AZ, db.t3.small
- **ECS**: 2-6 instâncias, t3.small
- **Backup**: 30 dias de retenção
- **KMS**: Habilitado
- **WAF**: Habilitado
- **Container Insights**: Habilitado

## 📊 Recursos AWS Criados

### **Networking**
- 1 VPC com 6 subnets (3 públicas, 3 privadas)
- 1 Internet Gateway
- 1 NAT Gateway (produção)
- Route Tables e Security Groups

### **Compute**
- 1 ECS Cluster com Capacity Provider
- Auto Scaling Group para EC2 instances
- ECS Service com Auto Scaling de tasks

### **Database**
- 1 RDS PostgreSQL instance
- Secrets Manager para credenciais
- KMS encryption (produção)

### **Load Balancing**
- 1 Application Load Balancer
- Target Group com health checks
- WAF protection (produção)

### **Monitoring**
- CloudWatch Log Groups
- CloudWatch Alarms para Auto Scaling
- Container Insights (produção)

## 🔒 Segurança

### **Criptografia**
- **Em repouso**: KMS para RDS e Secrets Manager
- **Em trânsito**: HTTPS/TLS para todas as comunicações
- **State files**: Criptografados no S3

### **Network Security**
- **Security Groups**: Princípio do menor privilégio
- **Subnets privadas**: RDS isolado da internet
- **WAF**: Proteção contra ataques web (produção)

### **Access Control**
- **IAM Roles**: Permissões mínimas necessárias
- **Secrets Manager**: Credenciais não hardcoded
- **Resource tagging**: Para auditoria e compliance

## 📚 Documentação Adicional

- **[CI/CD Documentation](./CI_CD_README.md)** - Detalhes dos workflows
- **[Secrets Setup](./SECRETS_SETUP.md)** - Configuração de credenciais
- **[Validation Report](./VALIDATION_REPORT.md)** - Relatório de conformidade

## 🆘 Troubleshooting

### **Problemas Comuns**

#### **Terraform Version Issues**
```bash
# Verificar versão (deve ser 1.6.6+)
terraform version
```

#### **Backend Issues**
```bash
terraform init -reconfigure -backend-config=backend-prod.hcl
```

#### **Plan Failures**
```bash
terraform validate
terraform plan -var="environment=prod" -detailed-exitcode
```

#### **GitHub Actions Errors**
```bash
# Verificar se erro "unsupported checkable object kind" foi resolvido
# Workflows agora usam Terraform 1.6.6 com melhor compatibilidade
```

#### **AWS Credentials**
```bash
aws sts get-caller-identity
aws configure list
```

## 🏷️ Tags Padrão

Todos os recursos são taggeados com:
- **Environment**: dev/prod
- **Project**: BIA
- **ManagedBy**: Terraform
- **Owner**: Nelson Holanda
- **CostCenter**: Engineering
- **Application**: BIA

## 📞 Suporte

Para problemas ou dúvidas:
1. Verificar logs do GitHub Actions
2. Executar validação local
3. Consultar documentação específica
4. Verificar configurações de backend

---

**Versão**: 2.0 - Otimizada e Validada  
**Última atualização**: 27 de Janeiro de 2025