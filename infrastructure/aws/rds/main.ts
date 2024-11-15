// AWS CDK v2.0.0
import { Stack, StackProps } from 'aws-cdk-lib';
import * as aws_rds from 'aws-cdk-lib/aws-rds';
import * as aws_ec2 from 'aws-cdk-lib/aws-ec2';
import * as aws_secretsmanager from 'aws-cdk-lib/aws-secretsmanager';
import { VPCStack } from '../vpc/main';

/**
 * Human Tasks:
 * 1. Verify AWS account limits for RDS instances and storage
 * 2. Ensure proper IAM permissions for RDS and Secrets Manager
 * 3. Configure database parameter groups if custom parameters are needed
 * 4. Set up monitoring alerts for database metrics
 * 5. Review backup retention requirements and maintenance windows
 */

// Database Configuration Constants
const DB_PORT = 5432;
const DB_NAME = 'mint_replica';
const DEFAULT_TAGS = {
  Project: 'mint-replica-lite',
  Environment: 'production',
  ManagedBy: 'cdk'
};
const DB_INSTANCE_TYPE = 'r6g.large';
const DB_ENGINE_VERSION = '14.7';

/**
 * RDS Infrastructure Stack
 * @implements REQ-5.1: Data Layer Infrastructure - Primary database deployment
 * @implements REQ-5.3.4: Cloud Infrastructure - AWS RDS implementation
 * @implements REQ-5.2: High Availability - Multi-AZ database configuration
 */
export class RDSStack extends Stack {
  public readonly database: aws_rds.IDatabaseInstance;
  public readonly dbSecurityGroup: aws_ec2.ISecurityGroup;
  public readonly dbCredentials: aws_secretsmanager.ISecret;

  constructor(app: any, id: string, props: StackProps, vpcStack: VPCStack) {
    super(app, id, props);

    // Create security group for database access
    this.dbSecurityGroup = this.createSecurityGroup();

    // Create database credentials in Secrets Manager
    this.dbCredentials = this.createCredentialsSecret();

    // Create the RDS instance
    this.database = this.createDatabase();

    // Apply default tags to all resources in the stack
    Object.entries(DEFAULT_TAGS).forEach(([key, value]) => {
      aws_ec2.Tags.of(this).add(key, value);
    });
  }

  /**
   * Creates and configures the RDS PostgreSQL database instance
   * @implements REQ-5.2: High Availability - Multi-AZ deployment
   */
  private createDatabase(): aws_rds.IDatabaseInstance {
    // Create DB subnet group using isolated subnets
    const dbSubnetGroup = new aws_rds.SubnetGroup(this, 'DBSubnetGroup', {
      vpc: this.vpcStack.vpc,
      description: 'Isolated subnets for RDS instance',
      vpcSubnets: { subnets: this.vpcStack.isolatedSubnets }
    });

    // Create the RDS instance
    const instance = new aws_rds.DatabaseInstance(this, 'Database', {
      engine: aws_rds.DatabaseInstanceEngine.postgres({
        version: aws_rds.PostgresEngineVersion.VER_14_7
      }),
      instanceType: aws_ec2.InstanceType.of(
        aws_ec2.InstanceClass.R6G,
        aws_ec2.InstanceSize.LARGE
      ),
      vpc: this.vpcStack.vpc,
      vpcSubnets: { subnets: this.vpcStack.isolatedSubnets },
      subnetGroup: dbSubnetGroup,
      securityGroups: [this.dbSecurityGroup],
      credentials: aws_rds.Credentials.fromSecret(this.dbCredentials),
      databaseName: DB_NAME,
      port: DB_PORT,
      multiAz: true, // Enable high availability
      storageType: aws_rds.StorageType.GP3,
      allocatedStorage: 100,
      iops: 3000,
      maxAllocatedStorage: 1000, // Enable autoscaling up to 1TB
      monitoringInterval: 60, // Enhanced monitoring every 60 seconds
      enablePerformanceInsights: true,
      performanceInsightRetention: aws_rds.PerformanceInsightRetention.LONG_TERM,
      backupRetention: Duration.days(14),
      preferredBackupWindow: '00:00-02:00', // UTC
      preferredMaintenanceWindow: 'Sun:02:00-Sun:04:00', // UTC
      deletionProtection: true,
      removalPolicy: RemovalPolicy.RETAIN,
      autoMinorVersionUpgrade: true
    });

    return instance;
  }

  /**
   * Creates and configures the database security group
   * @implements REQ-5.2: Security through network isolation
   */
  private createSecurityGroup(): aws_ec2.ISecurityGroup {
    const securityGroup = new aws_ec2.SecurityGroup(this, 'DatabaseSecurityGroup', {
      vpc: this.vpcStack.vpc,
      description: 'Security group for RDS instance',
      allowAllOutbound: true
    });

    // Allow inbound PostgreSQL traffic from application tier
    securityGroup.addIngressRule(
      aws_ec2.Peer.ipv4(this.vpcStack.vpc.vpcCidrBlock),
      aws_ec2.Port.tcp(DB_PORT),
      'Allow PostgreSQL access from within VPC'
    );

    // Apply specific tags for the security group
    aws_ec2.Tags.of(securityGroup).add('Name', 'rds-security-group');
    aws_ec2.Tags.of(securityGroup).add('Component', 'Database');

    return securityGroup;
  }

  /**
   * Creates a Secrets Manager secret for database credentials
   * @implements REQ-5.2: Secure credential management
   */
  private createCredentialsSecret(): aws_secretsmanager.ISecret {
    const secret = new aws_secretsmanager.Secret(this, 'DatabaseCredentials', {
      description: 'RDS database credentials',
      generateSecretString: {
        secretStringTemplate: JSON.stringify({ username: 'dbadmin' }),
        generateStringKey: 'password',
        excludePunctuation: true,
        passwordLength: 32,
        excludeCharacters: '"@/\\\'',
      }
    });

    // Configure automatic rotation
    secret.addRotationSchedule('RotationSchedule', {
      automaticallyAfter: Duration.days(30),
      rotationLambdaOptions: {
        runtime: aws_lambda.Runtime.NODEJS_18_X,
        timeout: Duration.seconds(30),
        vpc: this.vpcStack.vpc,
        vpcSubnets: { subnets: this.vpcStack.privateSubnets }
      }
    });

    // Apply specific tags for the secret
    aws_ec2.Tags.of(secret).add('Name', 'rds-credentials');
    aws_ec2.Tags.of(secret).add('Component', 'Database');

    return secret;
  }
}