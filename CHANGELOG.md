# 📝 Changelog

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
e este projeto adere ao [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.1.0] - 2025-07-30

### 🚀 Added
- **BACKUP-STRATEGY.md**: Documentação completa da estratégia de backup
- Configurações otimizadas de backup para RDS
- Backup diário automatizado com retenção diferenciada por ambiente
- Janelas de backup otimizadas (03:00-04:00 UTC)
- Copy tags to snapshots habilitado
- Final snapshot para produção

### 🔄 Changed
- **Desenvolvimento**: Retenção de backup aumentada de 1 para 7 dias
- **Produção**: Mantida retenção de 30 dias
- **RDS Configuration**: Melhoradas configurações de backup automático
- **locals.tf**: Adicionadas configurações detalhadas de backup

### 💾 Backup Features
- **RTO**: < 4 horas (Recovery Time Objective)
- **RPO**: < 24 horas (Recovery Point Objective)
- **Point-in-Time Recovery**: Habilitado para ambos ambientes
- **Cross-AZ Backup**: Automático em produção
- **Automated Cleanup**: Configurado para ambos ambientes

## [2.0.0] - 2025-07-30

### 🚀 Added
- **ARCHITECTURE.md**: Documentação completa da arquitetura
- **MIGRATION-S3-LOCKING.md**: Documentação da migração para S3 locking
- **CHANGELOG.md**: Este arquivo de changelog
- Backup automático das configurações antes da migração
- Suporte completo ao S3 object locking

### 🔄 Changed
- **BREAKING**: Migração de DynamoDB para S3 object locking
- **backend-dev.hcl**: Removida referência ao DynamoDB
- **backend-prod.hcl**: Removida referência ao DynamoDB
- **deploy.sh**: Atualizada documentação sobre locking
- **README.md**: Documentação atualizada com nova arquitetura
- **.gitignore**: Otimizado para incluir arquivos importantes

### 🗑️ Removed
- **setup-dynamodb-lock.sh**: Script não mais necessário
- Dependência das tabelas DynamoDB para state locking
- Arquivos temporários de terraform plan
- Backups vazios desnecessários

### 🔧 Fixed
- State locking agora usa S3 nativo (mais confiável)
- Redução de custos operacionais
- Simplificação da infraestrutura

### 💰 Cost Impact
- **Economia**: ~$6/ano pela remoção das tabelas DynamoDB
- **Manutenção**: Redução significativa na complexidade

## [1.0.0] - 2025-07-29

### 🚀 Added
- Infraestrutura inicial com Terraform
- Suporte a múltiplos ambientes (dev/prod)
- Módulos para VPC, ECS, RDS, ALB, WAF
- GitHub Actions workflows
- DynamoDB state locking
- Documentação inicial

### 🏗️ Architecture
- VPC com subnets públicas e privadas
- ECS cluster com auto-scaling
- RDS PostgreSQL com Multi-AZ (prod)
- Application Load Balancer
- WAF para proteção (prod)
- KMS para criptografia (prod)

### 🔒 Security
- Security groups restritivos
- Secrets Manager para credenciais
- Criptografia em trânsito e repouso
- IAM roles com least privilege

---

## Tipos de Mudanças

- **Added** para novas funcionalidades
- **Changed** para mudanças em funcionalidades existentes
- **Deprecated** para funcionalidades que serão removidas
- **Removed** para funcionalidades removidas
- **Fixed** para correções de bugs
- **Security** para vulnerabilidades corrigidas

## Versionamento

Este projeto usa [Semantic Versioning](https://semver.org/):

- **MAJOR**: Mudanças incompatíveis na API
- **MINOR**: Funcionalidades adicionadas de forma compatível
- **PATCH**: Correções de bugs compatíveis

## Migração entre Versões

### De 1.x para 2.0.0

⚠️ **BREAKING CHANGE**: Esta versão remove a dependência do DynamoDB.

**Passos para migração:**
1. Fazer backup das configurações atuais
2. Atualizar arquivos backend-*.hcl
3. Reinicializar backends do Terraform
4. Remover tabelas DynamoDB (opcional)

**Rollback (se necessário):**
1. Restaurar arquivos de `.backup/20250730_200741/`
2. Recriar tabelas DynamoDB
3. Reinicializar backends

Para mais detalhes, consulte `MIGRATION-S3-LOCKING.md`.