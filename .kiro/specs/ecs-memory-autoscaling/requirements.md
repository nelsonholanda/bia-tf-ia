# Requirements Document

## Introduction

Este documento define os requisitos para implementar auto scaling das tasks ECS baseado em utilização de memória, configurando o mínimo de 1 task e máximo de 10 tasks, com scale out apenas quando as instâncias estiverem com memória cheia. Também inclui atualizações no .gitignore e deploy para ambos os ambientes.

## Requirements

### Requirement 1

**User Story:** Como administrador de infraestrutura, eu quero configurar auto scaling das tasks ECS baseado em memória, para que o sistema escale automaticamente apenas quando necessário.

#### Acceptance Criteria

1. WHEN a utilização de memória das tasks atingir 80% THEN o sistema SHALL iniciar o scale out
2. WHEN a utilização de memória das tasks ficar abaixo de 60% THEN o sistema SHALL iniciar o scale in
3. WHEN configurado THEN o número mínimo de tasks SHALL ser 1
4. WHEN configurado THEN o número máximo de tasks SHALL ser 10
5. WHEN o scale out for acionado THEN o sistema SHALL aguardar 5 minutos antes de permitir nova ação de scaling
6. WHEN o scale in for acionado THEN o sistema SHALL aguardar 10 minutos antes de permitir nova ação de scaling

### Requirement 2

**User Story:** Como desenvolvedor, eu quero que as configurações de auto scaling sejam diferentes por ambiente, para que dev tenha configurações mais conservadoras que produção.

#### Acceptance Criteria

1. WHEN no ambiente dev THEN o target de memória SHALL ser 80%
2. WHEN no ambiente prod THEN o target de memória SHALL ser 75%
3. WHEN no ambiente dev THEN o máximo de tasks SHALL ser 6
4. WHEN no ambiente prod THEN o máximo de tasks SHALL ser 10
5. WHEN configurado THEN ambos os ambientes SHALL ter mínimo de 1 task

### Requirement 3

**User Story:** Como administrador de infraestrutura, eu quero remover o auto scaling baseado em CPU, para que apenas a memória seja o fator de scaling.

#### Acceptance Criteria

1. WHEN configurado THEN o sistema SHALL remover as políticas de auto scaling baseadas em CPU
2. WHEN configurado THEN apenas métricas de memória SHALL ser utilizadas para scaling
3. WHEN removido o CPU scaling THEN o sistema SHALL manter apenas a política de memória ativa

### Requirement 4

**User Story:** Como desenvolvedor, eu quero que as mudanças sejam aplicadas em ambos os ambientes, para que dev e prod tenham as mesmas configurações de auto scaling.

#### Acceptance Criteria

1. WHEN as mudanças forem implementadas THEN elas SHALL ser aplicadas no ambiente dev
2. WHEN as mudanças forem implementadas THEN elas SHALL ser aplicadas no ambiente prod
3. WHEN o deploy for executado THEN ambos os ambientes SHALL ser atualizados via GitHub Actions
4. WHEN o deploy for concluído THEN o sistema SHALL validar que as configurações estão ativas

### Requirement 5

**User Story:** Como desenvolvedor, eu quero que o .gitignore seja atualizado com melhores práticas, para que arquivos desnecessários não sejam commitados.

#### Acceptance Criteria

1. WHEN o .gitignore for atualizado THEN ele SHALL incluir padrões específicos para projetos Terraform
2. WHEN o .gitignore for atualizado THEN ele SHALL incluir padrões para arquivos de CI/CD
3. WHEN o .gitignore for atualizado THEN ele SHALL manter arquivos importantes como .terraform.lock.hcl
4. WHEN o .gitignore for atualizado THEN ele SHALL excluir arquivos sensíveis como .tfvars