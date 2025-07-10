# Infrastructure Guide

## 🏗️ AWS Architecture Overview

This document provides detailed information about the AWS infrastructure components used in the microservices project.

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                                Internet                                              │
└─────────────────────────┬───────────────────────────────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────────────────────────────┐
│                     Internet Gateway                                                │
│                    (IGW-xxxxxxxxxxxx)                                               │
└─────────────────────────┬───────────────────────────────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────────────────────────────┐
│                   Application Load Balancer                                         │
│                     (microdemo-alb)                                                 │
│                   Listens on Port 80                                                │
└─────────────────────────┬───────────────────────────────────────────────────────────┘
                          │
            ┌─────────────▼─────────────┐
            │        Target Group       │
            │     (microdemo-tg)        │
            │    Health Check: /health  │
            └─────────────┬─────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────────────────────────────┐
│                         ECS Cluster                                                 │
│                    (microdemo-ecs-cluster)                                          │
│                                                                                     │
│  ┌─────────────────────────────────┐  ┌─────────────────────────────────────────┐  │
│  │      Microservice 1             │  │         Microservice 2                  │  │
│  │     (API Receiver)              │  │        (SQS Worker)                     │  │
│  │                                 │  │                                         │  │
│  │ • Receives HTTP requests        │  │ • Polls SQS for messages               │  │
│  │ • Validates token & data        │  │ • Processes messages                    │  │
│  │ • Sends messages to SQS         │  │ • Stores data in S3                     │  │
│  │ • Port: 8080                    │  │ • Port: 8080 (internal)                │  │
│  │                                 │  │                                         │  │
│  │ Container: Node.js + Express    │  │ Container: Node.js                      │  │
│  │ Task Definition: microdemo-task │  │ Task Definition: microdemo-worker-task  │  │
│  │ Service: microdemo-service      │  │ Service: microdemo-worker-service       │  │
│  └─────────────┬───────────────────┘  └───────────┬─────────────────────────────┘  │
└────────────────┼───────────────────────────────────┼─────────────────────────────────┘
                 │                                   │
                 │                                   │
        ┌────────▼────────┐                 ┌────────▼────────┐
        │   CloudWatch    │                 │   CloudWatch    │
        │   Log Group     │                 │   Log Group     │
        │ /ecs/microdemo  │                 │/ecs/microdemo-  │
        │                 │                 │    worker       │
        └─────────────────┘                 └─────────────────┘
                 │
                 │
        ┌────────▼────────┐
        │   Amazon SQS    │
        │     Queue       │
        │(microdemo-queue)│
        │                 │
        │ • FIFO: No      │
        │ • Retention: 14d│
        │ • Visibility: 30s│
        └─────────────────┘
                 │
                 │
        ┌────────▼────────┐
        │   Amazon S3     │
        │   Data Bucket   │
        │(microdemo-data- │
        │    bucket)      │
        │                 │
        │ • Stores JSON   │
        │ • Path: /data/  │
        │ • Encryption: On│
        └─────────────────┘
```

### Network Architecture

```
VPC: microdemo-vpc (10.0.0.0/16)
│
├── Public Subnet 1 (10.0.1.0/24) - us-east-2a
│   ├── Microservice 1 (API Receiver)
│   └── Application Load Balancer
│
├── Public Subnet 2 (10.0.2.0/24) - us-east-2b  
│   ├── Microservice 2 (SQS Worker)
│   └── Application Load Balancer
│
├── Internet Gateway (IGW)
├── Route Table (Public)
│   └── Route: 0.0.0.0/0 → IGW
│
└── Security Groups
    ├── ALB Security Group (HTTP from 0.0.0.0/0)
    ├── ECS API Receiver SG (Port 8080 from ALB SG)
    └── ECS SQS Worker SG (Port 8080 from 0.0.0.0/0)
