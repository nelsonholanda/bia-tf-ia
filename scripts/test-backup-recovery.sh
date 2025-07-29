#!/bin/bash

# BIA Backup Recovery Test Script
# Usage: ./test-backup-recovery.sh [dev|prod]

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
DRY_RUN=${2:-"true"}

# Validate environment
if [[ "$ENVIRONMENT" != "dev" && "$ENVIRONMENT" != "prod" ]]; then
    error "Environment must be 'dev' or 'prod'"
    exit 1
fi

log "Starting backup recovery test for environment: $ENVIRONMENT"
if [[ "$DRY_RUN" == "true" ]]; then
    warning "Running in DRY RUN mode - no actual restore will be performed"
fi
echo "=================================================================="

# Function to get latest recovery point
get_latest_recovery_point() {
    log "Finding latest recovery point..."
    
    local vault_name="bia-$ENVIRONMENT-backup-vault"
    
    local latest_point=$(aws backup list-recovery-points-by-backup-vault \
        --backup-vault-name $vault_name \
        --query 'RecoveryPoints | sort_by(@, &CreationDate) | [-1].{
            Arn:RecoveryPointArn,
            Resource:ResourceArn,
            Created:CreationDate,
            Status:Status,
            Size:BackupSizeInBytes
        }' \
        --output json 2>/dev/null)
    
    if [[ $? -eq 0 && "$latest_point" != "null" ]]; then
        local point_arn=$(echo $latest_point | jq -r '.Arn')
        local resource_arn=$(echo $latest_point | jq -r '.Resource')
        local created=$(echo $latest_point | jq -r '.Created')
        local status=$(echo $latest_point | jq -r '.Status')
        local size=$(echo $latest_point | jq -r '.Size')
        
        if [[ "$status" == "COMPLETED" ]]; then
            success "Latest recovery point found:"
            echo "  ARN: $point_arn"
            echo "  Resource: $(basename $resource_arn)"
            echo "  Created: $created"
            echo "  Size: $((size / 1024 / 1024)) MB"
            echo "  Status: $status"
            
            echo "$point_arn"
        else
            error "Latest recovery point is not in COMPLETED status: $status"
            return 1
        fi
    else
        error "No recovery points found in vault: $vault_name"
        return 1
    fi
}

# Function to validate backup integrity
validate_backup_integrity() {
    local recovery_point_arn=$1
    
    log "Validating backup integrity..."
    
    # Get recovery point details
    local point_details=$(aws backup describe-recovery-point \
        --backup-vault-name "bia-$ENVIRONMENT-backup-vault" \
        --recovery-point-arn "$recovery_point_arn" \
        --query '{
            Status:Status,
            Size:BackupSizeInBytes,
            Created:CreationDate,
            Completed:CompletionDate,
            Lifecycle:Lifecycle
        }' \
        --output json 2>/dev/null)
    
    if [[ $? -eq 0 ]]; then
        local status=$(echo $point_details | jq -r '.Status')
        local size=$(echo $point_details | jq -r '.Size')
        local created=$(echo $point_details | jq -r '.Created')
        local completed=$(echo $point_details | jq -r '.Completed')
        
        if [[ "$status" == "COMPLETED" && "$size" -gt 0 ]]; then
            success "Backup integrity validation passed"
            echo "  Status: $status"
            echo "  Size: $((size / 1024 / 1024)) MB"
            echo "  Duration: $(date -d "$completed" +%s) - $(date -d "$created" +%s) = $(($(date -d "$completed" +%s) - $(date -d "$created" +%s))) seconds"
            return 0
        else
            error "Backup integrity validation failed"
            echo "  Status: $status"
            echo "  Size: $size bytes"
            return 1
        fi
    else
        error "Failed to get recovery point details"
        return 1
    fi
}

# Function to prepare restore metadata
prepare_restore_metadata() {
    local environment=$1
    
    log "Preparing restore metadata..."
    
    # Generate unique identifier for test restore
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local test_db_identifier="bia-$environment-db-test-restore-$timestamp"
    
    # Get original RDS configuration
    local original_config=$(aws rds describe-db-instances \
        --db-instance-identifier "bia-$environment-db" \
        --query 'DBInstances[0].{
            Class:DBInstanceClass,
            Engine:Engine,
            Version:EngineVersion,
            MultiAZ:MultiAZ,
            StorageType:StorageType,
            AllocatedStorage:AllocatedStorage
        }' \
        --output json 2>/dev/null)
    
    if [[ $? -eq 0 ]]; then
        local db_class=$(echo $original_config | jq -r '.Class')
        local engine=$(echo $original_config | jq -r '.Engine')
        local version=$(echo $original_config | jq -r '.Version')
        
        # Use smaller instance class for test
        local test_class="db.t3.micro"
        
        success "Restore metadata prepared:"
        echo "  Test DB Identifier: $test_db_identifier"
        echo "  Instance Class: $test_class (original: $db_class)"
        echo "  Engine: $engine $version"
        
        # Create metadata JSON
        local metadata=$(cat <<EOF
{
    "DBInstanceIdentifier": "$test_db_identifier",
    "DBInstanceClass": "$test_class",
    "Engine": "$engine",
    "MultiAZ": false,
    "PubliclyAccessible": false,
    "StorageType": "gp2",
    "AllocatedStorage": 20,
    "DeletionProtection": false,
    "BackupRetentionPeriod": 0,
    "Tags": [
        {
            "Key": "Environment",
            "Value": "$environment"
        },
        {
            "Key": "Purpose",
            "Value": "BackupRecoveryTest"
        },
        {
            "Key": "CreatedBy",
            "Value": "backup-recovery-test-script"
        },
        {
            "Key": "DeleteAfter",
            "Value": "$(date -d '+1 day' --iso-8601)"
        }
    ]
}
EOF
        )
        
        echo "$metadata"
    else
        error "Failed to get original RDS configuration"
        return 1
    fi
}

