# 🔧 Guia Operacional - Infraestrutura BIA

Este documento é um guia prático para operadores, analistas e desenvolvedores que precisam trabalhar com a infraestrutura BIA.

## 📋 Índice

- [Configurações Principais](#configurações-principais)
- [Ambientes](#ambientes)
- [Alterando Configurações](#alterando-configurações)
- [Deploy Manual](#deploy-manual)
- [CI/CD GitHub Actions](#cicd-github-actions)
- [Troubleshooting](#troubleshooting)
- [Comandos Úteis](#comandos-úteis)

## 🎯 Configurações Principais

### 📁 Arquivo: `terraform/locals.tf`
**Este é o arquivo MAIS IMPORTANTE para configurações por ambiente.**

```hcl
env_config = {
  dev = {
    instance_type           = "t3.micro"        # Tipo da instância EC2
    rds_instance_class      = "db.t3.micro"     # Tipo da instância RDS
    container_cpu           = 1024              # CPU do container (1024 = 1 vCPU)
    container_memory        = 512               # Memória do container (MB)
    multi_az                = false             # RDS Multi-AZ (false = economia)
    backup_retention_period = 1                # Dias de backup RDS
    min_capacity            = 1                 # Mínimo de instâncias
    max_capacity            = 4                 # Máximo de instâncias
    desired_capacity        = 1                 # Instâncias iniciais
    cpu_scale_target        = 70.0              # % CPU para autoscaling
    memory_scale_target     = 75.0              # % Memória para autoscaling
    use_private_subnets     = false             # ECS em subnets privadas?
    create_nat_gateway      = false             # Criar NAT Gateway?
  }
  prod = {
    # Configurações similares para produção
  }
}
```

### 📁 Arquivo: `terraform/variables.tf`
**Variáveis globais do projeto.**

```hcl
variable "aws_region" {
  default = "us-east-1"  # ← Altere aqui para mudar região
}

variable "key_name" {
  default = "nholanda"   # ← Altere aqui para sua chave SSH
}

variable "ecr_repository_url" {
  default = "194722426008.dkr.ecr.us-east-1.amazonaws.com/bia"  # ← URL do ECR
}
```

## 🌍 Ambientes

### Desenvolvimento (dev)
- **Branch**: `dev`
- **Backend S3**: `s3://tf-nh/kiro-tf-bia/dev/terraform.tfstate`
- **Características**: Economia de custos, sem NAT Gateway
- **Deploy**: Automático via push para branch `dev`

### Produção (prod)
- **Branch**: `bia-v1`
- **Backend S3**: `s3://tf-nh/kiro-tf-bia/prod/terraform.tfstate`
- **Características**: Alta disponibilidade, com NAT Gateway
- **Deploy**: Automático via push para branch `bia-v1`

## ⚙️ Alterando Configurações

### 🔄 Para alterar capacidade de instâncias:
```hcl
# Em terraform/locals.tf
dev = {
  min_capacity     = 2    # ← Mínimo de instâncias
  max_capacity     = 6    # ← Máximo de instâncias
  desired_capacity = 2    # ← Instâncias iniciais
}
```

### 📊 Para alterar thresholds de autoscaling:
```hcl
# Em terraform/locals.tf
dev = {
  cpu_scale_target    = 80.0   # ← CPU > 80% = scale out
  memory_scale_target = 85.0   # ← Memory > 85% = scale out
}
```

### 💾 Para alterar configurações do RDS:
```hcl
# Em terraform/locals.tf
dev = {
  rds_instance_class      = "db.t3.small"  # ← Tipo da instância
  multi_az                = true           # ← Multi-AZ
  backup_retention_period = 7              # ← Dias de backup
}
```

### 🖥️ Para alterar tipo de instância EC2:
```hcl
# Em terraform/locals.tf
dev = {
  instance_type = "t3.small"  # ← t3.micro, t3.small, t3.medium, etc.
}
```

### 🐳 Para alterar recursos do container:
```hcl
# Em terraform/locals.tf
dev = {
  container_cpu    = 2048  # ← 1024 = 1 vCPU, 2048 = 2 vCPU
  container_memory = 1024  # ← Memória em MB
}
```

## 🚀 Deploy Manual

### Pré-requisitos:
```bash
# 1. AWS CLI configurado
aws configure

# 2. Terraform instalado
terraform --version

# 3. Estar no diretório correto
cd terraform/
```

### Comandos de Deploy:
```bash
# Planejar mudanças (recomendado sempre)
./deploy.sh dev plan
./deploy.sh prod plan

# Aplicar mudanças
./deploy.sh dev apply
./deploy.sh prod apply

# Validar ambiente
./validate.sh dev
./validate.sh prod

# Destruir ambiente (CUIDADO!)
./deploy.sh dev destroy
./deploy.sh prod destroy
```

## 🤖 CI/CD GitHub Actions

### Configuração de Secrets:
No GitHub, configure em **Settings > Secrets and variables > Actions**:
- `AWS_ACCOUNT_ID`: ID da conta AWS (ex: 194722426008)

### Role IAM:
- **Nome**: `GIT_ACTIONS`
- **Tipo**: Role para GitHub Actions OIDC
- **Já configurada**: ✅

### Fluxo Automático:

#### Para Desenvolvimento:
1. Faça push para branch `dev`
2. GitHub Actions executa automaticamente
3. Valida → Testa → Aplica

#### Para Produção:
1. Faça push para branch `bia-v1`
2. GitHub Actions executa automaticamente
3. Valida → Testa → Aplica (com aprovação manual)

### Arquivos de Workflow:
- `.github/workflows/main.yml` - Workflow reutilizável
- `.github/workflows/terraform-dev.yml` - Workflow para dev
- `.github/workflows/terraform-prod.yml` - Workflow para prod

## 🔍 Troubleshooting

### Problema: "Backend initialization failed"
```bash
# Solução: Verificar acesso ao S3
aws s3 ls s3://tf-nh/kiro-tf-bia/

# Reconfigurar backend
terraform init -backend-config="backend-dev.hcl" -reconfigure
```

### Problema: "Resource already exists"
```bash
# Solução: Importar recurso existente
terraform import module.vpc.aws_vpc.main vpc-xxxxxxxxx

# Ou remover do state
terraform state rm module.vpc.aws_vpc.main
```

### Problema: "ECS tasks não inicializam"
```bash
# Verificar logs
aws logs tail /ecs/bia-dev --follow

# Verificar service
aws ecs describe-services --cluster bia-dev-cluster --services bia-dev-service
```

### Problema: "Auto Scaling não funciona"
```bash
# Verificar métricas
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ServiceName,Value=bia-dev-service \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-01T23:59:59Z \
  --period 300 \
  --statistics Average
```

## 📝 Comandos Úteis

### Terraform:
```bash
# Ver estado atual
terraform state list

# Ver outputs
terraform output

# Ver plano detalhado
terraform plan -detailed-exitcode

# Aplicar apenas um módulo
terraform apply -target=module.vpc

# Refresh do estado
terraform refresh
```

### AWS CLI:
```bash
# Listar clusters ECS
aws ecs list-clusters

# Ver instâncias do Auto Scaling Group
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names bia-dev-asg

# Ver status do RDS
aws rds describe-db-instances --db-instance-identifier bia-dev-db

# Ver logs do CloudWatch
aws logs describe-log-groups --log-group-name-prefix /ecs/bia
```

### Monitoramento:
```bash
# CPU do ECS Service
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ServiceName,Value=bia-dev-service Name=ClusterName,Value=bia-dev-cluster \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average

# Memória do ECS Service
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name MemoryUtilization \
  --dimensions Name=ServiceName,Value=bia-dev-service Name=ClusterName,Value=bia-dev-cluster \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average
```

## 🎯 Checklist de Deploy

### Antes do Deploy:
- [ ] Revisar mudanças no `terraform plan`
- [ ] Verificar se o ambiente está saudável
- [ ] Backup do estado atual (se necessário)
- [ ] Comunicar mudanças para a equipe

### Após o Deploy:
- [ ] Verificar se todos os recursos foram criados
- [ ] Testar conectividade da aplicação
- [ ] Verificar logs no CloudWatch
- [ ] Confirmar métricas de monitoramento
- [ ] Documentar mudanças realizadas

## 📞 Suporte

Para dúvidas ou problemas:
1. Consulte este documento primeiro
2. Verifique os logs do GitHub Actions
3. Consulte os logs do CloudWatch
4. Entre em contato com a equipe de infraestrutura

---

**💡 Dica**: Sempre execute `terraform plan` antes de `terraform apply` para revisar as mudanças que serão feitas!