```

## 📊 Infrastructure Components

### 1. Virtual Private Cloud (VPC)

**Resource**: `module.vpc`
**CIDR Block**: `10.0.0.0/16`

- **Purpose**: Isolated network environment for all resources
- **Subnets**: 2 public subnets across different AZs for high availability
- **Internet Gateway**: Enables internet access for public subnets
- **Route Tables**: Direct traffic to internet gateway

**Key Features**:
- Multi-AZ deployment for fault tolerance
- Public subnets for ALB and ECS services
- Custom route tables for traffic control

### 2. Application Load Balancer (ALB)

**Resource**: `module.alb`
**DNS**: `microdemo-alb-xxxxxxxxx.us-east-2.elb.amazonaws.com`

- **Purpose**: Distributes incoming HTTP traffic to healthy ECS tasks
- **Listener**: Port 80 (HTTP)
- **Target Group**: Routes to ECS tasks running on port 8080
- **Health Checks**: `/health` endpoint with 30s interval

**Configuration**:
```terraform
# Health Check Settings
health_check_path     = "/health"
health_check_interval = 30
health_check_timeout  = 5
healthy_threshold     = 2
unhealthy_threshold   = 5
```

### 3. Elastic Container Service (ECS)

**Cluster**: `microdemo-ecs-cluster`
**Launch Type**: EC2 (with Auto Scaling Group)

#### Microservice 1 (API Receiver)
- **Service**: `microdemo-service`
- **Task Definition**: `microdemo-task`
- **Desired Count**: 1
- **CPU**: 256 units (0.25 vCPU)
- **Memory**: 512 MB
- **Port Mapping**: 8080:8080

**Environment Variables**:
```
AWS_REGION=us-east-2
SQS_QUEUE_URL=https://sqs.us-east-2.amazonaws.com/ACCOUNT/microdemo-queue
TOKEN_SECRET=<secure-32-char-token>
```

#### Microservice 2 (SQS Worker)
- **Service**: `microdemo-worker-service`
- **Task Definition**: `microdemo-worker-task`
- **Desired Count**: 1
- **CPU**: 256 units (0.25 vCPU)
- **Memory**: 512 MB

**Environment Variables**:
```
AWS_REGION=us-east-2
SQS_QUEUE_URL=https://sqs.us-east-2.amazonaws.com/ACCOUNT/microdemo-queue
S3_BUCKET_NAME=microdemo-data-bucket
TOKEN_SECRET=<secure-32-char-token>
```

### 4. Elastic Container Registry (ECR)

**Repositories**:
- `microdemo/microservice-1`: API receiver container images
- `microdemo/microservice-2`: SQS worker container images

**Features**:
- Automatic image scanning for vulnerabilities
- Lifecycle policies for image retention
- IAM-based access control

### 5. Simple Queue Service (SQS)

**Queue**: `microdemo-queue`
**Type**: Standard Queue

**Configuration**:
- **Message Retention**: 14 days
- **Visibility Timeout**: 30 seconds
- **Max Receives**: 3 (before moving to DLQ)
- **Dead Letter Queue**: Not configured (future enhancement)

### 6. Simple Storage Service (S3)

**Bucket**: `microdemo-data-bucket`
**Purpose**: Store processed JSON messages from SQS

**Configuration**:
- **Versioning**: Disabled
- **Encryption**: Server-side encryption enabled
- **Public Access**: Blocked
- **Lifecycle**: Not configured (future enhancement)

### 7. Systems Manager (SSM) Parameter Store

**Parameters**:
1. `/microservices-demo/api-token` (SecureString)
   - 32-character random token for API authentication
   - Encrypted with AWS KMS

2. `/microdemo/images/api-receiver` (String)
   - Current Docker image URI for API receiver
   - Updated by CI/CD pipeline

3. `/microdemo/images/sqs-worker` (String)
   - Current Docker image URI for SQS worker
   - Updated by CI/CD pipeline

### 8. Identity and Access Management (IAM)

#### ECS Task Execution Role
**Role**: `microdemo-ecs-task-execution-role`

**Permissions**:
- Pull images from ECR
- Write logs to CloudWatch
- Access SSM parameters
- Send/receive SQS messages
- Read/write S3 objects

**Attached Policies**:
- `AmazonECSTaskExecutionRolePolicy` (AWS managed)
- `microdemo-ecs-task-policy` (custom policy)

**Custom Policy Permissions**:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::microdemo-data-bucket/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "sqs:SendMessage",
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage"
      ],
      "Resource": "arn:aws:sqs:us-east-2:ACCOUNT:microdemo-queue"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameter",
        "ssm:GetParameters"
      ],
      "Resource": "arn:aws:ssm:us-east-2:ACCOUNT:parameter/microservices-demo/*"
    }
  ]
}
```

### 9. CloudWatch Logging

**Log Groups**:
- `/ecs/microdemo`: API receiver service logs
- `/ecs/microdemo-worker`: SQS worker service logs

**Configuration**:
- **Retention**: 7 days (configurable)
- **Log Driver**: awslogs
- **Auto-creation**: Enabled

### 10. Security Groups