# Function to start restore job
start_restore_job() {
    local recovery_point_arn=$1
    local metadata=$2
    
    log "Starting restore job..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        warning "DRY RUN: Would start restore job with the following parameters:"
        echo "  Recovery Point: $recovery_point_arn"
        echo "  Metadata: $metadata"
        return 0
    fi
    
    # Get backup role ARN
    local backup_role_arn
    if [[ -f "main.tf" ]]; then
        terraform init -backend-config="backend-$ENVIRONMENT.hcl" -reconfigure > /dev/null 2>&1
        backup_role_arn=$(terraform output -raw backup_role_arn 2>/dev/null)
    fi
    
    if [[ -z "$backup_role_arn" ]]; then
        error "Could not get backup role ARN from terraform output"
        return 1
    fi
    
    # Start restore job
    local restore_job=$(aws backup start-restore-job \
        --recovery-point-arn "$recovery_point_arn" \
        --metadata "$metadata" \
        --iam-role-arn "$backup_role_arn" \
        --query 'RestoreJobId' \
        --output text 2>/dev/null)
    
    if [[ $? -eq 0 && -n "$restore_job" ]]; then
        success "Restore job started successfully"
        echo "  Job ID: $restore_job"
        echo "  Recovery Point: $recovery_point_arn"
        
        # Monitor restore job
        monitor_restore_job "$restore_job"
    else
        error "Failed to start restore job"
        return 1
    fi
}

# Function to monitor restore job
monitor_restore_job() {
    local job_id=$1
    
    log "Monitoring restore job: $job_id"
    
    local max_attempts=60  # 30 minutes (30 seconds * 60)
    local attempt=0
    
    while [[ $attempt -lt $max_attempts ]]; do
        local job_status=$(aws backup describe-restore-job \
            --restore-job-id "$job_id" \
            --query '{
                Status:Status,
                Progress:PercentDone,
                Created:CreationDate,
                Expected:ExpectedCompletionDate,
                Resource:CreatedResourceArn
            }' \
            --output json 2>/dev/null)
        
        if [[ $? -eq 0 ]]; then
            local status=$(echo $job_status | jq -r '.Status')
            local progress=$(echo $job_status | jq -r '.Progress // "0"')
            local resource=$(echo $job_status | jq -r '.Resource // "N/A"')
            
            case $status in
                "COMPLETED")
                    success "Restore job completed successfully!"
                    echo "  Status: $status"
                    echo "  Progress: ${progress}%"
                    echo "  Restored Resource: $resource"
                    
                    # Verify restored database
                    verify_restored_database "$resource"
                    return 0
                    ;;
                "FAILED"|"ABORTED")
                    error "Restore job failed: $status"
                    return 1
                    ;;
                "RUNNING"|"PENDING")
                    log "Restore job in progress: $status (${progress}%)"
                    ;;
                *)
                    warning "Unknown restore job status: $status"
                    ;;
            esac
        else
            error "Failed to get restore job status"
            return 1
        fi
        
        sleep 30
        ((attempt++))
    done
    
    error "Restore job monitoring timed out after 30 minutes"
    return 1
}

