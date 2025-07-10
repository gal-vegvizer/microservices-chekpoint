# Microservices

This directory contains the Node.js microservices that form the core of the application architecture. The services are designed to work together in a distributed, event-driven system on AWS.

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Internet      │    │   Application    │    │   Microservice 1│
│   Gateway       │────│   Load Balancer  │────│   (API Receiver)│
│                 │    │                  │    │   Port: 8080    │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                                         │
                                                ┌─────────────────┐
                                                │   Amazon SQS    │
                                                │     Queue       │
                                                └─────────────────┘
                                                         │
                                                ┌─────────────────┐
                                                │   Microservice 2│
                                                │   (SQS Worker)  │
                                                │   Background    │
                                                └─────────────────┘
                                                         │
                                                ┌─────────────────┐
                                                │   Amazon S3     │
                                                │   Data Storage  │
                                                └─────────────────┘
```

## 📁 Service Structure

### `microservice-1/` - API Receiver Service
**Purpose**: HTTP API endpoint that receives data submissions and forwards them to SQS

**Key Features**:
- RESTful API with token authentication
- Input validation and sanitization
- SQS message publishing
- Health check endpoint
- Comprehensive error handling

**Port**: 8080
**Type**: Web Service

### `microservice-2/` - SQS Worker Service
**Purpose**: Background worker that processes SQS messages and stores data in S3

**Key Features**:
- SQS message polling
- Data processing and transformation
- S3 object storage
- Automatic message cleanup
- Error handling and logging

**Port**: N/A (Background Service)
**Type**: Worker Service

## 🔧 Service Details

### Microservice 1 (API Receiver)

**Endpoints**:
- `POST /submit` - Submit data for processing
- `GET /health` - Health check endpoint

**Request Format**:
```json
{
  "token": "your-secure-token",
  "data": {
    "email_sender": "user@example.com",
    "email_subject": "Subject Line",
    "email_timestream": "2025-07-10T12:00:00Z"
  }
}
```

**Response Format**:
```json
{
  "success": true,
  "message": "Message sent to SQS"
}
```

**Validation Rules**:
- Token must match environment variable `TOKEN_SECRET`
- All data fields are required: `email_sender`, `email_subject`, `email_timestream`
- Email must be valid format (RFC 5322)
- Timestream must be ISO 8601 format (YYYY-MM-DDTHH:mm:ssZ)

**Error Responses**:
- `400`: Missing required fields or invalid format
- `403`: Invalid authentication token
- `500`: Internal server error

### Microservice 2 (SQS Worker)

**Functionality**:
- Polls SQS queue every 5 seconds
- Processes messages in JSON format
- Stores data to S3 with timestamp-based keys
- Automatically deletes processed messages
- Handles errors gracefully with logging

**S3 Storage Pattern**:
- Bucket: Configured via `S3_BUCKET_NAME` environment variable
- Key Pattern: `data/{timestamp}.json`
- Content: JSON representation of processed data

**Processing Flow**:
1. Receive message from SQS
2. Parse JSON message body
3. Generate unique S3 key
4. Store data to S3
5. Delete message from SQS
6. Log success/failure

## 🚀 Getting Started

### Prerequisites
- Node.js 18 or higher
- AWS credentials configured (for local development)
- Docker (for containerization)

### Local Development

#### Microservice 1
```bash
cd microservice-1
npm install
export TOKEN_SECRET="your-test-token"
export SQS_QUEUE_URL="your-queue-url"
export AWS_REGION="us-east-2"
node app.js
```

#### Microservice 2
```bash
cd microservice-2
npm install
export SQS_QUEUE_URL="your-queue-url"
export S3_BUCKET_NAME="your-bucket-name"
export AWS_REGION="us-east-2"
node app.js
```

### Testing Locally

#### Test API Receiver
```bash
# Health check
curl -f http://localhost:8080/health

# Submit data
curl -X POST http://localhost:8080/submit \
  -H "Content-Type: application/json" \
  -d '{
    "token": "your-test-token",
    "data": {
      "email_sender": "test@example.com",
      "email_subject": "Test Subject",
      "email_timestream": "2025-07-10T12:00:00Z"
    }
  }'
```

#### Monitor SQS Worker
```bash
# Check logs for processing activity
docker logs -f microservice-2-container

