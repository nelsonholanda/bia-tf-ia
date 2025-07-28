#!/bin/bash

# Script para limpeza de secrets órfãos no AWS Secrets Manager
# Este script deve ser executado antes do terraform apply para evitar conflitos

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Função para log
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

# Verificar se o ambiente foi fornecido
if [ -z "$1" ]; then
    error "Uso: $0 <environment>"
    error "Exemplo: $0 dev"
    error "Exemplo: $0 prod"
    exit 1
fi

ENVIRONMENT=$1

# Validar ambiente
if [[ "$ENVIRONMENT" != "dev" && "$ENVIRONMENT" != "prod" ]]; then
    error "Ambiente deve ser 'dev' ou 'prod'"
    exit 1
fi

log "Iniciando limpeza de secrets para ambiente: $ENVIRONMENT"

# Verificar se AWS CLI está configurado
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    error "AWS CLI não está configurado ou não tem permissões adequadas"
    exit 1
fi

# Buscar secrets do projeto que estão agendados para deleção
log "Buscando secrets agendados para deleção..."

PENDING_SECRETS=$(aws secretsmanager list-secrets \
    --include-planned-deletion \
    --query "SecretList[?contains(Name, 'bia-${ENVIRONMENT}') && DeletedDate].{Name:Name,ARN:ARN,DeletedDate:DeletedDate}" \
    --output json)

if [ "$PENDING_SECRETS" = "[]" ]; then
    log "Nenhum secret encontrado agendado para deleção"
    exit 0
fi

# Mostrar secrets encontrados
echo -e "\n${YELLOW}Secrets encontrados agendados para deleção:${NC}"
echo "$PENDING_SECRETS" | jq -r '.[] | "- \(.Name) (ARN: \(.ARN))"'

# Confirmar ação (apenas em modo interativo)
if [ -t 0 ]; then
    echo -e "\n${YELLOW}Deseja forçar a exclusão destes secrets? (y/N)${NC}"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        warn "Operação cancelada pelo usuário"
        exit 0
    fi
fi

# Forçar exclusão dos secrets
log "Forçando exclusão dos secrets..."

echo "$PENDING_SECRETS" | jq -r '.[].ARN' | while read -r secret_arn; do
    if [ -n "$secret_arn" ]; then
        log "Excluindo secret: $secret_arn"
        if aws secretsmanager delete-secret \
            --secret-id "$secret_arn" \
            --force-delete-without-recovery > /dev/null 2>&1; then
            log "✓ Secret excluído com sucesso: $secret_arn"
        else
            error "✗ Falha ao excluir secret: $secret_arn"
        fi
    fi
done

log "Limpeza de secrets concluída"

# Aguardar um pouco para garantir que a exclusão foi processada
log "Aguardando propagação das alterações..."
sleep 5

# Verificar se ainda há secrets pendentes
REMAINING_SECRETS=$(aws secretsmanager list-secrets \
    --include-planned-deletion \
    --query "SecretList[?contains(Name, 'bia-${ENVIRONMENT}') && DeletedDate].Name" \
    --output text)

if [ -n "$REMAINING_SECRETS" ]; then
    warn "Ainda existem secrets pendentes: $REMAINING_SECRETS"
    warn "Aguarde alguns minutos antes de executar o Terraform"
else
    log "✓ Todos os secrets foram limpos com sucesso"
fi

log "Script de limpeza finalizado"