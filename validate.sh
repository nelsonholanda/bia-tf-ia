#!/bin/bash

# Script para validação da configuração Terraform
# Uso: ./validate.sh [dev|prod]

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

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Função para validar ambiente
validate_environment() {
    local env=$1
    
    if [[ "$env" != "dev" && "$env" != "prod" ]]; then
        error "Environment must be 'dev' or 'prod'"
        echo "Usage: $0 [dev|prod]"
        exit 1
    fi
}

# Função para validar configuração
validate_configuration() {
    local env=$1
    
    log "Validating Terraform configuration for environment: $env"
    
    # Validar sintaxe
    log "Checking Terraform syntax..."
    terraform validate
    
    # Formatar código
    log "Checking Terraform formatting..."
    terraform fmt -check=true -diff=true
    
    # Validar com variável de ambiente
    log "Validating with environment variable..."
    terraform plan -var="environment=$env" -detailed-exitcode > /dev/null
    
    success "Configuration validation completed successfully!"
}

# Função para mostrar informações do ambiente
show_environment_info() {
    local env=$1
    
    log "Environment configuration for: $env"
    
    case $env in
        "dev")
            echo "  - Instance Type: t3.micro"
            echo "  - RDS Instance: db.t3.micro"
            echo "  - Container CPU: 1024"
            echo "  - Container Memory: 512 MB"
            echo "  - Multi-AZ RDS: false"
            echo "  - Backup Retention: 1 day"
            ;;
        "prod")
            echo "  - Instance Type: t3.micro"
            echo "  - RDS Instance: db.t3.micro"
            echo "  - Container CPU: 1024"
            echo "  - Container Memory: 512 MB"
            echo "  - Multi-AZ RDS: false"
            echo "  - Backup Retention: 7 days"
            ;;
    esac
    
    echo "  - Tags:"
    echo "    - Environment: $env"
    echo "    - Owner: Nelson Holanda"
    echo "    - Project: BIA"
    echo "    - ManagedBy: Terraform"
}

# Função principal
main() {
    local env=$1
    
    # Validar parâmetros
    if [[ $# -ne 1 ]]; then
        error "Invalid number of arguments"
        echo "Usage: $0 [dev|prod]"
        exit 1
    fi
    
    validate_environment "$env"
    
    # Verificar se estamos no diretório correto
    if [[ ! -f "main.tf" ]]; then
        error "main.tf not found. Please run this script from the terraform directory"
        exit 1
    fi
    
    # Inicializar Terraform se necessário
    if [[ ! -d ".terraform" ]]; then
        log "Initializing Terraform..."
        terraform init
    fi
    
    # Validar configuração
    validate_configuration "$env"
    
    # Mostrar informações do ambiente
    show_environment_info "$env"
    
    success "Validation completed successfully!"
}

# Executar função principal
main "$@"