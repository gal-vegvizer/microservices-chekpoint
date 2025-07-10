#!/bin/bash

# Fix ALB Health Check Issues
# This script addresses the ALB health check failures by applying the necessary Terraform changes

set -e

echo "🚀 Deploying ALB Health Check Fixes..."

# Navigate to the infrastructure directory
cd infra

# Initialize Terraform (if needed)
echo "📋 Initializing Terraform..."
terraform init

# Validate the configuration
echo "✅ Validating Terraform configuration..."
terraform validate

# Plan the changes
echo "📊 Planning Terraform changes..."
terraform plan -out=fix-alb.tfplan

# Apply the changes
echo "🛠️ Applying fixes..."
read -p "Apply these changes? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    terraform apply fix-alb.tfplan
    echo "✅ Infrastructure fixes applied!"
else
    echo "❌ Deployment cancelled"
    exit 1
fi

# Clean up plan file
rm -f fix-alb.tfplan

echo ""
echo "🔍 Checking deployment status..."

# Wait a bit for resources to stabilize
echo "⏳ Waiting 30 seconds for resources to stabilize..."
sleep 30

# Check ECS service status
echo "📊 ECS Service Status:"
aws ecs describe-services \
    --cluster microdemo-cluster \
    --services microdemo-service \
    --query 'services[0].{DesiredCount:desiredCount,RunningCount:runningCount,PendingCount:pendingCount,Status:status}' \
    --output table \
    --region us-east-2

# Check target health
echo ""
echo "🏥 ALB Target Health:"
TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups \
    --names microdemo-tg \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text \
    --region us-east-2)

aws elbv2 describe-target-health \
    --target-group-arn "$TARGET_GROUP_ARN" \
    --region us-east-2

echo ""
echo "🌐 ALB DNS Name:"
aws elbv2 describe-load-balancers \
    --names microdemo-alb \
    --query 'LoadBalancers[0].DNSName' \
    --output text \
    --region us-east-2

echo ""
echo "✅ Deployment completed!"
echo ""
echo "💡 Next steps:"
echo "   1. Wait 2-3 minutes for health checks to stabilize"
echo "   2. Test the health endpoint: curl http://<ALB-DNS>/health"
echo "   3. Run the debug script if issues persist: ./debug-alb-health.sh"
