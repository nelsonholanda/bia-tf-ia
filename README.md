# 🚀 BIA ECS Infrastructure

Este projeto contém a infraestrutura como código (IaC) para o sistema BIA usando Terraform na AWS com suporte a múltiplos ambientes e CI/CD automatizado.

## 📋 Documentação Completa

**📖 [Manual Técnico Completo (HTML)](./DOCUMENTATION.html)** - Documentação detalhada com instruções para alterar configurações

## 🏗️ Arquitetura

A infraestrutura é composta por:

- **VPC** com subnets públicas e privadas (CIDRs separados por ambiente)
- **ECS Cluster** com Auto Scaling de instâncias EC2 (1-4 instâncias)
- **ECS Service** com Auto Scaling de tasks (1-10 tasks, CPU 70%)
- **Application Load Balancer (ALB)** para distribuição de tráfego
- **RDS PostgreSQL 17.4** para banco de dados
- **CloudWatch** para logs e monitoramento
- **IAM** roles e policies com menor privilégio
- **Security Groups** para controle de acesso granular

## Estrutura do Projeto

```
terraform/
├── main.tf                      # Configuração principal
├── variables.tf                 # Variáveis do projeto
├── locals.tf                   # Valores locais e configurações por ambiente
├── outputs.tf                  # Outputs do Terraform
├── deploy.sh                   # Script de deploy automatizado
├── setup-secrets.sh            # Script para configurar secrets
├── backend-dev.hcl             # Configuração do backend S3 para dev
├── backend-prod.hcl            # Configuração do backend S3 para prod
├── SECRETS_SETUP.md            # Documentação detalhada dos secrets
├── .github/workflows/          # GitHub Actions workflows
│   ├── terraform-dev.yml       # CI/CD para ambiente dev
│   └── terraform-prod.yml      # CI/CD para ambiente prod
└── modules/                    # Módulos Terraform
    ├── vpc/                    # Módulo VPC
    ├── ecs-cluster/            # Módulo ECS Cluster
    ├── ecs-service/            # Módulo ECS Service
    ├── alb/                    # Módulo Application Load Balancer
    ├── rds/                    # Módulo RDS (inclui secrets)
    ├── iam/                    # Módulo IAM
    ├── security-groups/        # Módulo Security Groups
    └── cloudwatch/             # Módulo CloudWatch
```

## 🔄 Estratégia de Branches e CI/CD

### Branch `dev` (Homologação)
- **Propósito**: Testes e validação
- **Ambiente**: Desenvolvimento (dev)
- **CI/CD**: Deploy **MANUAL** (requer confirmação "DEPLOY-DEV")
- **Recursos**: Otimizado para custos, sem NAT Gateway
- **Rede**: ECS em subnets públicas

### Branch `prod` (Produção)
- **Propósito**: Ambiente de produção
- **Ambiente**: Produção (prod)
- **CI/CD**: Deploy **AUTOMÁTICO** em push para branch `prod`
- **Recursos**: Configuração completa com NAT Gateway
- **Rede**: ECS em subnets privadas

## 🌍 Ambientes

### Desenvolvimento (dev)
- **VPC CIDR**: 172.16.48.0/20
- **EC2 Instâncias**: 1-4 (Auto Scaling baseado em CPU 70%/30%)
- **ECS Tasks**: 1-10 (Auto Scaling baseado em CPU 70%)
- **Rede**: ECS em subnets públicas
- **NAT Gateway**: Não (economia de custos)
- **RDS**: db.t3.micro, backup 1 dia, single-AZ
- **Deploy**: Manual com confirmação

### Produção (prod)
- **VPC CIDR**: 172.16.0.0/20
- **EC2 Instâncias**: 1-4 (Auto Scaling baseado em CPU 70%/30%)
- **ECS Tasks**: 1-10 (Auto Scaling baseado em CPU 70%)
- **Rede**: ECS em subnets privadas
- **NAT Gateway**: Sim (segurança)
- **RDS**: db.t3.micro, backup 7 dias, single-AZ
- **Deploy**: Automático

## 🔐 Gerenciamento de Secrets

O projeto utiliza AWS Secrets Manager para armazenar credenciais do banco de dados com nomenclatura padronizada:

- **Dev**: `bia-dev-secrets`
- **Prod**: `bia-prod-secrets`

### Estrutura do Secret
```json
{
  "username": "postgres",
  "password": "generated_password",
  "engine": "postgres",
  "host": "hostname_only",
  "port": 5432,
  "dbname": "bia"
}
```

## Como Usar

### Pré-requisitos

1. AWS CLI configurado
2. Terraform >= 1.0 instalado
3. Permissões adequadas na AWS

### Deploy Manual

```bash
# Deploy ambiente de desenvolvimento
./deploy.sh dev apply

# Deploy ambiente de produção
./deploy.sh prod apply

# Planejar mudanças (sem aplicar)
./deploy.sh dev plan
./deploy.sh prod plan

# Destruir ambiente (cuidado!)
./deploy.sh dev destroy
./deploy.sh prod destroy
```

