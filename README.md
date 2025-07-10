# Microservices CI/CD Infrastructure Project

## 🎯 Project Overview

This project demonstrates a complete cloud-native microservices architecture with automated CI/CD deployment on AWS. It features two Node.js microservices communicating through AWS SQS, with secure token authentication, automated testing, and infrastructure as code using Terraform.

### 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Internet      │    │   Application    │    │   ECS Cluster   │
│   Gateway       │────│   Load Balancer  │────│   Microservice 1│
│                 │    │                  │    │   (API Receiver)│
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                                         │
                                                ┌─────────────────┐
                                                │   Amazon SQS    │
                                                │     Queue       │
                                                └─────────────────┘
                                                         │
                                                ┌─────────────────┐
                                                │   ECS Cluster   │
                                                │   Microservice 2│
                                                │   (SQS Worker)  │
                                                └─────────────────┘
                                                         │
                                                ┌─────────────────┐
                                                │   Amazon S3     │
                                                │   Data Bucket   │
                                                └─────────────────┘
```

### 🚀 Key Features

- **🔒 Secure Authentication**: 32-character cryptographically random API tokens
- **🏗️ Infrastructure as Code**: Complete Terraform configuration with modules
- **🔄 CI/CD Pipeline**: GitHub Actions with automated testing and deployment
- **📊 Container Orchestration**: AWS ECS with auto-scaling and health checks
- **🔐 Security**: IAM roles, security groups, encrypted SSM parameters
- **📈 Monitoring**: CloudWatch logs and metrics integration
- **🧪 Comprehensive Testing**: Unit, integration, and end-to-end tests

## 📋 Prerequisites

### Required Tools

1. **AWS CLI** (v2.x or later)
   ```bash
   aws --version
   # aws-cli/2.x.x Python/3.x.x
   ```

2. **Terraform** (v1.0.0 or later)
   ```bash
   terraform --version
   # Terraform v1.5.7
   ```

3. **Docker** (for local testing)
   ```bash
   docker --version
   # Docker version 20.x.x
   ```

4. **Git** (for version control)
   ```bash
   git --version
   # git version 2.x.x
   ```

### AWS Account Requirements

- **AWS Account** with administrative privileges
- **AWS CLI configured** with appropriate credentials
- **Estimated Cost**: $10-20/month for development environment

### GitHub Requirements

- **GitHub repository** with Actions enabled
- **AWS credentials** configured as GitHub Secrets:
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`

## 🚀 Quick Start Guide

### Step 1: Clone and Setup

```bash
# Clone the repository
git clone <your-repo-url>
cd microservices-checkpoint

# Verify prerequisites
./scripts/check-prerequisites.sh
```

### Step 2: Configure AWS Credentials

```bash
# Configure AWS CLI
aws configure
# AWS Access Key ID: [Your Access Key]
# AWS Secret Access Key: [Your Secret Key]
# Default region name: us-east-2
# Default output format: json

# Verify AWS access
aws sts get-caller-identity
```

### Step 3: Deploy Infrastructure

```bash
# Navigate to infrastructure directory
cd infra

# Initialize Terraform
terraform init

# Plan deployment (review resources)
terraform plan

# Deploy infrastructure
terraform apply -auto-approve
```

### Step 4: Verify Deployment

```bash
# Get outputs
ALB_DNS=$(terraform output -raw alb_dns_name)
TOKEN=$(terraform output -raw api_token_value)

# Test health endpoint
curl -s "http://$ALB_DNS/health"

# Test API endpoint
curl -X POST "http://$ALB_DNS/submit" \
  -H "Content-Type: application/json" \
  -d "{\"token\":\"$TOKEN\",\"data\":{\"email_sender\":\"test@example.com\",\"email_subject\":\"Test\",\"email_timestream\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}}"
```

## 📚 Detailed Documentation

### 🏗️ Infrastructure & Deployment

- **[Infrastructure Guide](docs/INFRASTRUCTURE.md)** - Detailed AWS architecture and resource descriptions
- **[Deployment Guide](docs/DEPLOYMENT.md)** - Complete deployment procedures and troubleshooting
- **[Security Guide](docs/SECURITY.md)** - Security implementation, best practices, and compliance

### 🔧 Development & Testing

- **[API Documentation](docs/API.md)** - Complete API reference with examples
- **[Testing Guide](docs/TESTING.md)** - Testing strategies, procedures, and automation
- **[Monitoring Guide](docs/MONITORING.md)** - Observability, alerting, and performance monitoring

### 🔄 CI/CD Pipeline

- **[CI/CD Setup](docs/CICD.md)** - GitHub Actions configuration
- **[Deployment Process](docs/DEPLOYMENT.md)** - Step-by-step deployment
- **[Monitoring Guide](docs/MONITORING.md)** - Observability and alerts