#### ALB Security Group
**Name**: `microdemo-alb-sg`
**Rules**:
- Inbound: Port 80 from 0.0.0.0/0 (HTTP)
- Outbound: All traffic to anywhere

#### ECS API Receiver Security Group  
**Name**: `microdemo-ecs-sg`
**Rules**:
- Inbound: Port 8080 from ALB Security Group
- Outbound: All traffic to anywhere

#### ECS SQS Worker Security Group
**Name**: `microdemo-worker-ecs-sg`
**Rules**:
- Inbound: Port 8080 from 0.0.0.0/0
- Outbound: All traffic to anywhere

## 🔧 Resource Specifications

### Compute Resources

| Component | CPU | Memory | Storage | Instance Type |
|-----------|-----|--------|---------|---------------|
| ECS Task (API) | 0.25 vCPU | 512 MB | N/A | Fargate |
| ECS Task (Worker) | 0.25 vCPU | 512 MB | N/A | Fargate |
| ALB | Managed | Managed | N/A | Managed |

### Storage Resources

| Component | Type | Size | Encryption |
|-----------|------|------|------------|
| S3 Bucket | Standard | Unlimited | SSE-S3 |
| CloudWatch Logs | Standard | 7-day retention | AES-256 |
| ECR Repositories | Standard | 10GB per repo | AES-256 |

### Network Resources

| Component | Bandwidth | Availability |
|-----------|-----------|--------------|
| ALB | Up to 25 Gbps | Multi-AZ |
| VPC | Up to 100 Gbps | Single Region |
| Internet Gateway | Up to 100 Gbps | Multi-AZ |

## 📈 Scaling and Performance

### Auto Scaling Configuration

Currently configured for basic deployment:
- **ECS Services**: Fixed desired count of 1
- **ALB**: Automatically scales based on traffic
- **SQS**: Serverless, scales automatically

### Future Scaling Enhancements

```terraform
# ECS Service Auto Scaling (not yet implemented)
resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 10
  min_capacity       = 1
  resource_id        = "service/microdemo-ecs-cluster/microdemo-service"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "scale_up" {
  name               = "scale-up"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70.0
  }
}
```

## 🔍 Monitoring and Observability

### CloudWatch Metrics

**ECS Metrics**:
- CPU Utilization
- Memory Utilization
- Task Count
- Service Events

**ALB Metrics**:
- Request Count
- Response Time
- HTTP Error Rates
- Target Health

**SQS Metrics**:
- Messages Sent
- Messages Received
- Queue Depth
- Message Age

### Health Checks

**ALB Target Group Health Check**:
- **Path**: `/health`
- **Protocol**: HTTP
- **Port**: 8080
- **Interval**: 30 seconds
- **Timeout**: 5 seconds
- **Healthy Threshold**: 2
- **Unhealthy Threshold**: 5

**ECS Task Health Check**:
- Container health check via Docker HEALTHCHECK
- Dependent on application `/health` endpoint

## 🛠️ Terraform Module Structure

```
infra/
├── main.tf              # Main infrastructure configuration
├── variables.tf         # Input variables
├── outputs.tf          # Output values
└── modules/
    ├── vpc/            # VPC, subnets, IGW, route tables
    ├── alb/            # Application Load Balancer
    ├── ecs/            # ECS cluster, services, task definitions
    ├── ecs_cluster/    # ECS cluster configuration
    ├── ecr/            # Elastic Container Registry
    ├── s3/             # S3 bucket configuration
    ├── sqs/            # SQS queue configuration
    ├── iam/            # IAM roles and policies
    ├── security_group/ # Security group configurations
    └── ssm_parameter/  # SSM parameter management
```

## 🔄 CI/CD Integration

### SSM Parameter Updates

The CI/CD pipeline updates SSM parameters with new image URIs:

```bash
# Update image URIs in SSM
aws ssm put-parameter --name "/microdemo/images/api-receiver" \
  --value "${ECR_REGISTRY}/${MS1_REPO}:${COMMIT_SHA}" \
  --type String --overwrite

aws ssm put-parameter --name "/microdemo/images/sqs-worker" \
  --value "${ECR_REGISTRY}/${MS2_REPO}:${COMMIT_SHA}" \
  --type String --overwrite
```

### ECS Service Updates

After Terraform apply, the CI/CD pipeline forces ECS service updates:

```bash
# Force new deployments
aws ecs update-service --cluster microdemo-ecs-cluster \
  --service microdemo-service --force-new-deployment

aws ecs update-service --cluster microdemo-ecs-cluster \
  --service microdemo-worker-service --force-new-deployment
```


