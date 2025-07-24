#!/bin/bash

# Script para testes automatizados da infraestrutura Terraform
# Uso: ./test.sh

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Contadores de teste
TESTS_PASSED=0
TESTS_FAILED=0
TOTAL_TESTS=0

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

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Função para executar teste
run_test() {
    local test_name=$1
    local test_command=$2
    
    ((TOTAL_TESTS++))
    
    log "Running test: $test_name"
    
    if eval "$test_command" > /dev/null 2>&1; then
        success "✓ $test_name"
        ((TESTS_PASSED++))
        return 0
    else
        error "✗ $test_name"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Função para testar sintaxe do Terraform
test_terraform_syntax() {
    log "Testing Terraform syntax and validation..."
    
    run_test "Terraform Init" "terraform init -backend=false"
    run_test "Terraform Validate" "terraform validate"
    run_test "Terraform Format Check" "terraform fmt -check=true -recursive"
}

# Função para testar configurações de ambiente
test_environment_configs() {
    log "Testing environment-specific configurations..."
    
    # Testar ambiente dev
    run_test "Dev Environment Plan" "terraform plan -var='environment=dev' -out=/dev/null"
    
    # Testar ambiente prod
    run_test "Prod Environment Plan" "terraform plan -var='environment=prod' -out=/dev/null"
    
    # Testar ambiente inválido (deve falhar)
    if terraform plan -var='environment=invalid' -out=/dev/null > /dev/null 2>&1; then
        error "✗ Invalid Environment Validation (should have failed)"
        ((TESTS_FAILED++))
    else
        success "✓ Invalid Environment Validation"
        ((TESTS_PASSED++))
    fi
    ((TOTAL_TESTS++))
}

# Função para testar estrutura de arquivos
test_file_structure() {
    log "Testing file structure..."
    
    # Arquivos principais
    run_test "Main.tf exists" "test -f main.tf"
    run_test "Variables.tf exists" "test -f variables.tf"
    run_test "Locals.tf exists" "test -f locals.tf"
    
    # Módulos
    run_test "VPC module exists" "test -d modules/vpc"
    run_test "IAM module exists" "test -d modules/iam"
    run_test "Security Groups module exists" "test -d modules/security-groups"
    run_test "CloudWatch module exists" "test -d modules/cloudwatch"
    run_test "RDS module exists" "test -d modules/rds"
    run_test "ALB module exists" "test -d modules/alb"
    run_test "ECS Cluster module exists" "test -d modules/ecs-cluster"
    run_test "ECS Service module exists" "test -d modules/ecs-service"
    
    # Scripts
    run_test "Deploy script exists" "test -f deploy.sh"
    run_test "Validate script exists" "test -f validate.sh"
    run_test "Deploy script is executable" "test -x deploy.sh"
    run_test "Validate script is executable" "test -x validate.sh"
}

# Função para testar configurações específicas por ambiente
test_environment_specific_configs() {
    log "Testing environment-specific configurations..."
    
    # Criar planos temporários para análise
    terraform plan -var='environment=dev' -out=dev.tfplan > /dev/null 2>&1
    terraform plan -var='environment=prod' -out=prod.tfplan > /dev/null 2>&1
    
    # Converter planos para JSON para análise
    terraform show -json dev.tfplan > dev.json 2>/dev/null || true
    terraform show -json prod.tfplan > prod.json 2>/dev/null || true
    
    # Testar se os planos foram criados
    run_test "Dev plan created" "test -f dev.tfplan"
    run_test "Prod plan created" "test -f prod.tfplan"
    
    # Limpeza
    rm -f dev.tfplan prod.tfplan dev.json prod.json
}

# Função para testar tags
test_tags_configuration() {
    log "Testing tags configuration..."
    
    # Verificar se locals.tf contém as tags corretas
    run_test "Common tags defined" "grep -q 'common_tags' locals.tf"
    run_test "Environment tag defined" "grep -q 'Environment.*var.environment' locals.tf"
    run_test "Owner tag defined" "grep -q 'Owner.*Nelson Holanda' locals.tf"
    run_test "Project tag defined" "grep -q 'Project.*BIA' locals.tf"
    run_test "ManagedBy tag defined" "grep -q 'ManagedBy.*Terraform' locals.tf"
}

# Função para testar variáveis
test_variables_configuration() {
    log "Testing variables configuration..."
    
    # Verificar se a variável environment existe e tem validação
    run_test "Environment variable defined" "grep -q 'variable \"environment\"' variables.tf"
    run_test "Environment validation defined" "grep -q 'validation' variables.tf"
    run_test "Environment validation contains dev/prod" "grep -q 'dev.*prod' variables.tf"
}

# Função para testar módulos
test_modules_configuration() {
    log "Testing modules configuration..."
    
    # Verificar se todos os módulos têm as variáveis necessárias
    for module in vpc iam security-groups cloudwatch rds alb ecs-cluster ecs-service; do
        run_test "$module module has environment variable" "grep -q 'variable \"environment\"' modules/$module/variables.tf"
        run_test "$module module has tags variable" "grep -q 'variable \"tags\"' modules/$module/variables.tf"
    done
}

# Função para mostrar resumo dos testes
show_test_summary() {
    echo ""
    log "Test Summary:"
    echo "  Total Tests: $TOTAL_TESTS"
    echo "  Passed: $TESTS_PASSED"
    echo "  Failed: $TESTS_FAILED"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        success "All tests passed! ✓"
        return 0
    else
        error "Some tests failed! ✗"
        return 1
    fi
}

# Função principal
main() {
    log "Starting automated tests for Terraform multi-environment setup..."
    
    # Verificar se estamos no diretório correto
    if [[ ! -f "main.tf" ]]; then
        error "main.tf not found. Please run this script from the terraform directory"
        exit 1
    fi
    
    # Executar testes
    test_file_structure
    test_terraform_syntax
    test_variables_configuration
    test_tags_configuration
    test_modules_configuration
    test_environment_configs
    test_environment_specific_configs
    
    # Mostrar resumo
    show_test_summary
}

# Executar função principal
main "$@"