// AWS CDK v2.0.0
import { Stack, StackProps } from 'aws-cdk-lib';
import * as aws_sqs from 'aws-cdk-lib/aws-sqs';
import * as aws_kms from 'aws-cdk-lib/aws-kms';
import * as aws_ec2 from 'aws-cdk-lib/aws-ec2';
import { VPCStack } from '../vpc/main';

/**
 * Human Tasks:
 * 1. Verify AWS account limits for SQS queues and KMS keys
 * 2. Ensure proper IAM permissions for queue access
 * 3. Review message retention and DLQ policies
 * 4. Configure CloudWatch alarms for queue metrics
 */

// Queue Configuration Constants
const DEFAULT_TAGS = {
  Project: 'mint-replica-lite',
  Environment: 'production',
  ManagedBy: 'cdk'
};

const QUEUE_RETENTION_DAYS = 14;
const MAX_MESSAGE_SIZE_BYTES = 262144; // 256 KB
const VISIBILITY_TIMEOUT_SECONDS = 300; // 5 minutes
const MAX_RECEIVE_COUNT = 3;

/**
 * SQS Infrastructure Stack
 * @implements REQ-5.3.4: AWS infrastructure deployment with SQS components
 * @implements REQ-6.2.2: Asynchronous transaction processing
 * @implements REQ-6.2.1: Account synchronization messaging
 */
export class SQSStack extends Stack {
  public readonly transactionQueue: aws_sqs.Queue;
  public readonly transactionDLQ: aws_sqs.Queue;
  public readonly accountSyncQueue: aws_sqs.Queue;
  public readonly accountSyncDLQ: aws_sqs.Queue;
  public readonly notificationQueue: aws_sqs.Queue;
  public readonly notificationDLQ: aws_sqs.Queue;
  public readonly budgetAlertQueue: aws_sqs.Queue;
  public readonly budgetAlertDLQ: aws_sqs.Queue;
  private readonly queueEncryptionKey: aws_kms.Key;
  private readonly vpc: aws_ec2.IVpc;
  private readonly privateSubnets: aws_ec2.ISubnet[];

  constructor(app: cdk.App, id: string, props: cdk.StackProps, vpcStack: VPCStack) {
    super(app, id, props);

    // Import VPC configuration
    this.vpc = vpcStack.vpc;
    this.privateSubnets = vpcStack.privateSubnets;

    // Create KMS encryption key for queues
    this.queueEncryptionKey = new aws_kms.Key(this, 'QueueEncryptionKey', {
      enableKeyRotation: true,
      description: 'KMS key for SQS queue encryption',
      alias: 'mint-replica/sqs-encryption'
    });

    // Create dead letter queues
    this.transactionDLQ = this.createDeadLetterQueue('TransactionDLQ');
    this.accountSyncDLQ = this.createDeadLetterQueue('AccountSyncDLQ');
    this.notificationDLQ = this.createDeadLetterQueue('NotificationDLQ');
    this.budgetAlertDLQ = this.createDeadLetterQueue('BudgetAlertDLQ');

    // Create main queues with DLQ configuration
    this.transactionQueue = this.createQueue('TransactionQueue', {
      queueName: 'mint-replica-transaction-queue',
      fifo: false // Standard queue for higher throughput
    }, this.transactionDLQ);

    this.accountSyncQueue = this.createQueue('AccountSyncQueue', {
      queueName: 'mint-replica-account-sync-queue',
      fifo: true, // FIFO queue for ordered processing
      contentBasedDeduplication: true
    }, this.accountSyncDLQ);

    this.notificationQueue = this.createQueue('NotificationQueue', {
      queueName: 'mint-replica-notification-queue',
      fifo: false
    }, this.notificationDLQ);

    this.budgetAlertQueue = this.createQueue('BudgetAlertQueue', {
      queueName: 'mint-replica-budget-alert-queue',
      fifo: false
    }, this.budgetAlertDLQ);

    // Apply resource tags
    this.configureTags();
  }

  /**
   * Creates an SQS queue with standard configuration
   * @implements REQ-6.2.2: Reliable message processing
   */
  private createQueue(
    queueName: string,
    props: aws_sqs.QueueProps,
    deadLetterQueue: aws_sqs.Queue
  ): aws_sqs.Queue {
    return new aws_sqs.Queue(this, queueName, {
      ...props,
      retentionPeriod: cdk.Duration.days(QUEUE_RETENTION_DAYS),
      encryption: aws_sqs.QueueEncryption.KMS,
      encryptionMasterKey: this.queueEncryptionKey,
      visibilityTimeout: cdk.Duration.seconds(VISIBILITY_TIMEOUT_SECONDS),
      maxMessageSizeBytes: MAX_MESSAGE_SIZE_BYTES,
      deadLetterQueue: {
        queue: deadLetterQueue,
        maxReceiveCount: MAX_RECEIVE_COUNT
      },
      // VPC endpoint for private access
      vpcSubnets: {
        subnets: this.privateSubnets
      }
    });
  }

  /**
   * Creates a dead letter queue for failed message handling
   * @implements REQ-6.2.2: Error handling for failed messages
   */
  private createDeadLetterQueue(queueName: string): aws_sqs.Queue {
    return new aws_sqs.Queue(this, queueName, {
      queueName: `mint-replica-${queueName.toLowerCase()}`,
      retentionPeriod: cdk.Duration.days(QUEUE_RETENTION_DAYS * 2), // Double retention for DLQ
      encryption: aws_sqs.QueueEncryption.KMS,
      encryptionMasterKey: this.queueEncryptionKey,
      vpcSubnets: {
        subnets: this.privateSubnets
      }
    });
  }

  /**
   * Applies standard resource tags
   * @implements REQ-5.3.4: AWS resource management
   */
  private configureTags(): void {
    // Apply default tags to all resources
    Object.entries(DEFAULT_TAGS).forEach(([key, value]) => {
      cdk.Tags.of(this).add(key, value);
    });

    // Add specific tags for queues
    const queueList = [
      this.transactionQueue,
      this.transactionDLQ,
      this.accountSyncQueue,
      this.accountSyncDLQ,
      this.notificationQueue,
      this.notificationDLQ,
      this.budgetAlertQueue,
      this.budgetAlertDLQ
    ];

    queueList.forEach(queue => {
      cdk.Tags.of(queue).add('Component', 'Messaging');
      cdk.Tags.of(queue).add('Service', 'SQS');
    });
  }
}