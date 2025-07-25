#!/bin/bash

# Script para configurar secrets iniciais
# Usage: ./setup-secrets.sh <environment>

set -e

ENVIRONMENT=${1:-dev}

if [ -z "$ENVIRONMENT" ]; then
    echo "❌ Erro: Ambiente é obrigatório"
    echo "Usage: $0 <environment>"
    echo "Example: $0 dev"
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
terraform apply -var="environment=$ENVIRONMENT" -auto-approve

echo "✅ Secrets configurados com sucesso!"
echo ""
echo "📋 Recursos criados:"
echo "   - Secret Manager: bia-$ENVIRONMENT-secrets"
echo ""
echo "🔍 Para verificar os secrets:"
echo "   aws secretsmanager get-secret-value --secret-id bia-$ENVIRONMENT-secrets"
echo ""
echo "🔍 Para validar a configuração:"
echo "   aws secretsmanager get-secret-value --secret-id bia-$ENVIRONMENT-secrets"