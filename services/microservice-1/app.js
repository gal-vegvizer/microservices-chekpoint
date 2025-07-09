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

  if (token !== process.env.TOKEN_SECRET) {
    return res.status(403).send('Invalid token');
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

app.listen(3000, () => console.log('Microservice 1 listening on port 3000'));
