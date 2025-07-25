# 🔐 Configuração de Secrets e Parameter Store - VERSÃO CORRIGIDA

## 📋 Resumo das Mudanças

Implementação corrigida conforme especificações:

### ✅ **Implementações Realizadas:**

1. **2 Secrets separados** - Criados junto com o RDS (dev e prod)
2. **Parameter Store** - Nomes específicos: `userdb`, `portdb`, `rdsendpointdev`, `rdsendpointprod`
3. **Permissões IAM atualizadas** - Acesso aos secrets para ECS tasks
4. **Task Definition atualizada** - Usa secrets em vez de environment variables
5. **Deploy apenas na branch dev** - Para testes antes de produção

## 🏗️ **Arquitetura de Secrets**

### **AWS Secrets Manager (Apenas Senha - Criado junto com RDS):**
- `bia-dev-db-password` - Senha do banco (DEV)
- `bia-prod-db-password` - Senha do banco (PROD)

### **AWS Parameter Store (Outras Configurações):**
- `rdsendpointdev` - Endpoint do RDS (DEV)
- `rdsendpointprod` - Endpoint do RDS (PROD)
- `portdb` - Porta do banco (5432)
- `userdb` - Usuário do banco (postgres)

## 🔧 **Como Configurar**

### **1. Deploy Inicial:**

```bash
# Para DEV
terraform apply -var="environment=dev" -var="db_password=SuaSenhaSegura123"

# Para PROD
terraform apply -var="environment=prod" -var="db_password=SuaSenhaSeguraProd456"
```

### **2. Usando o Script de Setup:**

```bash
# Dar permissão de execução
chmod +x setup-secrets.sh

# Configurar DEV
./setup-secrets.sh dev "SuaSenhaSegura123"

# Configurar PROD
./setup-secrets.sh prod "SuaSenhaSeguraProd456"
```

### **3. Verificar Configuração:**

```bash
# Verificar secret da senha
aws secretsmanager get-secret-value --secret-id bia-dev-db-password

# Verificar parâmetros
aws ssm get-parameter --name rdsendpointdev
aws ssm get-parameter --name portdb
aws ssm get-parameter --name userdb
```

## 🔄 **Como Alterar Senha do Banco**

### **Método 1: Via Terraform**
```bash
terraform apply -var="environment=dev" -var="db_password=NovaSenha123"
```

### **Método 2: Via AWS CLI**
```bash
aws secretsmanager update-secret --secret-id bia-dev-db-password --secret-string "NovaSenha123"
```

### **Método 3: Via Console AWS**
1. Acesse AWS Secrets Manager
2. Encontre o secret `bia-dev-db-password`
3. Clique em "Retrieve secret value"
4. Clique em "Edit"
5. Altere a senha
6. Salve

## 🚀 **Deploy Apenas na Branch DEV**

Para testes, o deploy será feito apenas na branch dev:

```bash
# Fazer commit das mudanças
git add .
git commit -m "Implement Parameter Store and Secrets Manager integration"

# Push apenas para dev
git push origin dev

# Testar no ambiente dev antes de fazer merge para prod
```

## 📦 **Estrutura dos Módulos Atualizada**

### **Módulo RDS (`modules/rds/`):**
- Agora cria o secret da senha junto com o banco
- Secrets separados: `bia-dev-db-password` e `bia-prod-db-password`

### **Módulo Secrets (`modules/secrets/`):**
- Apenas Parameter Store
- Parâmetros: `rdsendpointdev/prod`, `portdb`, `userdb`

### **Módulo ECS Service:**
- Task Definition usa secrets do RDS e parâmetros específicos
- Variáveis de ambiente obtidas dinamicamente

## 🔍 **Troubleshooting**

### **Problema: Task não consegue acessar secrets**
```bash
# Verificar se o secret existe
aws secretsmanager describe-secret --secret-id bia-dev-db-password

# Verificar parâmetros
aws ssm describe-parameters --filters Key=Name,Values=rdsendpointdev
```

### **Problema: Parâmetros não encontrados**
```bash
# Listar todos os parâmetros
aws ssm describe-parameters

# Verificar parâmetro específico
aws ssm get-parameter --name userdb
```

## 📋 **Checklist de Deploy DEV**

- [ ] Aplicar Terraform na branch dev
- [ ] Verificar criação do secret `bia-dev-db-password`
- [ ] Verificar criação dos parâmetros: `rdsendpointdev`, `portdb`, `userdb`
- [ ] Testar conectividade da aplicação com o banco
- [ ] Verificar logs do ECS para erros de autenticação
- [ ] Validar funcionamento antes de merge para prod

## 🔄 **Próximos Passos**

1. **Testar na DEV**: Validar toda a funcionalidade
2. **Ajustes se necessário**: Corrigir problemas encontrados
3. **Merge para PROD**: Após validação completa na dev
4. **Deploy PROD**: Aplicar as mudanças em produção

## 📞 **Suporte**

Para dúvidas sobre a configuração de secrets:
1. Consulte os logs do CloudWatch
2. Verifique as permissões IAM
3. Teste acesso aos secrets via AWS CLI
4. Entre em contato com a equipe de infraestrutura