# Verify S3 storage
aws s3 ls s3://your-bucket-name/data/
```

## 🐳 Docker Configuration

### Microservice 1 Dockerfile
```dockerfile
FROM node:18
WORKDIR /app
COPY . .
RUN npm install
EXPOSE 8080
CMD ["node", "app.js"]
```

### Microservice 2 Dockerfile
```dockerfile
FROM node:18
WORKDIR /app
COPY . .
RUN npm install
CMD ["node", "app.js"]
```

### Build and Run
```bash
# Build images
docker build -t microservice-1 ./microservice-1
docker build -t microservice-2 ./microservice-2

# Run containers
docker run -d -p 8080:8080 \
  -e TOKEN_SECRET="your-token" \
  -e SQS_QUEUE_URL="your-queue-url" \
  -e AWS_REGION="us-east-2" \
  microservice-1

docker run -d \
  -e SQS_QUEUE_URL="your-queue-url" \
  -e S3_BUCKET_NAME="your-bucket" \
  -e AWS_REGION="us-east-2" \
  microservice-2
```

## 🔐 Environment Variables

### Common Variables
- `AWS_REGION`: AWS region (default: us-east-2)
- `SQS_QUEUE_URL`: Full SQS queue URL
- `TOKEN_SECRET`: Authentication token (microservice-1 only)
- `S3_BUCKET_NAME`: S3 bucket name (microservice-2 only)

### Security Notes
- Never hardcode credentials in the code
- Use AWS IAM roles in production
- Environment variables are injected by ECS
- Tokens are stored securely in SSM Parameter Store

## 📊 Dependencies

### Common Dependencies
```json
{
  "aws-sdk": "^2.1360.0",
  "express": "^4.18.2",
  "body-parser": "^1.20.2"
}
```

### AWS SDK Usage
- **SQS**: Message queue operations
- **S3**: Object storage operations
- **Automatic Credentials**: Uses ECS IAM role in production

## 🔄 Development Workflow

### Local Testing
1. **Setup Environment**: Configure AWS credentials and environment variables
2. **Install Dependencies**: Run `npm install` in each service directory
3. **Start Services**: Run services individually for testing
4. **Test Integration**: Use curl or Postman to test API endpoints

### Container Testing
1. **Build Images**: Create Docker images for both services
2. **Run Containers**: Start containers with proper environment variables
3. **Test Communication**: Verify SQS message flow between services
4. **Monitor Logs**: Check container logs for processing activity

### Production Deployment
1. **CI/CD Pipeline**: Automated build and deployment via GitHub Actions
2. **ECR Storage**: Images stored in Amazon Elastic Container Registry
3. **ECS Deployment**: Services deployed on Amazon ECS with auto-scaling
4. **Health Monitoring**: Automated health checks and monitoring

## 🧪 Testing Strategy

### Unit Tests
- Input validation functions
- Error handling logic
- AWS SDK integration
- Environment variable handling

### Integration Tests
- API endpoint functionality
- SQS message processing
- S3 storage operations
- End-to-end data flow

### Load Testing
- API performance under load
- SQS processing capacity
- Memory and CPU usage
- Auto-scaling behavior

## 📈 Performance Considerations

### Microservice 1 (API Receiver)
- **Concurrency**: Express.js handles multiple concurrent requests
- **Validation**: Input validation adds minimal overhead
- **SQS Publishing**: Asynchronous message publishing
- **Memory Usage**: Lightweight with minimal dependencies

### Microservice 2 (SQS Worker)
- **Polling Frequency**: 5-second intervals balance responsiveness and efficiency
- **Batch Processing**: Processes one message at a time for reliability
- **S3 Operations**: Efficient JSON storage with timestamp-based keys
- **Error Handling**: Graceful error handling prevents service crashes

## 🔧 Troubleshooting

### Common Issues

#### API Receiver Issues
```bash
# Check service logs
docker logs microservice-1-container

# Test connectivity
curl -f http://localhost:8080/health

# Verify environment variables
docker exec microservice-1-container printenv
```

#### SQS Worker Issues
```bash
# Check processing logs
docker logs -f microservice-2-container

# Verify SQS queue
aws sqs get-queue-attributes --queue-url YOUR_QUEUE_URL

# Check S3 bucket
aws s3 ls s3://your-bucket-name/data/
```

### Debug Commands
```bash
# Check AWS credentials
aws sts get-caller-identity

# List SQS messages
aws sqs receive-message --queue-url YOUR_QUEUE_URL

# Monitor S3 uploads
aws s3 ls s3://your-bucket-name/data/ --recursive
```