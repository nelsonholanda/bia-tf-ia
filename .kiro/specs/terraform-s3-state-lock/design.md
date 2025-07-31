# Design Document

## Overview

Este documento descreve o design para migrar o mecanismo de state lock do Terraform de DynamoDB para S3 object locking. A solução utilizará recursos nativos do S3 para gerenciar tanto o armazenamento do estado quanto o controle de concorrência, eliminando a necessidade de tabelas DynamoDB dedicadas para lock.

## Architecture

### Current Architecture
```
Terraform State Management:
├── S3 Bucket (tf-nh)
│   ├── State Files (.tfstate)
│   └── Versioning enabled
└── DynamoDB Tables
    ├── terraform-state-lock-bia-dev
    └── terraform-state-lock-bia-prod
```

### Target Architecture
```
Terraform State Management:
└── S3 Bucket (tf-nh)
    ├── State Files (.tfstate)
    ├── Versioning enabled
    ├── Object Lock enabled
    └── Legal Hold for critical states
```

### Migration Strategy

1. **Phase 1: Preparation**
   - Enable S3 Object Lock on existing bucket
   - Update backend configurations
   - Test lock functionality

2. **Phase 2: Migration**
   - Update backend-dev.hcl and backend-prod.hcl
   - Remove DynamoDB table references
   - Reinitialize Terraform backends

3. **Phase 3: Cleanup**
   - Verify lock functionality
   - Remove DynamoDB tables
   - Update documentation

## Components and Interfaces

### S3 Bucket Configuration

**Object Lock Settings:**
- **Mode:** Governance mode for flexibility
- **Retention Period:** 1 day minimum
- **Legal Hold:** Available for critical operations

**Bucket Policy Updates:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::194722426008:root"
      },
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:GetObjectLockConfiguration",
        "s3:PutObjectLockConfiguration",
        "s3:GetObjectRetention",
        "s3:PutObjectRetention"
      ],
      "Resource": "arn:aws:s3:::tf-nh/*"
    }
  ]
}
```

### Backend Configuration Changes

**Before (with DynamoDB):**
```hcl
bucket         = "tf-nh"
key            = "kiro-tf-bia/[env]/terraform.tfstate"
region         = "us-east-1"
encrypt        = true
dynamodb_table = "terraform-state-lock-bia-[env]"
```

**After (S3 only):**
```hcl
bucket         = "tf-nh"
key            = "kiro-tf-bia/[env]/terraform.tfstate"
region         = "us-east-1"
encrypt        = true
# dynamodb_table removed - S3 object lock used instead
```

### Terraform Lock Mechanism

**S3 Object Lock Implementation:**
- Terraform will use S3's native object locking
- Lock files stored as separate objects with retention
- Automatic cleanup after operations complete
- Conflict resolution through S3 versioning

## Data Models

### State File Structure
```
s3://tf-nh/
├── kiro-tf-bia/
│   ├── dev/
│   │   ├── terraform.tfstate
│   │   └── .terraform.lock.hcl
│   └── prod/
│       ├── terraform.tfstate
│       └── .terraform.lock.hcl
```

### Lock Object Metadata
```json
{
  "LockID": "unique-lock-identifier",
  "Operation": "apply|plan|destroy",
  "Info": "user@hostname",
  "Who": "terraform-user",
  "Version": "terraform-version",
  "Created": "2025-01-30T10:00:00Z",
  "Path": "kiro-tf-bia/[env]/terraform.tfstate"
}
```

## Error Handling

### Lock Acquisition Failures
1. **Scenario:** Multiple users attempt simultaneous operations
   - **Detection:** S3 returns object lock conflict
   - **Response:** Terraform displays lock information and waits
   - **Resolution:** Automatic retry with exponential backoff

2. **Scenario:** Stale lock from interrupted operation
   - **Detection:** Lock older than retention period
   - **Response:** Automatic cleanup by S3 object lock expiration
   - **Resolution:** New operation can proceed

3. **Scenario:** S3 service unavailability
   - **Detection:** S3 API errors
   - **Response:** Terraform fails with clear error message
   - **Resolution:** Retry when S3 service is restored

### Migration Rollback Plan
1. **Backup current state files**
2. **Restore DynamoDB table configuration**
3. **Revert backend configuration files**
4. **Reinitialize Terraform with DynamoDB**

## Testing Strategy

### Unit Tests
- Backend configuration validation
- Lock acquisition and release
- Error handling scenarios

### Integration Tests
- Multi-user concurrent operations
- State file integrity during lock operations
- Cross-environment consistency

### Migration Tests
1. **Pre-migration validation**
   - Verify current state integrity
   - Test DynamoDB lock functionality
   - Backup all state files

2. **Migration execution**
   - Enable S3 object lock
   - Update backend configurations
   - Test lock acquisition

3. **Post-migration validation**
   - Verify S3 lock functionality
   - Test concurrent operations
   - Validate state file integrity

### Performance Tests
- Lock acquisition time comparison
- State file access latency
- Concurrent operation handling

## Security Considerations

### Access Control
- IAM policies updated for S3 object lock permissions
- Principle of least privilege maintained
- Cross-account access restrictions

### Encryption
- State files encrypted at rest (S3-SSE)
- Lock objects encrypted with same key
- In-transit encryption via HTTPS

### Audit Trail
- CloudTrail logging for all S3 operations
- Lock acquisition/release events logged
- State modification tracking

## Implementation Phases

### Phase 1: Preparation (Day 1)
1. Enable S3 Object Lock on tf-nh bucket
2. Update IAM policies for object lock permissions
3. Create backup of current state files
4. Test object lock functionality

### Phase 2: Development Environment (Day 2)
1. Update backend-dev.hcl configuration
2. Reinitialize Terraform for dev environment
3. Test lock functionality with dev operations
4. Validate state integrity

### Phase 3: Production Environment (Day 3)
1. Update backend-prod.hcl configuration
2. Reinitialize Terraform for prod environment
3. Test lock functionality with prod operations
4. Validate state integrity

### Phase 4: Cleanup (Day 4)
1. Verify both environments working correctly
2. Remove DynamoDB tables
3. Update documentation and scripts
4. Monitor for any issues

## Monitoring and Alerting

### Metrics to Track
- Lock acquisition success rate
- Lock duration times
- State file access patterns
- Error rates and types

### Alerts
- Failed lock acquisitions
- Stale locks (beyond retention)
- State file corruption
- S3 service issues

## Rollback Strategy

### Immediate Rollback (if issues detected)
1. Stop all Terraform operations
2. Restore backend configurations to use DynamoDB
3. Reinitialize Terraform backends
4. Verify functionality with DynamoDB

### Data Recovery
1. Restore state files from S3 versioning
2. Verify state consistency
3. Resume normal operations

This design ensures a smooth migration from DynamoDB to S3 object locking while maintaining security, reliability, and performance of Terraform state management.