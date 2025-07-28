# 🔧 Guia Técnico para Alterações na Infraestrutura

## 📋 Visão Geral

Este documento fornece instruções detalhadas sobre como fazer alterações na infraestrutura BIA usando Terraform, incluindo boas práticas, procedimentos de segurança e fluxos de trabalho recomendados.

## 🏗️ Estrutura do Projeto

### **Arquivos Principais**
```
bia-kiro-tf/
├── main.tf                    # Configuração principal - chama todos os módulos
├── variables.tf               # Definições de variáveis globais
├── locals.tf                 # Configurações específicas por ambiente
├── outputs.tf                # Outputs expostos do Terraform
├── terraform.tfvars          # Valores para desenvolvimento
├── terraform-prod.tfvars     # Valores para produção
├── backend-dev.hcl           # Configuração do backend S3 para dev
└── backend-prod.hcl          # Configuração do backend S3 para prod
```

### **Módulos Terraform**
```
modules/
├── alb/                      # Application Load Balancer
├── cloudwatch/               # Logs e monitoramento
├── ecs-cluster/              # Cluster ECS com Auto Scaling
├── ecs-service/              # Serviço ECS e Task Definition
├── iam/                      # Roles e políticas IAM
├── kms/                      # Chaves de criptografia (prod only)
├── rds/                      # Banco PostgreSQL
├── security-groups/          # Security Groups
├── vpc/                      # VPC, subnets, gateways
└── waf/                      # Web Application Firewall (prod only)
```

## 🔄 Fluxo de Alterações

### **1. Preparação**
```bash
# Verificar ambiente atual
aws sts get-caller-identity

# Verificar versão do Terraform
terraform version

# Fazer backup do state atual (opcional)
terraform show > backup-state-$(date +%Y%m%d).txt
```

### **2. Desenvolvimento Local**
```bash
# Método recomendado (com limpeza automática)
./deploy.sh dev plan    # Para planejar
./deploy.sh dev apply   # Para aplicar

# Método manual (se necessário)
# Inicializar para desenvolvimento
terraform init -backend-config=backend-dev.hcl -reconfigure

# Limpar secrets órfãos (importante!)
./cleanup-secrets.sh dev

# Validar sintaxe
terraform validate

# Verificar plano de alterações
terraform plan

# Aplicar alterações (após revisão)
terraform apply
```

### **3. Produção**
```bash
# Método recomendado (com limpeza automática)
./deploy.sh prod plan    # Para planejar
./deploy.sh prod apply   # Para aplicar

# Método manual (se necessário)
# Inicializar para produção
terraform init -backend-config=backend-prod.hcl -reconfigure

# Limpar secrets órfãos (importante!)
./cleanup-secrets.sh prod

# Verificar plano com variáveis de produção
terraform plan -var-file=terraform-prod.tfvars

# Aplicar alterações (após revisão)
terraform apply -var-file=terraform-prod.tfvars
```

## 📝 Tipos Comuns de Alterações

### **A. Modificar Configurações de Recursos Existentes**

**Exemplo: Alterar tipo de instância ECS**
```hcl
# Em locals.tf
locals {
  environments = {
    dev = {
      # ... outras configurações
      ecs_instance_type = "t3.small"  # Era t3.micro
    }
    prod = {
      # ... outras configurações  
      ecs_instance_type = "t3.medium" # Era t3.small
    }
  }
}
```

**Exemplo: Modificar configurações do RDS**
```hcl
# Em terraform-prod.tfvars
rds_instance_class = "db.t3.small"  # Era db.t3.micro
rds_allocated_storage = 100         # Era 20
```

### **B. Adicionar Novos Recursos**

**1. Criar novo módulo**
```bash
mkdir modules/novo-recurso
touch modules/novo-recurso/{main.tf,variables.tf,outputs.tf}
```

**2. Definir o recurso**
```hcl
# modules/novo-recurso/main.tf
resource "aws_exemplo" "main" {
  name = "${var.project_name}-${var.environment}-exemplo"
  
  tags = var.tags
}
```

**3. Adicionar variáveis**
```hcl
# modules/novo-recurso/variables.tf
variable "project_name" {
  description = "Nome do projeto"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev/prod)"
  type        = string
}

variable "tags" {
  description = "Tags padrão"
  type        = map(string)
}
```

**4. Expor outputs**
```hcl
# modules/novo-recurso/outputs.tf
output "recurso_id" {
  description = "ID do recurso criado"
  value       = aws_exemplo.main.id
}
```

**5. Chamar o módulo**
```hcl
# main.tf
module "novo_recurso" {
  source = "./modules/novo-recurso"
  
  project_name = var.project_name
  environment  = var.environment
  tags         = local.common_tags
}
```

### **C. Modificar Security Groups**