### 🧪 Testing

- **[Testing Guide](docs/TESTING.md)** - Comprehensive testing strategy
- **[API Documentation](docs/API.md)** - API endpoints and usage

## 🛠️ Development Workflow

### Making Changes

1. **Update Code**: Modify microservice code in `services/` directory
2. **Commit & Push**: Git commit triggers CI/CD pipeline
3. **Automated Testing**: GitHub Actions runs tests and builds images
4. **Deployment**: New images deployed to ECS automatically
5. **Verification**: Health checks and integration tests run

### Local Development

```bash
# Run services locally
cd services/microservice-1
npm install
npm start

# Run tests
npm test

# Build Docker image
docker build -t microservice-1 .
```

## 🔧 Troubleshooting

### Common Issues

#### 1. Terraform State Lock
```bash
# If state is locked, check DynamoDB
aws dynamodb scan --table-name microdemo-terraform-locks

# Force unlock (use with caution)
terraform force-unlock <LOCK_ID>
```

#### 2. ECS Service Not Starting
```bash
# Check ECS service status
aws ecs describe-services --cluster microdemo-ecs-cluster --services microdemo-service

# Check task definition
aws ecs describe-task-definition --task-definition microdemo-task

# View logs
aws logs get-log-events --log-group-name /ecs/microdemo --log-stream-name <stream-name>
```

#### 3. API Authentication Issues
```bash
# Get current token
terraform output -raw api_token_value

# Test with correct token
curl -X POST "http://your-alb/submit" -H "Content-Type: application/json" -d '{"token":"your-token","data":{...}}'
```

#### 4. CI/CD Pipeline Failures
- Check GitHub Actions logs in repository
- Verify AWS credentials are configured correctly
- Ensure ECR repositories exist and are accessible

### Getting Help

1. **Check Logs**: CloudWatch logs contain detailed error information
2. **Review Documentation**: Comprehensive guides in `docs/` directory
3. **Validate Configuration**: Use provided validation scripts
4. **Test Incrementally**: Use step-by-step testing procedures

## 📊 Project Structure

```
microservices-checkpoint/
├── README.md                     # This file
├── .github/workflows/            # CI/CD pipeline configuration
│   └── ci-cd.yml                 # GitHub Actions workflow
├── services/                     # Microservices source code
│   ├── microservice-1/           # API receiver service
│   └── microservice-2/           # SQS worker service
├── infra/                        # Terraform infrastructure
│   ├── main.tf                   # Main infrastructure configuration
│   ├── variables.tf              # Input variables
│   ├── outputs.tf                # Output values
│   └── modules/                  # Reusable Terraform modules
├── scripts/                      # Utility scripts
│   ├── check-prerequisites.sh    # Verify system requirements
│   ├── deploy.sh                 # Automated deployment
│   └── test.sh                   # Comprehensive testing
├── tests/                        # Test suites
│   ├── unit/                     # Unit tests
│   ├── integration/              # Integration tests
│   └── e2e/                      # End-to-end tests
└── docs/                         # Detailed documentation
    ├── INFRASTRUCTURE.md         # Infrastructure details
    ├── SECURITY.md               # Security implementation
    ├── TESTING.md                # Testing procedures
    └── API.md                    # API documentation
```

## 🎯 Success Criteria

After successful deployment, you should have:

- ✅ **Working API**: Health check returns HTTP 200
- ✅ **Secure Authentication**: API requires valid token
- ✅ **Message Processing**: Data flows from API → SQS → S3
- ✅ **Input Validation**: Invalid data properly rejected
- ✅ **CI/CD Pipeline**: Code changes trigger automated deployment
- ✅ **Infrastructure Stability**: `terraform plan` shows no changes
- ✅ **Monitoring**: CloudWatch logs show application activity

## 📈 Performance & Scaling

- **Auto Scaling**: ECS services scale based on CPU/memory utilization
- **Load Balancing**: ALB distributes traffic across healthy instances
- **Health Checks**: Automatic replacement of unhealthy containers
- **Resource Limits**: CPU and memory limits prevent resource exhaustion

## 🔐 Security Features

- **Encrypted Storage**: SSM parameters use AWS KMS encryption
- **IAM Roles**: Least privilege access for ECS tasks
- **Network Security**: Security groups restrict traffic flow
- **Token Authentication**: Cryptographically secure API tokens
- **Input Validation**: Comprehensive data validation and sanitization

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📞 Support

For support and questions:
- Review the documentation in the `docs/` directory
- Check the troubleshooting section above
- Open an issue in the GitHub repository

---

**🎉 Ready to deploy? Follow the Quick Start Guide above!**