#!/bin/bash

# Local validation script for Terraform
# Usage: ./validate-local.sh [environment]

set -e

ENVIRONMENT=${1:-dev}
BACKEND_CONFIG="backend-${ENVIRONMENT}.hcl"

echo "🔍 Running local Terraform validation for environment: $ENVIRONMENT"
echo "=================================================="

# Check if required tools are installed
check_tool() {
    if ! command -v $1 &> /dev/null; then
        echo "❌ $1 is not installed. Please install it first."
        return 1
    else
        echo "✅ $1 is available"
        return 0
    fi
}

echo ""
echo "📋 Checking required tools..."
echo "=================================================="

TOOLS_OK=true
check_tool "terraform" || TOOLS_OK=false
check_tool "tfsec" || echo "⚠️  tfsec not found - security scanning will be skipped"
check_tool "checkov" || echo "⚠️  checkov not found - security scanning will be skipped"

if [ "$TOOLS_OK" = false ]; then
    echo ""
    echo "❌ Missing required tools. Please install them first:"
    echo "   - Terraform: https://www.terraform.io/downloads"
    echo "   - tfsec: https://github.com/aquasecurity/tfsec#installation"
    echo "   - checkov: pip install checkov"
    exit 1
fi

echo ""
echo "📋 Step 1: Terraform Format Check..."
echo "=================================================="

if terraform fmt -check -recursive; then
    echo "✅ Terraform format check passed"
else
    echo "❌ Terraform format check failed"
    echo "💡 Run 'terraform fmt -recursive' to fix formatting"
    exit 1
fi

echo ""
echo "📋 Step 2: Terraform Initialization..."
echo "=================================================="

if [ ! -f "$BACKEND_CONFIG" ]; then
    echo "❌ Backend configuration file not found: $BACKEND_CONFIG"
    exit 1
fi

terraform init -backend-config="$BACKEND_CONFIG"
echo "✅ Terraform initialized successfully"

echo ""
echo "📋 Step 3: Terraform Validation..."
echo "=================================================="

if terraform validate; then
    echo "✅ Terraform validation passed"
else
    echo "❌ Terraform validation failed"
    exit 1
fi

echo ""
echo "📋 Step 4: Terraform Plan..."
echo "=================================================="

if terraform plan -var="environment=$ENVIRONMENT" -out="tfplan-$ENVIRONMENT" -detailed-exitcode; then
    PLAN_EXIT_CODE=$?
    if [ $PLAN_EXIT_CODE -eq 0 ]; then
        echo "✅ No changes needed"
    elif [ $PLAN_EXIT_CODE -eq 2 ]; then
        echo "✅ Plan created successfully with changes"
        echo "💡 Review the plan above before applying"
    fi
else
    echo "❌ Terraform plan failed"
    exit 1
fi

echo ""
echo "📋 Step 5: Security Scanning..."
echo "=================================================="

# Run tfsec if available
if command -v tfsec &> /dev/null; then
    echo "🔒 Running tfsec security scan..."
    if tfsec . --config-file .tfsec/config.yml; then
        echo "✅ tfsec scan completed"
    else
        echo "⚠️  tfsec found security issues (see above)"
    fi
else
    echo "⚠️  Skipping tfsec scan (not installed)"
fi

echo ""

# Run checkov if available
if command -v checkov &> /dev/null; then
    echo "🔒 Running checkov security scan..."
    if checkov -f .checkov.yml; then
        echo "✅ checkov scan completed"
    else
        echo "⚠️  checkov found security issues (see above)"
    fi
else
    echo "⚠️  Skipping checkov scan (not installed)"
fi

echo ""
echo "📋 Step 6: Plan Summary..."
echo "=================================================="

if [ -f "tfplan-$ENVIRONMENT" ]; then
    echo "📄 Terraform plan saved as: tfplan-$ENVIRONMENT"
    echo ""
    echo "📊 Plan summary:"
    terraform show -no-color "tfplan-$ENVIRONMENT" | head -20
    echo ""
    echo "💡 To apply the plan, run:"
    echo "   terraform apply tfplan-$ENVIRONMENT"
    echo ""
    echo "💡 To see the full plan, run:"
    echo "   terraform show tfplan-$ENVIRONMENT"
fi

echo ""
echo "🎉 Local validation completed!"
echo "=================================================="
echo ""
echo "📋 Summary:"
echo "   ✅ Format check passed"
echo "   ✅ Terraform validation passed"
echo "   ✅ Plan created successfully"
echo "   🔒 Security scans completed (check results above)"
echo ""
echo "🚀 Ready for deployment!"

# Clean up plan file if no changes
if [ -f "tfplan-$ENVIRONMENT" ]; then
    PLAN_CHANGES=$(terraform show -json "tfplan-$ENVIRONMENT" | jq -r '.resource_changes | length')
    if [ "$PLAN_CHANGES" = "0" ]; then
        rm -f "tfplan-$ENVIRONMENT"
        echo "🧹 Cleaned up empty plan file"
    fi
fi