const AWS = require('aws-sdk');

// Set dummy credentials for LocalStack
AWS.config.update({
  accessKeyId: 'test',
  secretAccessKey: 'test',
  region: 'us-east-2',
  s3ForcePathStyle: true,
});


const sqs = new AWS.SQS({ endpoint: 'http://localstack:4566' });
const s3 = new AWS.S3({ endpoint: 'http://localstack:4566', s3ForcePathStyle: true });

const queueUrl = 'http://localstack:4566/000000000000/microdemo-queue';

const bucketName = 'demo-bucket';

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

      console.log(`Processed and stored message to S3 as ${s3Key}`);
    }
  } catch (error) {
    console.error('Error processing message:', error);
  }
}

setInterval(pollSQS, 5000);
