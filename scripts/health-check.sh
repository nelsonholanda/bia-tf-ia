#!/bin/bash

# BIA Infrastructure Health Check Script
# Usage: ./health-check.sh [dev|prod]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Validate environment parameter
if [[ $# -ne 1 ]]; then
    error "Usage: $0 [dev|prod]"
    exit 1
fi

ENVIRONMENT=$1

if [[ "$ENVIRONMENT" != "dev" && "$ENVIRONMENT" != "prod" ]]; then
    error "Environment must be 'dev' or 'prod'"
    exit 1
fi

log "Starting BIA Infrastructure Health Check for environment: $ENVIRONMENT"
echo "=================================================================="

# Check if we're in the right directory
if [[ ! -f "main.tf" ]]; then
    error "Please run this script from the terraform directory"
    exit 1
fi

# Initialize terraform to get outputs
log "Initializing Terraform..."
terraform init -backend-config="backend-$ENVIRONMENT.hcl" -reconfigure > /dev/null 2>&1

# Function to check ECS Service
check_ecs_service() {
    log "Checking ECS Service..."
    
    local service_info=$(aws ecs describe-services \
        --cluster bia-$ENVIRONMENT-cluster \
        --services bia-$ENVIRONMENT-service \
        --query 'services[0].{Status:status,Running:runningCount,Desired:desiredCount,Pending:pendingCount}' \
        --output json 2>/dev/null)
    
    if [[ $? -eq 0 && "$service_info" != "null" ]]; then
        local status=$(echo $service_info | jq -r '.Status')
        local running=$(echo $service_info | jq -r '.Running')
        local desired=$(echo $service_info | jq -r '.Desired')
        local pending=$(echo $service_info | jq -r '.Pending')
        
        if [[ "$status" == "ACTIVE" && "$running" -eq "$desired" ]]; then
            success "ECS Service: $status | Running: $running/$desired | Pending: $pending"
        else
            warning "ECS Service: $status | Running: $running/$desired | Pending: $pending"
        fi
    else
        error "Failed to get ECS service information"
    fi
}

# Function to check RDS Instance
check_rds_instance() {
    log "Checking RDS Instance..."
    
    local rds_info=$(aws rds describe-db-instances \
        --db-instance-identifier bia-$ENVIRONMENT-db \
        --query 'DBInstances[0].{Status:DBInstanceStatus,MultiAZ:MultiAZ,Engine:Engine,Class:DBInstanceClass}' \
        --output json 2>/dev/null)
    
    if [[ $? -eq 0 && "$rds_info" != "null" ]]; then
        local status=$(echo $rds_info | jq -r '.Status')
        local multi_az=$(echo $rds_info | jq -r '.MultiAZ')
        local engine=$(echo $rds_info | jq -r '.Engine')
        local class=$(echo $rds_info | jq -r '.Class')
        
        if [[ "$status" == "available" ]]; then
            success "RDS Instance: $status | Engine: $engine | Class: $class | Multi-AZ: $multi_az"
        else
            warning "RDS Instance: $status | Engine: $engine | Class: $class | Multi-AZ: $multi_az"
        fi
    else
        error "Failed to get RDS instance information"
    fi
}

# Function to check ALB and Target Health
check_alb_health() {
    log "Checking ALB and Target Health..."
    
    # Get ALB ARN from terraform output
    local alb_arn=$(terraform output -raw alb_arn 2>/dev/null)
    local target_group_arn=$(terraform output -raw alb_target_group_arn 2>/dev/null)
    
    if [[ -n "$alb_arn" ]]; then
        local alb_info=$(aws elbv2 describe-load-balancers \
            --load-balancer-arns $alb_arn \
            --query 'LoadBalancers[0].{State:State.Code,DNS:DNSName}' \
            --output json 2>/dev/null)
        
        if [[ $? -eq 0 ]]; then
            local state=$(echo $alb_info | jq -r '.State')
            local dns=$(echo $alb_info | jq -r '.DNS')
            
            if [[ "$state" == "active" ]]; then
                success "ALB Status: $state | DNS: $dns"
            else
                warning "ALB Status: $state | DNS: $dns"
            fi
        fi
    fi
    
    # Check target health
    if [[ -n "$target_group_arn" ]]; then
        local target_health=$(aws elbv2 describe-target-health \
            --target-group-arn $target_group_arn \
            --query 'TargetHealthDescriptions[].{Target:Target.Id,Health:TargetHealth.State,Reason:TargetHealth.Reason}' \
            --output json 2>/dev/null)
        
        if [[ $? -eq 0 ]]; then
            local healthy_count=$(echo $target_health | jq '[.[] | select(.Health == "healthy")] | length')
            local total_count=$(echo $target_health | jq 'length')
            
            if [[ "$healthy_count" -eq "$total_count" && "$total_count" -gt 0 ]]; then
                success "Target Health: $healthy_count/$total_count targets healthy"
            else
                warning "Target Health: $healthy_count/$total_count targets healthy"
                echo $target_health | jq -r '.[] | "  - Target: \(.Target) | Health: \(.Health) | Reason: \(.Reason // "N/A")"'
            fi
        fi
    fi
}

# Function to check CloudWatch Alarms
check_cloudwatch_alarms() {
    log "Checking CloudWatch Alarms..."
    
    local alarm_states=$(aws cloudwatch describe-alarms \
        --alarm-name-prefix "bia-$ENVIRONMENT" \
        --query 'MetricAlarms[].{Name:AlarmName,State:StateValue,Reason:StateReason}' \
        --output json 2>/dev/null)
    
    if [[ $? -eq 0 ]]; then
        local alarm_count=$(echo $alarm_states | jq 'length')
        local ok_count=$(echo $alarm_states | jq '[.[] | select(.State == "OK")] | length')
        local alarm_count_state=$(echo $alarm_states | jq '[.[] | select(.State == "ALARM")] | length')
        
        if [[ "$alarm_count_state" -eq 0 ]]; then
            success "CloudWatch Alarms: $ok_count/$alarm_count alarms OK"
        else
            warning "CloudWatch Alarms: $alarm_count_state alarms in ALARM state"
            echo $alarm_states | jq -r '.[] | select(.State == "ALARM") | "  - \(.Name): \(.State) - \(.Reason)"'
        fi
    else
        error "Failed to get CloudWatch alarm information"
    fi
}

# Function to check Backup Status
check_backup_status() {
    log "Checking Backup Status..."
    
    local recent_backups=$(aws backup list-backup-jobs \
        --by-state COMPLETED \
        --max-results 5 \
        --query 'BackupJobs[?contains(ResourceArn, `bia-'$ENVIRONMENT'`)].{JobId:BackupJobId,Resource:ResourceArn,Created:CreationDate,Completed:CompletionDate}' \
        --output json 2>/dev/null)
    
    if [[ $? -eq 0 ]]; then
        local backup_count=$(echo $recent_backups | jq 'length')
        
        if [[ "$backup_count" -gt 0 ]]; then
            success "Recent Backups: $backup_count completed backup jobs found"
            echo $recent_backups | jq -r '.[] | "  - Job: \(.JobId) | Completed: \(.Completed)"' | head -3
        else
            warning "No recent backup jobs found for environment: $ENVIRONMENT"
        fi
    else
        warning "Failed to get backup information"
    fi
}

# Function to check VPC Endpoints (cost optimization)
check_vpc_endpoints() {
    log "Checking VPC Endpoints..."
    
    local vpc_id=$(terraform output -raw vpc_id 2>/dev/null)
    
    if [[ -n "$vpc_id" ]]; then
        local endpoints=$(aws ec2 describe-vpc-endpoints \
            --filters "Name=vpc-id,Values=$vpc_id" \
            --query 'VpcEndpoints[].{Service:ServiceName,State:State,Type:VpcEndpointType}' \
            --output json 2>/dev/null)
        
        if [[ $? -eq 0 ]]; then
            local endpoint_count=$(echo $endpoints | jq 'length')
            local available_count=$(echo $endpoints | jq '[.[] | select(.State == "available")] | length')
            
            if [[ "$endpoint_count" -gt 0 ]]; then
                success "VPC Endpoints: $available_count/$endpoint_count endpoints available"
                echo $endpoints | jq -r '.[] | "  - \(.Service): \(.State) (\(.Type))"'
            else
                warning "No VPC endpoints found"
            fi
        fi
    fi
}

# Function to show resource summary
show_resource_summary() {
    log "Resource Summary..."
    
    local app_url=$(terraform output -raw application_url 2>/dev/null)
    local dashboard_url=$(terraform output -raw monitoring_dashboard_url 2>/dev/null)
    
    echo ""
    echo "📋 Resource Information:"
    echo "  Application URL: ${app_url:-'Not available'}"
    echo "  Dashboard URL: ${dashboard_url:-'Not available'}"
    echo "  Environment: $ENVIRONMENT"
    echo "  Region: $(aws configure get region)"
    echo "  Account: $(aws sts get-caller-identity --query Account --output text 2>/dev/null)"
}

# Main execution
main() {
    check_ecs_service
    echo ""
    check_rds_instance
    echo ""
    check_alb_health
    echo ""
    check_cloudwatch_alarms
    echo ""
    check_backup_status
    echo ""
    check_vpc_endpoints
    echo ""
    show_resource_summary
    
    echo ""
    echo "=================================================================="
    success "Health check completed for environment: $ENVIRONMENT"
    log "For detailed monitoring, visit the CloudWatch dashboard"
}

# Run main function
main
