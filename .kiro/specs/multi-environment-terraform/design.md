# Design Document

## Overview

O design implementará um sistema de múltiplos ambientes para a infraestrutura Terraform existente, permitindo implantação controlada em ambientes de desenvolvimento e produção. A solução utilizará workspaces do Terraform, variáveis condicionais e um sistema de tags padronizado.

## Architecture

### Environment Management Strategy

A arquitetura utilizará os seguintes componentes principais:

1. **Terraform Workspaces**: Isolamento de estado entre ambientes
2. **Environment Variables**: Configurações específicas por ambiente
3. **Conditional Resources**: Recursos dimensionados conforme o ambiente
4. **Standardized Tagging**: Tags consistentes em todos os recursos
5. **Environment Selection**: Mecanismo para escolha do ambiente

### Environment Configuration Matrix

| Componente | Desenvolvimento | Produção |
|------------|----------------|----------|
| ECS Instance Type | t3.micro | t3.micro |
| RDS Instance Class | db.t3.micro | db.t3.micro |
| Container CPU | 512 | 1024 |
| Container Memory | 256 MB | 512 MB |
| Multi-AZ RDS | false | true |
| Backup Retention | 1 day | 7 days |

## Components and Interfaces

### 1. Environment Configuration Module

```hcl
# locals.tf - Environment-specific configurations
locals {
  environment = var.environment
  
  # Environment-specific configurations
  env_config = {
    dev = {
      instance_type = "t3.micro"
      rds_instance_class = "db.t3.micro"
      container_cpu = 512
      container_memory = 256
      multi_az = false
      backup_retention_period = 1
    }
    prod = {
      instance_type = "t3.micro"
      rds_instance_class = "db.t3.micro"
      container_cpu = 1024
      container_memory = 512
      multi_az = true
      backup_retention_period = 7
    }
  }
  
  # Common tags applied to all resources
  common_tags = {
    Environment = var.environment
    Owner       = "Nelson Holanda"
    Project     = "BIA"
    ManagedBy   = "Terraform"
  }
}
```

### 2. Enhanced Variables System

Extensão do `variables.tf` existente para incluir:

- `environment`: Variável para seleção do ambiente
- Configurações específicas por ambiente
- Validação de valores de ambiente

### 3. Module Tag Propagation

Cada módulo será atualizado para:

- Aceitar tags como parâmetro
- Aplicar tags a todos os recursos criados
- Manter compatibilidade com a estrutura existente

### 4. Workspace Management

Sistema automatizado para:

- Criar workspaces se não existirem
- Selecionar workspace apropriado
- Validar estado do workspace

## Data Models

### Environment Configuration Structure

```hcl
variable "environment" {
  description = "Environment name (dev or prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be either 'dev' or 'prod'."
  }
}

variable "common_tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default     = {}
}
```

### Module Interface Updates

Cada módulo receberá:

```hcl
variable "environment" {
  description = "Environment name"
  type        = string
}

variable "tags" {
  description = "Tags to be applied to resources"
  type        = map(string)
  default     = {}
}
```

## Error Handling

### Environment Validation

1. **Input Validation**: Validação no nível de variável para aceitar apenas "dev" ou "prod"
2. **Workspace Validation**: Verificação se o workspace corresponde ao ambiente
3. **Resource Naming**: Validação de conflitos de nomes entre ambientes

### Production Safety

1. **Confirmation Prompts**: Implementação de confirmação para ambiente de produção
2. **Audit Logging**: Logs detalhados para operações em produção
3. **State Backup**: Backup automático do estado antes de mudanças em produção

### Error Recovery

1. **Rollback Procedures**: Documentação de procedimentos de rollback
2. **State Recovery**: Mecanismos para recuperação de estado corrompido
3. **Resource Cleanup**: Limpeza automática de recursos órfãos

## Testing Strategy

### Environment Isolation Testing

1. **Workspace Isolation**: Verificar que mudanças em dev não afetam prod
2. **Resource Naming**: Confirmar que recursos têm nomes únicos por ambiente
3. **Tag Validation**: Verificar aplicação correta de tags

### Configuration Testing

1. **Environment-Specific Values**: Validar que cada ambiente usa configurações corretas
2. **Resource Sizing**: Confirmar dimensionamento apropriado por ambiente
3. **Network Isolation**: Verificar isolamento de rede entre ambientes

### Integration Testing

1. **Module Compatibility**: Testar compatibilidade com módulos existentes
2. **State Management**: Validar gerenciamento correto de estado
3. **Deployment Flow**: Testar fluxo completo de implantação

### Validation Scripts

```bash
# Script para validação de ambiente
#!/bin/bash
validate_environment() {
  local env=$1
  
  if [[ "$env" != "dev" && "$env" != "prod" ]]; then
    echo "Error: Environment must be 'dev' or 'prod'"
    exit 1
  fi
  
  if [[ "$env" == "prod" ]]; then
    read -p "Are you sure you want to deploy to PRODUCTION? (yes/no): " confirm
    if [[ "$confirm" != "yes" ]]; then
      echo "Production deployment cancelled"
      exit 1
    fi
  fi
}
```

## Implementation Approach

### Phase 1: Core Infrastructure
- Implementar sistema de variáveis de ambiente
- Adicionar locals para configurações específicas
- Atualizar tags em recursos principais

### Phase 2: Module Updates
- Atualizar cada módulo para aceitar tags
- Implementar configurações condicionais
- Testar compatibilidade

### Phase 3: Workspace Management
- Implementar scripts de gerenciamento de workspace
- Adicionar validações de ambiente
- Documentar procedimentos

### Phase 4: Validation & Testing
- Implementar testes automatizados
- Validar isolamento entre ambientes
- Documentar procedimentos operacionais