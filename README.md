# BIA ECS Infrastructure

Este projeto contém a infraestrutura como código (IaC) para o sistema BIA usando Terraform na AWS com suporte a múltiplos ambientes e CI/CD automatizado.

## Arquitetura

A infraestrutura é composta por:

- **VPC** com subnets públicas e privadas
- **ECS Cluster** com Auto Scaling
- **Application Load Balancer (ALB)**
- **RDS PostgreSQL** para banco de dados
- **CloudWatch** para logs
- **IAM** roles e policies
- **Security Groups** para controle de acesso

## Estrutura do Projeto

```
terraform/
├── main.tf                 # Configuração principal
├── variables.tf            # Variáveis do projeto
├── locals.tf              # Valores locais e configurações por ambiente
├── outputs.tf             # Outputs do Terraform
├── deploy.sh              # Script de deploy automatizado
├── validate.sh            # Script de validação
├── test.sh                # Script de testes automatizados
├── backend-dev.hcl        # Configuração do backend S3 para dev
├── backend-prod.hcl       # Configuração do backend S3 para prod
├── .github/workflows/     # GitHub Actions workflows
│   ├── terraform-dev.yml  # CI/CD para ambiente dev
│   └── terraform-prod.yml # CI/CD para ambiente prod
└── modules/               # Módulos Terraform
    ├── vpc/               # Módulo VPC
    ├── ecs-cluster/       # Módulo ECS Cluster
    ├── ecs-service/       # Módulo ECS Service
    ├── alb/               # Módulo Application Load Balancer
    ├── rds/               # Módulo RDS
    ├── iam/               # Módulo IAM
    ├── security-groups/   # Módulo Security Groups
    └── cloudwatch/        # Módulo CloudWatch
```

## Estratégia de Branches

### Branch `dev`
- **Propósito**: Desenvolvimento e testes
- **Ambiente**: Desenvolvimento (dev)
- **CI/CD**: Deploy automático em push para branch `dev`
- **Recursos**: Otimizado para custos, sem NAT Gateway

### Branch `bia-v1`
- **Propósito**: Produção estável
- **Ambiente**: Produção (prod)
- **CI/CD**: Deploy automático em push para branch `bia-v1`
- **Recursos**: Configuração completa com NAT Gateway

## Ambientes

### Desenvolvimento (dev)
- **Instâncias**: 1-4 (mínimo 1, máximo 4, inicial 1)
- **Rede**: ECS em subnets públicas (sem IP público para instâncias privadas)
- **NAT Gateway**: Não (economia de custos)
- **Autoscaling**: CPU > 70% scale-out, < 70% scale-in
- **RDS**: db.t3.micro, backup 1 dia
- **Branch**: `dev`

### Produção (prod)
- **Instâncias**: 1-4 (mínimo 1, máximo 4, inicial 1)
- **Rede**: ECS em subnets privadas (sem IP público)
- **NAT Gateway**: Sim (para acesso à internet das subnets privadas)
- **Autoscaling**: CPU > 70% scale-out, < 70% scale-in
- **RDS**: db.t3.micro, backup 7 dias
- **Branch**: `bia-v1`

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

### Deploy Automatizado (CI/CD)

#### Para Desenvolvimento:
1. Faça push para a branch `dev`
2. GitHub Actions executará automaticamente:
   - Validação do Terraform
   - Testes automatizados
   - Deploy no ambiente dev

#### Para Produção:
1. Faça push para a branch `bia-v1`
2. GitHub Actions executará automaticamente:
   - Validação do Terraform
   - Testes automatizados
   - Deploy no ambiente prod (com aprovação manual)

### Validação

```bash
# Validar configuração do ambiente dev
./validate.sh dev

# Validar configuração do ambiente prod
./validate.sh prod
```

### Testes

```bash
# Executar todos os testes automatizados
./test.sh
```

## Configuração por Ambiente

As configurações específicas de cada ambiente estão definidas no arquivo `locals.tf`:

- **Capacidade de instâncias**: min=1, max=4, desired=1
- **Thresholds de autoscaling**: CPU 70%, Memory 75%
- **Configurações de rede**: públicas (dev) vs privadas (prod)
- **Recursos de banco**: diferentes períodos de backup
- **NAT Gateway**: apenas em produção

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

## URLs dos Ambientes

- **Dev**: `bia-dev-alb-2038579356.us-east-1.elb.amazonaws.com`
- **Prod**: `bia-prod-alb-1188670732.us-east-1.elb.amazonaws.com`