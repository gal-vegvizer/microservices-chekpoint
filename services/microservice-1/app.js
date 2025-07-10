const express = require('express');
const AWS = require('aws-sdk');
const bodyParser = require('body-parser');

const app = express();
app.use(bodyParser.json());

// Use real AWS credentials via ECS IAM role
AWS.config.update({
  region: process.env.AWS_REGION || 'us-east-2',
});

const sqs = new AWS.SQS();
const queueUrl = process.env.SQS_QUEUE_URL;

app.post('/submit', async (req, res) => {
  const { token, data } = req.body;

  // Validate token
  if (token !== process.env.TOKEN_SECRET) {
    return res.status(403).send('Invalid token');
  }

  // Validate required data fields
  if (!data || !data.email_sender || !data.email_subject || !data.email_timestream) {
    return res.status(400).send('Missing required fields: email_sender, email_subject, email_timestream');
  }

  // Validate email format
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(data.email_sender)) {
    return res.status(400).send('Invalid email format');
  }

  // Validate email_timestream format (ISO 8601)
  const timestreamRegex = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{3})?Z?$/;
  if (!timestreamRegex.test(data.email_timestream)) {
    return res.status(400).send('Invalid timestream format. Expected ISO 8601 format (YYYY-MM-DDTHH:mm:ssZ)');
  }

  try {
    await sqs.sendMessage({
      QueueUrl: queueUrl,
      MessageBody: JSON.stringify(data),
    }).promise();
    res.send('Message sent to SQS');
  } catch (error) {
    console.error('Error sending to SQS:', error);
    res.status(500).send('Error');
  }
});

// Health check endpoint for ALB
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'HEALTHY_V3',
    service: 'api-receiver',
    version: 'v3.0.0',
    timestamp: new Date().toISOString(),
    deployment_id: 'cicd-test-2025-07-10',
    message: 'CI/CD Pipeline Test - New Image Deployed Successfully!'
  });
});

app.listen(8080, '0.0.0.0', () => console.log('Microservice 1 listening on port 8080'));
