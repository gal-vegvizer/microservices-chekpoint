const express = require('express');
const AWS = require('aws-sdk');
const bodyParser = require('body-parser');

// Set dummy credentials for LocalStack
AWS.config.update({
  accessKeyId: 'test',
  secretAccessKey: 'test',
  region: 'us-east-2',
  s3ForcePathStyle: true,
});


const app = express();
app.use(bodyParser.json());

const sqs = new AWS.SQS({ endpoint: 'http://localstack:4566' });
const queueUrl = 'http://localstack:4566/000000000000/microdemo-queue';


app.post('/submit', async (req, res) => {
  const { token, data } = req.body;

  // Basic token validation
  if (token !== 'SECRET_TOKEN') {
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
