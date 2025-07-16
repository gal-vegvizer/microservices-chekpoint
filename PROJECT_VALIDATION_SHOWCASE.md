# Microservices Project - Validation & Showcase Commands


## 1. Token Management Validation

### Retrieve API Token from SSM Parameter Store
```powershell
powershell -Command "aws ssm get-parameter --name '/microservices-demo/api-token' --with-decryption --region us-east-2 --query 'Parameter.Value' --output text"
```

### Verify Token from Terraform
```bash
terraform output -raw api_token_value
```
---

## 2. ECS Services Validation

### Check ECS Services Status
```bash
aws ecs describe-services --cluster microdemo-ecs-cluster --services microdemo-service microdemo-worker-service --query 'services[*].{Name:serviceName,Status:status,RunningCount:runningCount,DesiredCount:desiredCount}'
```
**Expected Output:**
```json
[
    {
        "Name": "microdemo-service",
        "Status": "ACTIVE",
        "RunningCount": 1,
        "DesiredCount": 1
    },
    {
        "Name": "microdemo-worker-service",
        "Status": "ACTIVE",
        "RunningCount": 1,
        "DesiredCount": 1
    }
]
```

---

## 3. Application Load Balancer Validation

### Health Check Endpoint
```bash
curl -s "http://microdemo-alb-394538633.us-east-2.elb.amazonaws.com/health"
```
**Expected Output:**
```json
{
  "status": "HEALTHY_V3",
  "service": "api-receiver",
  "version": "v3.0.0",
  "timestamp": "2025-07-15T15:47:40.177Z",
  "deployment_id": "cicd-test-2025-07-10",
  "message": "CI/CD Pipeline Test - New Image Deployed Successfully!"
}
```

---

## 4. SQS Queue Validation

### Check SQS Queue Status
```bash
aws sqs get-queue-attributes --queue-url "https://sqs.us-east-2.amazonaws.com/139176429165/microdemo-queue" --attribute-names QueueArn ApproximateNumberOfMessages
```
**Expected Output:**
```json
{
    "Attributes": {
        "QueueArn": "arn:aws:sqs:us-east-2:139176429165:microdemo-queue",
        "ApproximateNumberOfMessages": "0"
    }
}
```

---

## 5. ECR Repository Validation

### List ECR Repositories
```bash
aws ecr describe-repositories --repository-names microdemo/microservice-1 microdemo/microservice-2 --query 'repositories[*].{Name:repositoryName,URI:repositoryUri,Images:imageTagMutability}'
```
**Expected Output:**
```json
[
    {
        "Name": "microdemo/microservice-1",
        "URI": "139176429165.dkr.ecr.us-east-2.amazonaws.com/microdemo/microservice-1",
        "Images": "MUTABLE"
    },
    {
        "Name": "microdemo/microservice-2",
        "URI": "139176429165.dkr.ecr.us-east-2.amazonaws.com/microdemo/microservice-2",
        "Images": "MUTABLE"
    }
]
```


## 6. API Functional Testing

### Test Valid API Request
```bash
curl -X POST "http://microdemo-alb-394538633.us-east-2.elb.amazonaws.com/submit" \
  -H "Content-Type: application/json" \
  -d '{
    "token": "46mB$Ah{)pf^y.V3!Fu9)Y,8yZPGdeF#",
    "data": {
      "email_sender": "test@example.com",
      "email_subject": "Test Subject",
      "email_timestream": "2025-07-15T15:30:00Z"
    }
  }'
```
**Expected Output:**
```
Message sent to SQS
```

### Test Invalid Token (Security Validation)
```bash
curl -X POST "http://microdemo-alb-394538633.us-east-2.elb.amazonaws.com/submit" \
  -H "Content-Type: application/json" \
  -d '{
    "token": "invalid-token",
    "data": {
      "email_sender": "test@example.com",
      "email_subject": "Test Subject",
      "email_timestream": "2025-07-15T15:30:00Z"
    }
  }'
```
**Expected Output:**
```
Invalid token
```

---

## 7. Data Processing Validation

### Check S3 Data Storage
```bash
aws s3 ls s3://microdemo-data-bucket/data/ --recursive | tail -5
```
**Expected Output:**
```
2025-07-15 18:50:04        108 data/1752594603176.json
```

### View Processed Data Content
```bash
aws s3 cp s3://microdemo-data-bucket/data/1752594603176.json -
```
**Expected Output:**
```json
{"email_sender":"test@example.com","email_subject":"Test Subject","email_timestream":"2025-07-15T15:30:00Z"}
```
