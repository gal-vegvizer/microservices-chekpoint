#!/bin/bash

# Debug script to check ALB target health
# Run this script to verify that the ALB can reach your ECS tasks

set -e

echo "🔍 Checking ALB Target Health..."

# Get the target group ARN
TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups \
    --names microdemo-tg \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text \
    --region us-east-2)

if [ "$TARGET_GROUP_ARN" == "None" ] || [ -z "$TARGET_GROUP_ARN" ]; then
    echo "❌ Target group 'microdemo-tg' not found"
    exit 1
fi

echo "📍 Target Group ARN: $TARGET_GROUP_ARN"

# Check target health
echo "🏥 Checking target health..."
aws elbv2 describe-target-health \
    --target-group-arn "$TARGET_GROUP_ARN" \
    --region us-east-2

echo ""
echo "🔍 Checking ALB details..."
aws elbv2 describe-load-balancers \
    --names microdemo-alb \
    --query 'LoadBalancers[0].{DNSName:DNSName,State:State.Code,Scheme:Scheme}' \
    --output table \
    --region us-east-2

echo ""
echo "🎯 Checking target group configuration..."
aws elbv2 describe-target-groups \
    --target-group-arns "$TARGET_GROUP_ARN" \
    --query 'TargetGroups[0].{Port:Port,Protocol:Protocol,HealthCheckPath:HealthCheckPath,HealthCheckPort:HealthCheckPort}' \
    --output table \
    --region us-east-2

echo ""
echo "📊 Checking ECS service status..."
aws ecs describe-services \
    --cluster microdemo-cluster \
    --services microdemo-service \
    --query 'services[0].{DesiredCount:desiredCount,RunningCount:runningCount,PendingCount:pendingCount}' \
    --output table \
    --region us-east-2

echo ""
echo "🔒 Checking security groups..."
ALB_SG=$(aws elbv2 describe-load-balancers \
    --names microdemo-alb \
    --query 'LoadBalancers[0].SecurityGroups[0]' \
    --output text \
    --region us-east-2)

echo "ALB Security Group: $ALB_SG"
aws ec2 describe-security-groups \
    --group-ids "$ALB_SG" \
    --query 'SecurityGroups[0].{GroupId:GroupId,IngressRules:IpPermissions}' \
    --output table \
    --region us-east-2

echo ""
echo "✅ Debug check completed!"
echo ""
echo "💡 If targets are unhealthy, check:"
echo "   1. ECS tasks are running and healthy"
echo "   2. Security groups allow ALB -> ECS communication on port 8080"
echo "   3. Health check endpoint /health returns 200 OK"
echo "   4. Container is binding to 0.0.0.0:8080, not localhost:8080"
