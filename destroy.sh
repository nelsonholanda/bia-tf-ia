#!/bin/bash

# Script para destruir recursos Terraform na ordem correta
# Uso: ./destroy.sh <environment>

set -e

ENVIRONMENT=${1:-dev}
BACKEND_CONFIG="backend-${ENVIRONMENT}.hcl"

echo "🗑️ Iniciando destruição da infraestrutura do ambiente: $ENVIRONMENT"

# Verificar se o arquivo de backend existe
if [ ! -f "$BACKEND_CONFIG" ]; then
    echo "❌ Arquivo de backend $BACKEND_CONFIG não encontrado!"
    exit 1
fi

# Inicializar Terraform
echo "🔧 Inicializando Terraform..."
terraform init -backend-config="$BACKEND_CONFIG" -reconfigure

# Verificar se há recursos para destruir
echo "📊 Verificando recursos existentes..."
RESOURCE_COUNT=$(terraform state list 2>/dev/null | wc -l || echo "0")

if [ "$RESOURCE_COUNT" -eq "0" ]; then
    echo "ℹ️ Nenhum recurso encontrado para destruir."
    exit 0
fi

echo "📋 Recursos encontrados: $RESOURCE_COUNT"

# Função para destruir recursos específicos
destroy_resources() {
    local resources=("$@")
    for resource in "${resources[@]}"; do
        if terraform state list | grep -q "$resource"; then
            echo "🗑️ Destruindo: $resource"
            terraform destroy -target="$resource" -var="environment=$ENVIRONMENT" -auto-approve || {
                echo "⚠️ Falha ao destruir $resource, continuando..."
            }
        fi
    done
}

# Ordem de destruição (do mais dependente para o menos dependente)
echo "🚀 Iniciando destruição ordenada..."

# 1. Auto Scaling Policies (mais dependentes)
echo "📍 Fase 1: Removendo políticas de auto scaling..."
destroy_resources \
    "module.ecs_service.aws_appautoscaling_policy.ecs_memory_policy"

# 2. Auto Scaling Targets
echo "📍 Fase 2: Removendo targets de auto scaling..."
destroy_resources \
    "module.ecs_service.aws_appautoscaling_target.ecs_target"

# 3. ECS Service
echo "📍 Fase 3: Removendo serviço ECS..."
destroy_resources \
    "module.ecs_service.aws_ecs_service.main"

# 4. ECS Task Definition
echo "📍 Fase 4: Removendo task definition..."
destroy_resources \
    "module.ecs_service.aws_ecs_task_definition.main"

# 5. ECS Cluster Capacity Providers
echo "📍 Fase 5: Removendo capacity providers..."
destroy_resources \
    "module.ecs_cluster.aws_ecs_cluster_capacity_providers.main"

# 6. ECS Capacity Provider
echo "📍 Fase 6: Removendo capacity provider..."
destroy_resources \
    "module.ecs_cluster.aws_ecs_capacity_provider.main"

# 7. Auto Scaling Group
echo "📍 Fase 7: Removendo auto scaling group..."
destroy_resources \
    "module.ecs_cluster.aws_autoscaling_group.ecs"

# 8. Launch Template
echo "📍 Fase 8: Removendo launch template..."
destroy_resources \
    "module.ecs_cluster.aws_launch_template.ecs"

# 9. ECS Cluster
echo "📍 Fase 9: Removendo cluster ECS..."
destroy_resources \
    "module.ecs_cluster.aws_ecs_cluster.main"

# 10. ALB Resources
echo "📍 Fase 10: Removendo recursos do ALB..."
destroy_resources \
    "module.alb.aws_lb_listener.bia_listener" \
    "module.alb.aws_lb.bia_alb" \
    "module.alb.aws_lb_target_group.bia_tg"

# 11. RDS
echo "📍 Fase 11: Removendo RDS..."
destroy_resources \
    "module.rds.aws_db_instance.bia" \
    "module.rds.aws_db_subnet_group.bia"

# 12. Security Groups
echo "📍 Fase 12: Removendo security groups..."
destroy_resources \
    "module.security_groups.aws_security_group.bia_dev" \
    "module.security_groups.aws_security_group.bia_alb" \
    "module.security_groups.aws_security_group.bia_ec2" \
    "module.security_groups.aws_security_group.bia_rds"

# 13. VPC Resources (NAT Gateway primeiro)
echo "📍 Fase 13: Removendo recursos de rede..."
destroy_resources \
    "module.vpc.aws_nat_gateway.main" \
    "module.vpc.aws_eip.nat" \
    "module.vpc.aws_route_table_association.private_1a" \
    "module.vpc.aws_route_table_association.private_1c" \
    "module.vpc.aws_route_table_association.private_1f" \
    "module.vpc.aws_route_table_association.public_1a" \
    "module.vpc.aws_route_table_association.public_1c" \
    "module.vpc.aws_route_table_association.public_1f" \
    "module.vpc.aws_route_table.private" \
    "module.vpc.aws_route_table.public" \
    "module.vpc.aws_subnet.private_1a" \
    "module.vpc.aws_subnet.private_1c" \
    "module.vpc.aws_subnet.private_1f" \
    "module.vpc.aws_subnet.public_1a" \
    "module.vpc.aws_subnet.public_1c" \
    "module.vpc.aws_subnet.public_1f" \
    "module.vpc.aws_internet_gateway.main" \
    "module.vpc.aws_vpc.main"

# 14. IAM Resources
echo "📍 Fase 14: Removendo recursos IAM..."
destroy_resources \
    "module.iam.aws_iam_role_policy_attachment.ecs_instance_role_policy" \
    "module.iam.aws_iam_role_policy_attachment.ecs_instance_ssm_policy" \
    "module.iam.aws_iam_role_policy_attachment.ecs_task_execution_role_policy" \
    "module.iam.aws_iam_instance_profile.ecs_instance_profile" \
    "module.iam.aws_iam_role.ecs_instance_role" \
    "module.iam.aws_iam_role.ecs_task_execution_role"

# 15. CloudWatch
echo "📍 Fase 15: Removendo CloudWatch..."
destroy_resources \
    "module.cloudwatch.aws_cloudwatch_log_group.ecs_logs"

# 16. Destruição final (qualquer recurso restante)
echo "📍 Fase Final: Verificando recursos restantes..."
REMAINING_RESOURCES=$(terraform state list 2>/dev/null | wc -l || echo "0")

if [ "$REMAINING_RESOURCES" -gt "0" ]; then
    echo "⚠️ Ainda existem $REMAINING_RESOURCES recursos. Executando destroy completo..."
    terraform destroy -var="environment=$ENVIRONMENT" -auto-approve
else
    echo "✅ Todos os recursos foram destruídos com sucesso!"
fi

# Verificação final
FINAL_COUNT=$(terraform state list 2>/dev/null | wc -l || echo "0")
if [ "$FINAL_COUNT" -eq "0" ]; then
    echo "🎉 Destruição completa! Ambiente $ENVIRONMENT limpo."
else
    echo "⚠️ Ainda restam $FINAL_COUNT recursos. Verifique manualmente."
    terraform state list
fi