# API Token Management

## Overview
The microservices use a secure API token stored in AWS SSM Parameter Store for authentication. The token is automatically generated using Terraform's random provider with security best practices.

## Token Generation
- **Length**: 32 characters
- **Character set**: Upper/lowercase letters, numbers, and safe special characters
- **Storage**: AWS SSM Parameter Store as SecureString (encrypted)
- **Generation**: Automatic via Terraform random provider

## Token Security Features

### ✅ Security Best Practices Implemented:
1. **Random Generation**: 32-character cryptographically secure random token
2. **Encrypted Storage**: Stored as SecureString in SSM Parameter Store
3. **Environment Variable Injection**: Passed to containers securely
4. **Sensitive Marking**: Terraform treats the value as sensitive
5. **Safe Character Set**: Excludes characters that could cause HTTP/JSON issues

### 🔧 Token Retrieval:

#### For Testing/Development:
```bash
# Get the token value (requires AWS CLI access)
terraform output -raw api_token_value

# Or directly from SSM:
aws ssm get-parameter --name "/microservices-demo/api-token" --with-decryption --query 'Parameter.Value' --output text
```

#### For Applications:
The token is automatically injected as `TOKEN_SECRET` environment variable into ECS containers.

### 🔄 Token Rotation:

#### Method 1: Terraform Regeneration
```bash
# Force regeneration of the token
terraform apply -replace="random_password.api_token"
```

#### Method 2: Manual Update
```bash
# Update with a custom token
aws ssm put-parameter --name "/microservices-demo/api-token" \
  --value "your-new-secure-token" --type SecureString --overwrite

# Restart ECS services to pick up the new token
aws ecs update-service --cluster microdemo-ecs-cluster --service microdemo-service --force-new-deployment
aws ecs update-service --cluster microdemo-ecs-cluster --service microdemo-worker-service --force-new-deployment
```

### 📝 API Usage:

```bash
# Get the current token
TOKEN=$(terraform output -raw api_token_value)

# Use in API calls
curl -X POST "http://your-alb-dns/submit" \
  -H "Content-Type: application/json" \
  -d "{\"token\":\"$TOKEN\",\"data\":{\"email_sender\":\"test@example.com\",\"email_subject\":\"Test\",\"email_timestream\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}}"
```

### 🔐 Production Considerations:

1. **Token Lifecycle**: Consider implementing regular token rotation
2. **Access Control**: Limit SSM parameter access using IAM policies
3. **Monitoring**: Monitor API calls for unauthorized access attempts
4. **Backup**: Document the token rotation process for your team
5. **Multiple Environments**: Use different tokens for dev/staging/prod

### 🚀 Advanced Security Enhancements (Future):

- Implement JWT tokens with expiration
- Add rate limiting per token
- Implement client-specific tokens
- Add token usage audit logging
- Consider OAuth 2.0 or API Gateway authentication
