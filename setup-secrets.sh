#!/bin/bash

# Script para configurar secrets iniciais
# Usage: ./setup-secrets.sh <environment> <db_password>

set -e

ENVIRONMENT=${1:-dev}
DB_PASSWORD=${2}

if [ -z "$DB_PASSWORD" ]; then
    echo "❌ Erro: Senha do banco é obrigatória"
    echo "Usage: $0 <environment> <db_password>"
    echo "Example: $0 dev mySecurePassword123"
    exit 1
fi

echo "🔐 Configurando secrets para ambiente: $ENVIRONMENT"

# Verificar se AWS CLI está configurado
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "❌ Erro: AWS CLI não está configurado"
    exit 1
fi

# Aplicar Terraform com a nova senha
echo "📦 Aplicando Terraform com secrets..."
terraform apply -var="environment=$ENVIRONMENT" -var="db_password=$DB_PASSWORD" -auto-approve

echo "✅ Secrets configurados com sucesso!"
echo ""
echo "📋 Recursos criados:"
echo "   - Secret Manager: bia-$ENVIRONMENT-db-password"
echo "   - Parameter Store: rdsendpoint$ENVIRONMENT"
echo "   - Parameter Store: portdb"
echo "   - Parameter Store: userdb"
echo ""
echo "🔍 Para verificar os secrets:"
echo "   aws secretsmanager get-secret-value --secret-id bia-$ENVIRONMENT-db-password"
echo "   aws ssm get-parameter --name rdsendpoint$ENVIRONMENT"
echo "   aws ssm get-parameter --name portdb"
echo "   aws ssm get-parameter --name userdb"