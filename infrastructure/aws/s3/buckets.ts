// AWS CDK v2.0.0
import { Stack, StackProps } from 'aws-cdk-lib';
import * as aws_s3 from 'aws-cdk-lib/aws-s3';
import * as aws_iam from 'aws-cdk-lib/aws-iam';
import * as aws_kms from 'aws-cdk-lib/aws-kms';
import * as aws_ec2 from 'aws-cdk-lib/aws-ec2';
import { VPCStack } from '../vpc/main';

/**
 * Human Tasks:
 * 1. Verify AWS account limits for S3 bucket creation and KMS key quotas
 * 2. Ensure proper IAM permissions for CDK deployment
 * 3. Review and approve bucket naming convention with security team
 * 4. Configure AWS CloudTrail for bucket access logging
 * 5. Set up monitoring and alerting for bucket access patterns
 */

// Global constants for bucket configuration
const DEFAULT_TAGS = {
  Project: 'mint-replica-lite',
  Environment: 'production',
  ManagedBy: 'cdk'
};

const BUCKET_NAMES = {
  EXPORTS: 'mint-replica-exports',
  ASSETS: 'mint-replica-assets',
  BACKUPS: 'mint-replica-backups'
};

/**
 * AWS CDK Stack for S3 bucket infrastructure
 * @implements REQ-Object Storage: Secure S3 storage with encryption and access controls
 * @implements REQ-Data Export: Secure storage for data exports with encryption
 * @implements REQ-Infrastructure: AWS infrastructure deployment with security best practices
 */
export class S3BucketStack extends Stack {
  public readonly exportsBucket: aws_s3.IBucket;
  public readonly assetsBucket: aws_s3.IBucket;
  public readonly backupsBucket: aws_s3.IBucket;
  public readonly bucketKey: aws_kms.IKey;
  private readonly s3Endpoint: aws_ec2.IVpcEndpoint;

  constructor(app: cdk.App, id: string, props?: cdk.StackProps) {
    super(app, id, props);

    // Create KMS key for bucket encryption
    this.bucketKey = new aws_kms.Key(this, 'BucketEncryptionKey', {
      enableKeyRotation: true,
      description: 'KMS key for S3 bucket encryption',
      alias: 'mint-replica/s3-encryption',
      removalPolicy: cdk.RemovalPolicy.RETAIN
    });

    // Create S3 buckets with security configurations
    this.exportsBucket = this.createBucket(BUCKET_NAMES.EXPORTS, {
      versioned: true,
      encryption: aws_s3.BucketEncryption.KMS,
      encryptionKey: this.bucketKey,
      blockPublicAccess: aws_s3.BlockPublicAccess.BLOCK_ALL,
      removalPolicy: cdk.RemovalPolicy.RETAIN
    });

    this.assetsBucket = this.createBucket(BUCKET_NAMES.ASSETS, {
      versioned: true,
      encryption: aws_s3.BucketEncryption.KMS,
      encryptionKey: this.bucketKey,
      blockPublicAccess: aws_s3.BlockPublicAccess.BLOCK_ALL,
      removalPolicy: cdk.RemovalPolicy.RETAIN
    });

    this.backupsBucket = this.createBucket(BUCKET_NAMES.BACKUPS, {
      versioned: true,
      encryption: aws_s3.BucketEncryption.KMS,
      encryptionKey: this.bucketKey,
      blockPublicAccess: aws_s3.BlockPublicAccess.BLOCK_ALL,
      removalPolicy: cdk.RemovalPolicy.RETAIN
    });

    // Configure bucket policies
    this.configureBucketPolicy(this.exportsBucket, 'exports');
    this.configureBucketPolicy(this.assetsBucket, 'assets');
    this.configureBucketPolicy(this.backupsBucket, 'backups');

    // Set up VPC endpoint for private S3 access
    const vpc = VPCStack.vpc;
    this.s3Endpoint = new aws_ec2.VpcEndpoint(this, 'S3VpcEndpoint', {
      vpc,
      service: aws_ec2.GatewayVpcEndpointAwsService.S3,
      subnets: [{ subnetType: aws_ec2.SubnetType.PRIVATE_WITH_NAT }]
    });

    // Apply resource tags
    Object.entries(DEFAULT_TAGS).forEach(([key, value]) => {
      cdk.Tags.of(this).add(key, value);
    });
  }

  /**
   * Creates an S3 bucket with standard security configurations
   * @implements REQ-Object Storage: Secure bucket creation with encryption
   */
  private createBucket(bucketName: string, props: aws_s3.BucketProps): aws_s3.IBucket {
    const bucket = new aws_s3.Bucket(this, bucketName, {
      ...props,
      bucketName: bucketName,
      lifecycleRules: [
        {
          // Transition objects to Infrequent Access after 90 days
          transitions: [
            {
              storageClass: aws_s3.StorageClass.INFREQUENT_ACCESS,
              transitionAfter: cdk.Duration.days(90)
            }
          ],
          // Move to Glacier after 180 days
          transitions: [
            {
              storageClass: aws_s3.StorageClass.GLACIER,
              transitionAfter: cdk.Duration.days(180)
            }
          ],
          // Delete objects after 7 years
          expiration: cdk.Duration.days(2555)
        }
      ],
      serverAccessLogsPrefix: 'access-logs/',
      cors: [
        {
          allowedMethods: [
            aws_s3.HttpMethods.GET,
            aws_s3.HttpMethods.PUT
          ],
          allowedOrigins: ['*'],
          allowedHeaders: ['*'],
          maxAge: 3000
        }
      ]
    });

    return bucket;
  }

  /**
   * Configures IAM policies for secure bucket access
   * @implements REQ-Object Storage: Secure access patterns
   */
  private configureBucketPolicy(bucket: aws_s3.IBucket, bucketType: string): void {
    const policy = new aws_iam.PolicyStatement({
      effect: aws_iam.Effect.ALLOW,
      principals: [new aws_iam.ServicePrincipal('s3.amazonaws.com')],
      actions: ['s3:*'],
      resources: [bucket.bucketArn, `${bucket.bucketArn}/*`],
      conditions: {
        Bool: {
          'aws:SecureTransport': 'true'
        },
        StringEquals: {
          'aws:SourceVpc': this.s3Endpoint.vpcId
        }
      }
    });

    // Add bucket-specific permissions
    switch (bucketType) {
      case 'exports':
        policy.addActions(
          's3:GetObject',
          's3:PutObject',
          's3:DeleteObject'
        );
        break;
      case 'assets':
        policy.addActions(
          's3:GetObject',
          's3:PutObject'
        );
        break;
      case 'backups':
        policy.addActions(
          's3:GetObject',
          's3:PutObject',
          's3:ListBucket'
        );
        break;
    }

    bucket.addToResourcePolicy(policy);
  }
}