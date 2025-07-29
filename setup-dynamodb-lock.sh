#!/bin/bash

# Script para configurar DynamoDB State Lock para Terraform
# Este script cria as tabelas DynamoDB necessárias para o state locking

set -e

echo "🔒 Configurando DynamoDB State Lock para Terraform..."

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para imprimir mensagens coloridas
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar se AWS CLI está configurado
if ! aws sts get-caller-identity &>/dev/null; then
    print_error "AWS CLI não está configurado ou não tem permissões adequadas"
    exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION="us-east-1"

print_status "Conta AWS: $ACCOUNT_ID"
print_status "Região: $REGION"

# Função para criar tabela DynamoDB
create_dynamodb_table() {
    local table_name=$1
    local environment=$2
    
    print_status "Verificando se a tabela $table_name já existe..."
    
    if aws dynamodb describe-table --table-name "$table_name" --region "$REGION" &>/dev/null; then
        print_warning "Tabela $table_name já existe, pulando criação..."
        return 0
    fi
    
    print_status "Criando tabela DynamoDB: $table_name"
    
    aws dynamodb create-table \
        --table-name "$table_name" \
        --attribute-definitions \
            AttributeName=LockID,AttributeType=S \
        --key-schema \
            AttributeName=LockID,KeyType=HASH \
        --provisioned-throughput \
            ReadCapacityUnits=5,WriteCapacityUnits=5 \
        --region "$REGION" \
        --tags \
            Key=Name,Value="$table_name" \
            Key=Environment,Value="$environment" \
            Key=Project,Value="BIA" \
            Key=ManagedBy,Value="Terraform" \
            Key=Purpose,Value="TerraformStateLock" \
            Key=Application,Value="BIA" \
            Key=Owner,Value="Nelson Holanda" \
            Key=CostCenter,Value="Engineering" \
            Key=Compliance,Value="SOC2" \
            Key=DataClass,Value="Confidential" \
        > /dev/null
    
    print_status "Aguardando tabela $table_name ficar ativa..."
    aws dynamodb wait table-exists --table-name "$table_name" --region "$REGION"
    
    print_success "Tabela $table_name criada com sucesso!"
}

# Criar tabelas para ambos os ambientes
print_status "Criando tabelas DynamoDB para state locking..."

# Tabela para ambiente de desenvolvimento
create_dynamodb_table "terraform-state-lock-bia-dev" "dev"

# Tabela para ambiente de produção
create_dynamodb_table "terraform-state-lock-bia-prod" "prod"

print_success "Configuração do DynamoDB State Lock concluída!"

echo ""
echo "📋 Resumo das tabelas criadas:"
echo "  • terraform-state-lock-bia-dev (desenvolvimento)"
echo "  • terraform-state-lock-bia-prod (produção)"
echo ""
echo "🔧 Próximos passos:"
echo "  1. Os arquivos backend-dev.hcl e backend-prod.hcl foram atualizados"
echo "  2. Execute 'terraform init -reconfigure' para aplicar as mudanças"
echo "  3. O state locking estará ativo automaticamente"
echo ""
echo "💡 Benefícios do State Locking:"
echo "  • Previne execuções simultâneas do Terraform"
echo "  • Evita corrupção do state file"
echo "  • Melhora a segurança em ambientes colaborativos"
echo "  • Fornece informações sobre quem está executando operações"