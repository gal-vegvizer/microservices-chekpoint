const AWS = require('aws-sdk');

// Use real AWS config
AWS.config.update({
  region: process.env.AWS_REGION || 'us-east-2',
});

const sqs = new AWS.SQS();
const s3 = new AWS.S3();

const queueUrl = process.env.SQS_QUEUE_URL;
const bucketName = process.env.S3_BUCKET_NAME;

async function pollSQS() {
  try {
    const result = await sqs.receiveMessage({
      QueueUrl: queueUrl,
      MaxNumberOfMessages: 1,
      WaitTimeSeconds: 5
    }).promise();

    if (result.Messages && result.Messages.length > 0) {
      const message = result.Messages[0];
      const body = JSON.parse(message.Body);

      const s3Key = `data/${Date.now()}.json`;

      await s3.putObject({
        Bucket: bucketName,
        Key: s3Key,
        Body: JSON.stringify(body),
      }).promise();

      await sqs.deleteMessage({
        QueueUrl: queueUrl,
        ReceiptHandle: message.ReceiptHandle
      }).promise();

      console.log(`Processed and stored message to S3 as test ${s3Key}`);
    }
  } catch (error) {
    console.error('Error processing message:', error);
  }
}

setInterval(pollSQS, 5000);
