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
