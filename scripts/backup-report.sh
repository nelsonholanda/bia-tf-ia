#!/bin/bash

# BIA Backup Report Script
# Usage: ./backup-report.sh [dev|prod] [days]

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

# Default values
ENVIRONMENT=${1:-"prod"}
DAYS=${2:-"7"}

# Validate environment
if [[ "$ENVIRONMENT" != "dev" && "$ENVIRONMENT" != "prod" ]]; then
    error "Environment must be 'dev' or 'prod'"
    exit 1
fi

log "Generating backup report for environment: $ENVIRONMENT (last $DAYS days)"
echo "=================================================================="

# Function to get backup jobs
get_backup_jobs() {
    local state=$1
    local title=$2
    
    log "Checking $title backup jobs..."
    
    local start_date=$(date -d "$DAYS days ago" --iso-8601)
    
    local jobs=$(aws backup list-backup-jobs \
        --by-state $state \
        --by-created-after $start_date \
        --query "BackupJobs[?contains(ResourceArn, 'bia-$ENVIRONMENT')].{
            JobId:BackupJobId,
            Resource:ResourceArn,
            State:State,
            Created:CreationDate,
            Completed:CompletionDate,
            Size:BackupSizeInBytes,
            Vault:BackupVaultName
        }" \
        --output json 2>/dev/null)
    
    if [[ $? -eq 0 ]]; then
        local job_count=$(echo $jobs | jq 'length')
        
        if [[ "$job_count" -gt 0 ]]; then
            success "$title: $job_count jobs found"
            echo ""
            printf "%-20s %-15s %-25s %-25s %-10s\n" "Job ID" "State" "Created" "Completed" "Size (MB)"
            echo "--------------------------------------------------------------------------------------------------------"
            
            echo $jobs | jq -r '.[] | [
                .JobId[0:18],
                .State,
                (.Created // "N/A"),
                (.Completed // "N/A"),
                (if .Size then (.Size / 1024 / 1024 | floor | tostring) else "N/A" end)
            ] | @tsv' | while IFS=$'\t' read -r job_id state created completed size; do
                printf "%-20s %-15s %-25s %-25s %-10s\n" "$job_id" "$state" "$created" "$completed" "$size"
            done
        else
            warning "$title: No jobs found in the last $DAYS days"
        fi
    else
        error "Failed to get $title backup jobs"
    fi
    
    echo ""
}

# Function to get recovery points
get_recovery_points() {
    log "Checking recovery points..."
    
    local vault_name="bia-$ENVIRONMENT-backup-vault"
    
    local recovery_points=$(aws backup list-recovery-points-by-backup-vault \
        --backup-vault-name $vault_name \
        --query 'RecoveryPoints[].{
            Arn:RecoveryPointArn,
            Resource:ResourceArn,
            Created:CreationDate,
            Status:Status,
            Size:BackupSizeInBytes,
            Lifecycle:Lifecycle
        }' \
        --output json 2>/dev/null)
    
    if [[ $? -eq 0 ]]; then
        local point_count=$(echo $recovery_points | jq 'length')
        
        if [[ "$point_count" -gt 0 ]]; then
            success "Recovery Points: $point_count points available"
            echo ""
            printf "%-25s %-15s %-25s %-10s\n" "Created" "Status" "Resource" "Size (MB)"
            echo "-----------------------------------------------------------------------------------------"
            
            echo $recovery_points | jq -r '.[] | [
                .Created,
                .Status,
                (.Resource | split("/") | last),
                (if .Size then (.Size / 1024 / 1024 | floor | tostring) else "N/A" end)
            ] | @tsv' | head -10 | while IFS=$'\t' read -r created status resource size; do
                printf "%-25s %-15s %-25s %-10s\n" "$created" "$status" "$resource" "$size"
            done
            
            if [[ "$point_count" -gt 10 ]]; then
                echo "... and $(($point_count - 10)) more recovery points"
            fi
        else
            warning "No recovery points found in vault: $vault_name"
        fi
    else
        error "Failed to get recovery points from vault: $vault_name"
    fi
    
    echo ""
}

# Function to check backup vault details
get_vault_details() {
    log "Checking backup vault details..."
    
    local vault_name="bia-$ENVIRONMENT-backup-vault"
    
    local vault_info=$(aws backup describe-backup-vault \
        --backup-vault-name $vault_name \
        --query '{
            Name:BackupVaultName,
            Arn:BackupVaultArn,
            KmsKey:EncryptionKeyArn,
            Created:CreationDate,
            NumberOfRecoveryPoints:NumberOfRecoveryPoints
        }' \
        --output json 2>/dev/null)
    
    if [[ $? -eq 0 ]]; then
        local vault_name_out=$(echo $vault_info | jq -r '.Name')
        local recovery_points=$(echo $vault_info | jq -r '.NumberOfRecoveryPoints')
        local kms_key=$(echo $vault_info | jq -r '.KmsKey // "Default"')
        local created=$(echo $vault_info | jq -r '.Created')
        
        success "Backup Vault: $vault_name_out"
        echo "  Recovery Points: $recovery_points"
        echo "  KMS Key: $(basename $kms_key)"
        echo "  Created: $created"
    else
        error "Failed to get backup vault details"
    fi
    
    echo ""
}

