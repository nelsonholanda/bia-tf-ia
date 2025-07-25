# 🔐 Configuração de Secrets e Parameter Store - VERSÃO CORRIGIDA

## 📋 Resumo das Mudanças

Implementação corrigida conforme especificações:

### ✅ **Implementações Realizadas:**

1. **Secrets padronizados** - Nomenclatura `bia-{environment}-secrets`
2. **Credenciais completas** - Todos os dados do banco em um único secret
3. **Permissões IAM atualizadas** - Acesso aos secrets para ECS tasks
4. **Task Definition atualizada** - Usa secrets em vez de environment variables
5. **Scripts de validação** - Verificação automática da configuração
6. **Correção de endpoint** - Host separado da porta corretamente

## 🏗️ **Arquitetura de Secrets**

### **AWS Secrets Manager (Credenciais Completas do Banco):**
- `bia-dev-secrets` - Credenciais completas do banco (DEV)
- `bia-prod-secrets` - Credenciais completas do banco (PROD)

### **Estrutura do Secret:**
```json
{
  "username": "postgres",
  "password": "generated_password",
  "engine": "postgres",
  "host": "hostname_only",
  "port": 5432,
  "dbname": "bia"
}
```

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
# Verificar manualmente
aws secretsmanager get-secret-value --secret-id bia-dev-db-password

# Verificar parâmetros (se usando Parameter Store)
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
aws secretsmanager update-secret --secret-id bia-dev-secrets --secret-string "NovaSenha123"
```

### **Método 3: Via Console AWS**
1. Acesse AWS Secrets Manager
2. Encontre o secret `bia-dev-secrets`
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
- Cria o secret completo junto com o banco
- Nomenclatura padronizada: `bia-{environment}-secrets`
- Todas as credenciais em um único secret

### **Módulo ECS Service:**
- Task Definition usa secrets do Secrets Manager
- Variáveis de ambiente obtidas dinamicamente do secret
- Suporte completo para ambos os ambientes (dev/prod)

## 🔍 **Troubleshooting**

### **Problema: Host do banco contém porta (CORRIGIDO)**
**Sintoma**: Aplicação não consegue conectar ao banco porque o endpoint vem com porta junto (ex: `host:5432`)

**Solução implementada**:
- Uso de regex para extrair apenas o hostname: `regex("^([^:]+)", aws_db_instance.bia.endpoint)[0]`
- Validação manual através de comandos AWS CLI

**Como verificar**:
```bash
# Verificar manualmente o secret
aws secretsmanager get-secret-value --secret-id bia-dev-db-password | jq '.SecretString | fromjson'
```

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

## 🔧 **Correção do Problema do Endpoint com Porta**

### **Problema Identificado:**
O endpoint do RDS estava sendo armazenado no secret com a porta incluída (ex: `hostname:5432`), causando problemas de conectividade na aplicação.

### **Solução Implementada:**
1. **Regex para extrair hostname**: `regex("^([^:]+)", aws_db_instance.bia.endpoint)[0]`
2. **Local value para processamento**: Criado `local.db_host` para garantir consistência
3. **Validação manual**: Comandos AWS CLI para verificar configuração
4. **Outputs adicionais**: Para facilitar debug e monitoramento

### **Como Aplicar a Correção:**

```bash
# 1. Aplicar as mudanças no Terraform
terraform plan -var="environment=dev"
terraform apply -var="environment=dev"

# 2. Reiniciar o serviço ECS para pegar os novos secrets
aws ecs update-service --cluster bia-dev-cluster --service bia-dev-service --force-new-deployment
```

## 📋 **Checklist de Deploy DEV**

- [ ] Aplicar Terraform na branch dev
- [ ] Verificar criação do secret `bia-dev-secrets`
- [ ] **NOVO**: Validar configuração manualmente com AWS CLI
- [ ] Verificar que o host não contém porta (apenas hostname)
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