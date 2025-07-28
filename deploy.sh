#!/bin/bash

# Script para deploy da infraestrutura BIA com múltiplos ambientes
# Uso: ./deploy.sh [dev|prod] [plan|apply|destroy]

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para logging
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Função para validar ambiente
validate_environment() {
    local env=$1
    
    if [[ "$env" != "dev" && "$env" != "prod" ]]; then
        error "Environment must be 'dev' or 'prod'"
        echo "Usage: $0 [dev|prod] [plan|apply|destroy]"
        exit 1
    fi
}

# Função para validar ação
validate_action() {
    local action=$1
    
    if [[ "$action" != "plan" && "$action" != "apply" && "$action" != "destroy" ]]; then
        error "Action must be 'plan', 'apply', or 'destroy'"
        echo "Usage: $0 [dev|prod] [plan|apply|destroy]"
        exit 1
    fi
}

# Função para verificar backend
check_backend() {
    local env=$1
    
    if [[ ! -f "backend-$env.hcl" ]]; then
        error "Backend configuration file 'backend-$env.hcl' not found"
        exit 1
    fi
    
    log "Using backend configuration: backend-$env.hcl"
}

# Função para limpeza de secrets órfãos
cleanup_secrets() {
    local env=$1
    
    log "Checking for orphaned secrets in environment: $env"
    
    if [[ -f "./cleanup-secrets.sh" ]]; then
        log "Running secrets cleanup script..."
        ./cleanup-secrets.sh "$env"
    else
        warning "cleanup-secrets.sh not found, skipping secrets cleanup"
    fi
}

# Função para executar terraform
execute_terraform() {
    local env=$1
    local action=$2
    
    log "Executing terraform $action for environment: $env"
    
    case $action in
        "plan")
            # Limpar secrets órfãos antes do plan
            cleanup_secrets "$env"
            terraform plan -var="environment=$env" -out="tfplan-$env"
            ;;
        "apply")
            # Limpar secrets órfãos antes do apply
            cleanup_secrets "$env"
            if [[ -f "tfplan-$env" ]]; then
                terraform apply "tfplan-$env"
                rm -f "tfplan-$env"
            else
                if [[ "$env" == "prod" ]]; then
                    terraform apply -var-file=terraform-prod.tfvars -auto-approve
                else
                    terraform apply -var="environment=$env" -auto-approve
                fi
            fi
            ;;
        "destroy")
            if [[ "$env" == "prod" ]]; then
                warning "You are about to DESTROY the PRODUCTION environment!"
                read -p "Type 'destroy-prod' to confirm: " confirm
                if [[ "$confirm" != "destroy-prod" ]]; then
                    log "Destroy operation cancelled"
                    exit 0
                fi
                terraform destroy -var-file=terraform-prod.tfvars -auto-approve
            else
                terraform destroy -var="environment=$env" -auto-approve
            fi
            ;;
    esac
}

# Função principal
main() {
    local env=$1
    local action=$2
    
    # Validar parâmetros
    if [[ $# -ne 2 ]]; then
        error "Invalid number of arguments"
        echo "Usage: $0 [dev|prod] [plan|apply|destroy]"
        exit 1
    fi
    
    validate_environment "$env"
    validate_action "$action"
    
    # Verificar se estamos no diretório correto
    if [[ ! -f "main.tf" ]]; then
        error "main.tf not found. Please run this script from the terraform directory"
        exit 1
    fi
    
    log "Starting deployment process..."
    log "Environment: $env"
    log "Action: $action"
    
    # Inicializar Terraform com backend específico do ambiente
    log "Initializing Terraform with backend configuration for $env..."
    terraform init -backend-config="backend-$env.hcl" -reconfigure
    
    # Verificar backend
    check_backend "$env"
    
    # Executar ação do Terraform
    execute_terraform "$env" "$action"
    
    success "Deployment process completed successfully!"
    
    # Mostrar informações do estado atual
    log "Environment: $env"
    log "Resources in this environment:"
    terraform state list 2>/dev/null || log "No resources found in state"
}

# Executar função principal
main "$@"