# Function to check backup plan
get_backup_plan() {
    log "Checking backup plan configuration..."
    
    # Get backup plan ARN from terraform output
    if [[ -f "main.tf" ]]; then
        terraform init -backend-config="backend-$ENVIRONMENT.hcl" -reconfigure > /dev/null 2>&1
        local plan_arn=$(terraform output -raw backup_plan_arn 2>/dev/null)
        
        if [[ -n "$plan_arn" ]]; then
            local plan_id=$(basename $plan_arn)
            
            local plan_info=$(aws backup get-backup-plan \
                --backup-plan-id $plan_id \
                --query 'BackupPlan.{
                    Name:BackupPlanName,
                    Rules:Rules[].{
                        Name:RuleName,
                        Schedule:ScheduleExpression,
                        Lifecycle:Lifecycle,
                        Vault:TargetBackupVaultName
                    }
                }' \
                --output json 2>/dev/null)
            
            if [[ $? -eq 0 ]]; then
                local plan_name=$(echo $plan_info | jq -r '.Name')
                success "Backup Plan: $plan_name"
                
                echo $plan_info | jq -r '.Rules[] | "  Rule: \(.Name)
    Schedule: \(.Schedule)
    Vault: \(.Vault)
    Lifecycle: \(.Lifecycle.DeleteAfterDays // "N/A") days retention"'
            else
                error "Failed to get backup plan details"
            fi
        else
            warning "Could not get backup plan ARN from terraform output"
        fi
    fi
    
    echo ""
}

# Function to show backup costs (estimate)
estimate_backup_costs() {
    log "Estimating backup costs..."
    
    local vault_name="bia-$ENVIRONMENT-backup-vault"
    
    # Get total backup size
    local total_size=$(aws backup list-recovery-points-by-backup-vault \
        --backup-vault-name $vault_name \
        --query 'sum(RecoveryPoints[].BackupSizeInBytes)' \
        --output text 2>/dev/null)
    
    if [[ "$total_size" != "null" && "$total_size" != "None" && -n "$total_size" ]]; then
        local size_gb=$((total_size / 1024 / 1024 / 1024))
        local estimated_cost=$(echo "scale=2; $size_gb * 0.05" | bc 2>/dev/null || echo "N/A")
        
        success "Storage Usage: ${size_gb} GB"
        echo "  Estimated monthly cost: \$${estimated_cost} (at \$0.05/GB/month)"
        echo "  Note: This is a rough estimate. Check AWS Billing for actual costs."
    else
        warning "Could not calculate backup storage size"
    fi
    
    echo ""
}

# Function to check cross-region backup (prod only)
check_cross_region_backup() {
    if [[ "$ENVIRONMENT" == "prod" ]]; then
        log "Checking cross-region backup (production only)..."
        
        # This would require checking the backup region
        # For now, just show if cross-region is configured
        local cross_region_vault="bia-prod-backup-vault-cross-region"
        
        # Check if cross-region vault exists (this is a simplified check)
        aws backup describe-backup-vault \
            --backup-vault-name $cross_region_vault \
            --region us-west-2 \
            --query 'BackupVaultName' \
            --output text > /dev/null 2>&1
        
        if [[ $? -eq 0 ]]; then
            success "Cross-region backup: Configured in us-west-2"
        else
            warning "Cross-region backup: Not found or not accessible"
        fi
        
        echo ""
    fi
}

# Main execution
main() {
    get_backup_jobs "COMPLETED" "Completed"
    get_backup_jobs "RUNNING" "Running"
    get_backup_jobs "FAILED" "Failed"
    get_recovery_points
    get_vault_details
    get_backup_plan
    estimate_backup_costs
    check_cross_region_backup
    
    echo "=================================================================="
    success "Backup report completed for environment: $ENVIRONMENT"
    log "For detailed backup management, visit AWS Backup console"
    echo "https://console.aws.amazon.com/backup/home?region=us-east-1#/backupvaults"
}

# Check if bc is available for cost calculation
if ! command -v bc &> /dev/null; then
    warning "bc command not found. Cost estimation will be disabled."
fi

# Run main function
main
