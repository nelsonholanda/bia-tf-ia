# Configuração para ambiente de produção
environment = "prod"

# Região AWS
aws_region = "us-east-1"

# Nome do cluster ECS para produção
cluster_name = "bia-prod-cluster"

# Nome da chave SSH para instâncias EC2
key_name = "nholanda"

# Configurações específicas do ambiente são definidas em locals.tf
# Este arquivo serve apenas para variáveis que podem mudar entre deployments