### Scripts Essenciais

```bash
# Configurar secrets iniciais
./setup-secrets.sh dev
./setup-secrets.sh prod
```

### Deploy Automatizado (CI/CD)

#### Para Desenvolvimento (Manual):
1. Vá para GitHub Actions
2. Execute workflow "Deploy Development"
3. Digite "DEPLOY-DEV" para confirmar
4. Aguarde conclusão do deploy

#### Para Produção (Automático):
1. Faça push para a branch `prod`
2. GitHub Actions executará automaticamente:
   - Terraform init, plan e apply
   - Deploy no ambiente prod

#### Para Destruir Recursos:
- **DEV**: Execute workflow "Destroy Development" e digite "DESTROY-DEV"
- **PROD**: Execute workflow "Destroy Production" e digite "DESTROY-PROD"

## 🔍 Troubleshooting

### Problemas Comuns

#### 1. Secrets não encontrados
```bash
# Verificar se o secret existe
aws secretsmanager describe-secret --secret-id bia-dev-secrets

# Recriar secrets se necessário
./setup-secrets.sh dev
```

#### 2. Serviço ECS não atualizado
```bash
# Forçar nova implantação via AWS CLI
aws ecs update-service --cluster bia-dev-cluster --service bia-dev-service --force-new-deployment
```

## ⚙️ Configuração por Ambiente

As configurações específicas de cada ambiente estão definidas no arquivo `locals.tf`:

### Auto Scaling Separado:
- **ECS Tasks**: 1-10 tasks, CPU 70% (independente)
- **EC2 Instâncias**: 1-4 instâncias, CPU 70%/30% (independente)

### Principais Configurações:
- **Tipos de instância**: t3.micro para ambos ambientes
- **RDS**: PostgreSQL 17.4, db.t3.micro
- **Containers**: 1024 CPU units, 307-512 MB memory
- **Rede**: CIDRs separados, NAT Gateway apenas em prod
- **Backup**: 1 dia (dev), 7 dias (prod)

## GitHub Actions

### Secrets Necessários

Configure os seguintes secrets no GitHub:

- `AWS_ACCESS_KEY_ID`: Access Key da AWS
- `AWS_SECRET_ACCESS_KEY`: Secret Key da AWS

### Workflows

#### terraform-dev.yml
- **Trigger**: Push/PR para branch `dev`
- **Ambiente**: Desenvolvimento
- **Ações**: Validate → Test → Plan → Apply

#### terraform-prod.yml
- **Trigger**: Push/PR para branch `bia-v1`
- **Ambiente**: Produção
- **Ações**: Validate → Test → Plan → Apply (com aprovação)

## Segurança

- Security Groups configurados com acesso mínimo necessário
- ECS em subnets privadas em produção (sem IP público)
- RDS sempre em subnets privadas
- IAM roles com princípio de menor privilégio
- NAT Gateway apenas em produção para acesso controlado à internet

## Monitoramento

- CloudWatch Logs para containers ECS
- Auto Scaling baseado em métricas de CPU (70%) e memória (75%)
- Health checks configurados no ALB
- Métricas de performance e utilização

## Custos

- Ambiente dev otimizado para custos (sem NAT Gateway)
- Ambiente prod com NAT Gateway para segurança
- Instâncias t3.micro para ambos ambientes
- Auto Scaling para otimização de recursos
- Configuração de 1-4 instâncias conforme demanda

## Fluxo de Trabalho

1. **Desenvolvimento**: Trabalhe na branch `dev` para testes e validações
2. **Testes**: Todos os fluxos são testados no ambiente dev primeiro
3. **Produção**: Merge/push para `bia-v1` para deploy em produção
4. **Validação**: CI/CD automatizado garante qualidade em ambos ambientes

## Suporte

Para dúvidas ou problemas:
- Consulte a documentação dos módulos individuais
- Verifique os logs do GitHub Actions
- Entre em contato com a equipe de infraestrutura

## 🔗 URLs dos Ambientes

- **Dev**: Disponível após deploy via ALB DNS name
- **Prod**: Disponível após deploy via ALB DNS name

Use `terraform output alb_dns_name` para obter a URL atual.

## 📚 Recursos Adicionais

- **[Manual Técnico Completo](./DOCUMENTATION.html)** - Instruções detalhadas para configuração
- **Módulos Terraform** - Documentação em cada diretório `modules/`
- **GitHub Actions** - Workflows em `.github/workflows/`

## 🚨 Importante

- **DEV**: Deploy manual para controle de homologação
- **PROD**: Deploy automático para agilidade em produção
- **Auto Scaling**: Dois níveis independentes (tasks e instâncias)
- **Segurança**: Subnets privadas em produção, públicas em dev