# Security Documentation

## Overview
This document outlines the security measures implemented in the microservices infrastructure.

## Security Features

### 1. Network Security
- **VPC Isolation**: All resources are deployed in a private VPC with controlled access
- **Security Groups**: Restrictive security groups with minimal required ports
  - ALB: Only ports 80/443 open to internet
  - ECS Services: Only port 3000 from ALB
  - Internal services: No direct internet access
- **Private Subnets**: ECS tasks run in private subnets with NAT Gateway for outbound access

### 2. Authentication & Authorization
- **Token-based Authentication**: Secure random tokens generated using Terraform's `random_password`
- **SSM Parameter Store**: Tokens stored as SecureString in AWS Systems Manager
- **Environment Variables**: Sensitive data injected as environment variables, not hardcoded

### 3. Data Protection
- **Encryption at Rest**: 
  - S3 bucket uses AES-256 encryption
  - SSM parameters use KMS encryption
  - ECS task logs encrypted in CloudWatch
- **Encryption in Transit**: HTTPS/TLS for all API communications

### 4. Container Security
- **Minimal Base Images**: Using official Node.js Alpine images
- **Non-root User**: Containers run as non-root user
- **Read-only Root Filesystem**: Where possible, containers use read-only filesystems
- **Security Scanning**: ECR provides vulnerability scanning for container images

### 5. Access Control
- **IAM Roles**: Least privilege principle applied to all AWS resources
- **Task Roles**: ECS tasks have minimal required permissions
- **No Hardcoded Credentials**: All AWS access via IAM roles

## Security Best Practices Implemented

### Infrastructure as Code
- All security configurations are version-controlled
- Terraform state is stored securely in S3 with encryption
- No sensitive data in source code

### Monitoring & Logging
- All API requests are logged
- Failed authentication attempts are tracked
- CloudWatch logs for debugging and audit trails

### Input Validation
- All API endpoints validate input data
- SQL injection and XSS prevention measures
- Rate limiting on public endpoints

## Security Checklist

### Deployment Security
- [ ] Verify VPC and subnet configurations
- [ ] Confirm security group rules are restrictive
- [ ] Validate IAM roles have minimal permissions
- [ ] Check SSM parameters are encrypted
- [ ] Ensure S3 bucket encryption is enabled

### Runtime Security
- [ ] Monitor CloudWatch logs for suspicious activity
- [ ] Regularly rotate authentication tokens
- [ ] Review and update security groups
- [ ] Scan container images for vulnerabilities

### Operational Security
- [ ] Regular security assessments
- [ ] Keep dependencies updated
- [ ] Monitor AWS Config for compliance
- [ ] Backup and disaster recovery procedures

## Incident Response

### Authentication Failures
1. Check CloudWatch logs for error details
2. Verify SSM parameter values
3. Confirm ECS task environment variables
4. Rotate tokens if compromised

### Network Issues
1. Verify security group configurations
2. Check VPC and subnet routing
3. Validate ALB target group health
4. Review NAT Gateway connectivity

### Container Security
1. Scan images for vulnerabilities
2. Update base images regularly
3. Monitor for suspicious container behavior
4. Implement network policies

## Security Monitoring

### Key Metrics to Monitor
- Authentication failure rates
- Unusual API access patterns
- Container resource usage anomalies
- Network traffic patterns

### Alerting
- Set up CloudWatch alarms for security events
- Configure SNS notifications for critical alerts
- Monitor ECS service health and task failures

## Compliance Considerations

### Data Privacy
- Ensure data handling complies with relevant regulations
- Implement data retention policies
- Consider data sovereignty requirements

### Audit Requirements
- Maintain audit logs for all system access
- Regular security assessments
- Document security procedures and changes

## Security Updates

### Regular Tasks
- Monthly security patch reviews
- Quarterly security assessments
- Annual penetration testing
- Continuous dependency scanning

### Emergency Response
- Procedures for security incident response
- Communication protocols for security issues
- Recovery procedures for compromised systems