# Function to verify restored database
verify_restored_database() {
    local resource_arn=$1
    
    log "Verifying restored database..."
    
    if [[ "$resource_arn" == "N/A" ]]; then
        warning "No resource ARN provided for verification"
        return 1
    fi
    
    # Extract DB identifier from ARN
    local db_identifier=$(basename "$resource_arn")
    
    # Wait for database to be available
    log "Waiting for database to be available..."
    aws rds wait db-instance-available --db-instance-identifier "$db_identifier"
    
    if [[ $? -eq 0 ]]; then
        # Get database details
        local db_details=$(aws rds describe-db-instances \
            --db-instance-identifier "$db_identifier" \
            --query 'DBInstances[0].{
                Status:DBInstanceStatus,
                Engine:Engine,
                Version:EngineVersion,
                Class:DBInstanceClass,
                Endpoint:Endpoint.Address
            }' \
            --output json 2>/dev/null)
        
        if [[ $? -eq 0 ]]; then
            local status=$(echo $db_details | jq -r '.Status')
            local engine=$(echo $db_details | jq -r '.Engine')
            local version=$(echo $db_details | jq -r '.Version')
            local class=$(echo $db_details | jq -r '.Class')
            local endpoint=$(echo $db_details | jq -r '.Endpoint')
            
            success "Database verification completed"
            echo "  Identifier: $db_identifier"
            echo "  Status: $status"
            echo "  Engine: $engine $version"
            echo "  Class: $class"
            echo "  Endpoint: $endpoint"
            
            # Schedule cleanup
            schedule_cleanup "$db_identifier"
        else
            error "Failed to get restored database details"
            return 1
        fi
    else
        error "Database did not become available within timeout"
        return 1
    fi
}

# Function to schedule cleanup
schedule_cleanup() {
    local db_identifier=$1
    
    log "Scheduling cleanup for test database..."
    
    warning "IMPORTANT: Test database created: $db_identifier"
    warning "This database will incur costs until deleted!"
    echo ""
    echo "To clean up manually, run:"
    echo "  aws rds delete-db-instance \\"
    echo "    --db-instance-identifier $db_identifier \\"
    echo "    --skip-final-snapshot \\"
    echo "    --delete-automated-backups"
    echo ""
    
    # Create cleanup script
    local cleanup_script="/tmp/cleanup-$db_identifier.sh"
    cat > "$cleanup_script" << EOF
#!/bin/bash
echo "Cleaning up test database: $db_identifier"
aws rds delete-db-instance \\
  --db-instance-identifier $db_identifier \\
  --skip-final-snapshot \\
  --delete-automated-backups
echo "Cleanup completed for: $db_identifier"
rm -f $cleanup_script
EOF
    
    chmod +x "$cleanup_script"
    
    echo "Cleanup script created: $cleanup_script"
    echo "Run this script to clean up the test database when done."
}

# Function to run pre-flight checks
run_preflight_checks() {
    log "Running pre-flight checks..."
    
    # Check AWS CLI access
    aws sts get-caller-identity > /dev/null 2>&1
    if [[ $? -ne 0 ]]; then
        error "AWS CLI not configured or no access"
        return 1
    fi
    
    # Check if terraform directory exists
    if [[ ! -f "main.tf" ]]; then
        error "Please run this script from the terraform directory"
        return 1
    fi
    
    # Check backup vault exists
    local vault_name="bia-$ENVIRONMENT-backup-vault"
    aws backup describe-backup-vault --backup-vault-name "$vault_name" > /dev/null 2>&1
    if [[ $? -ne 0 ]]; then
        error "Backup vault not found: $vault_name"
        return 1
    fi
    
    success "Pre-flight checks passed"
    return 0
}

# Main execution
main() {
    # Run pre-flight checks
    if ! run_preflight_checks; then
        exit 1
    fi
    
    # Get latest recovery point
    local recovery_point_arn
    recovery_point_arn=$(get_latest_recovery_point)
    if [[ $? -ne 0 ]]; then
        exit 1
    fi
    
    echo ""
    
    # Validate backup integrity
    if ! validate_backup_integrity "$recovery_point_arn"; then
        exit 1
    fi
    
    echo ""
    
    # Prepare restore metadata
    local metadata
    metadata=$(prepare_restore_metadata "$ENVIRONMENT")
    if [[ $? -ne 0 ]]; then
        exit 1
    fi
    
    echo ""
    
    # Confirm before proceeding
    if [[ "$DRY_RUN" != "true" ]]; then
        warning "This will create a test RDS instance that will incur costs!"
        read -p "Do you want to proceed? (yes/no): " confirm
        if [[ "$confirm" != "yes" ]]; then
            log "Recovery test cancelled by user"
            exit 0
        fi
    fi
    
    # Start restore job
    if ! start_restore_job "$recovery_point_arn" "$metadata"; then
        exit 1
    fi
    
    echo ""
    echo "=================================================================="
    success "Backup recovery test completed for environment: $ENVIRONMENT"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "To run actual recovery test, use: $0 $ENVIRONMENT false"
    else
        warning "Don't forget to clean up the test database to avoid charges!"
    fi
}

# Show usage if help requested
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Usage: $0 [environment] [dry_run]"
    echo ""
    echo "Arguments:"
    echo "  environment  Environment to test (dev|prod) [default: prod]"
    echo "  dry_run      Run in dry-run mode (true|false) [default: true]"
    echo ""
    echo "Examples:"
    echo "  $0 prod true     # Dry run for production"
    echo "  $0 prod false    # Actual test for production"
    echo "  $0 dev false     # Actual test for development"
    exit 0
fi

# Run main function
main