**Adicionar nova regra de ingress**
```hcl
# modules/security-groups/main.tf
resource "aws_security_group" "exemplo" {
  # ... configurações existentes
  
  ingress {
    description = "Nova regra HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }
}
```

### **D. Atualizar Políticas IAM**

**Adicionar nova permissão**
```hcl
# modules/iam/main.tf
resource "aws_iam_policy" "exemplo" {
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # ... statements existentes
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          "arn:aws:s3:::meu-bucket/*"
        ]
      }
    ]
  })
}
```

## 🔒 Considerações de Segurança

### **Recursos Sensíveis**
- **KMS Keys**: Alterações podem quebrar criptografia existente
- **IAM Roles**: Mudanças podem afetar permissões de aplicações
- **Security Groups**: Alterações podem expor recursos
- **RDS**: Modificações podem causar downtime

### **Validações Obrigatórias**
```bash
# Antes de aplicar em produção
terraform plan -var-file=terraform-prod.tfvars -out=plan.out
terraform show plan.out | grep -E "(destroy|replace)"

# Verificar se há recursos sendo destruídos/recriados
# Se sim, avaliar impacto antes de prosseguir
```

### **Backup de Dados**
```bash
# Para alterações no RDS, fazer backup antes
aws rds create-db-snapshot \
  --db-instance-identifier bia-prod-db \
  --db-snapshot-identifier bia-prod-backup-$(date +%Y%m%d-%H%M)
```

## 🚨 Procedimentos de Emergência

### **Rollback de Alterações**
```bash
# 1. Reverter código para versão anterior
git checkout HEAD~1

# 2. Aplicar estado anterior
terraform apply -var-file=terraform-prod.tfvars

# 3. Ou usar backup do state (se disponível)
terraform state pull > current-state.json
# Restaurar backup manualmente se necessário
```

### **Recuperação de Recursos Deletados**
```bash
# 1. Verificar se recurso ainda existe na AWS
aws ecs describe-clusters --clusters bia-prod-cluster

# 2. Importar recurso existente
terraform import module.ecs_cluster.aws_ecs_cluster.main arn:aws:ecs:...

# 3. Aplicar configuração
terraform apply -var-file=terraform-prod.tfvars
```

## 📊 Monitoramento de Alterações

### **Verificação Pós-Deploy**
```bash
# Verificar status dos serviços
aws ecs describe-services --cluster bia-prod-cluster --services bia-prod-service

# Verificar logs
aws logs describe-log-groups --log-group-name-prefix "/ecs/bia"

# Verificar métricas
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ServiceName,Value=bia-prod-service \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average
```

### **Logs de Auditoria**
```bash
# Verificar eventos do CloudTrail
aws logs filter-log-events \
  --log-group-name CloudTrail/BIA \
  --start-time $(date -d '1 hour ago' +%s)000 \
  --filter-pattern "{ $.eventName = CreateService || $.eventName = UpdateService }"
```

## 🔧 Troubleshooting

### **Problemas Comuns**

**1. State Lock**
```bash
# Se o state estiver travado
terraform force-unlock LOCK_ID
```

**2. Drift de Configuração**
```bash
# Sincronizar com estado real da AWS
terraform refresh -var-file=terraform-prod.tfvars

# Verificar diferenças
terraform plan -var-file=terraform-prod.tfvars
```

**3. Recursos Órfãos**
```bash
# Listar recursos não gerenciados pelo Terraform
aws resourcegroupstaggingapi get-resources \
  --tag-filters Key=ManagedBy,Values=Manual
```

**4. Permissões Insuficientes**
```bash
# Verificar permissões atuais
aws iam simulate-principal-policy \
  --policy-source-arn $(aws sts get-caller-identity --query Arn --output text) \
  --action-names ecs:CreateService \
  --resource-arns "*"
```

## 📋 Checklist de Alterações

### **Antes de Aplicar**
- [ ] Código validado com `terraform validate`
- [ ] Plano revisado com `terraform plan`
- [ ] Backup do state atual realizado
- [ ] Recursos críticos identificados
- [ ] Janela de manutenção agendada (se necessário)
- [ ] Equipe notificada sobre alterações

### **Durante a Aplicação**
- [ ] Monitorar logs em tempo real
- [ ] Verificar métricas de saúde
- [ ] Confirmar que serviços continuam funcionando
- [ ] Documentar qualquer comportamento inesperado

### **Após a Aplicação**
- [ ] Verificar status de todos os recursos
- [ ] Executar testes de conectividade
- [ ] Confirmar que aplicação está respondendo
- [ ] Atualizar documentação
- [ ] Commit das alterações no Git

## 📞 Contatos de Emergência

- **Responsável Técnico**: Nelson Holanda
- **Escalação**: Equipe de DevOps
- **Documentação**: Este repositório
- **Monitoramento**: AWS CloudWatch Console

---

**Versão**: 1.0  
**Última atualização**: 28 de Julho de 2025  
**Mantido por**: Nelson Holanda