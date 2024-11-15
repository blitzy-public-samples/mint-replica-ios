// AWS CDK v2.0.0
import { Stack, StackProps } from 'aws-cdk-lib';
import * as elasticache from 'aws-cdk-lib/aws-elasticache';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as aws_tags from 'aws-cdk-lib/aws-tags';
import { VPCStack } from '../vpc/main';

/**
 * Human Tasks:
 * 1. Verify AWS account limits for ElastiCache nodes and shards
 * 2. Ensure proper IAM permissions for ElastiCache management
 * 3. Review security group ingress rules based on application requirements
 * 4. Configure parameter group settings if custom Redis configuration is needed
 * 5. Plan maintenance window during low-traffic periods
 */

// ElastiCache Configuration Constants
const REDIS_PORT = 6379;
const REDIS_NODE_TYPE = 'cache.t3.medium';
const REDIS_NUM_SHARDS = 2;
const REDIS_REPLICAS_PER_SHARD = 1;
const DEFAULT_TAGS = {
  Project: 'mint-replica-lite',
  Environment: 'production',
  ManagedBy: 'cdk',
  Component: 'cache'
};

/**
 * ElastiCache Redis Infrastructure Stack
 * @implements REQ-5.1: Redis Cache in data layer for application caching
 * @implements REQ-5.3.4: AWS infrastructure deployment
 */
export class ElastiCacheStack extends Stack {
  public readonly redisCluster: elasticache.CfnReplicationGroup;
  public readonly redisSecurityGroup: ec2.SecurityGroup;
  private readonly vpc: ec2.IVpc;
  private readonly privateSubnets: ec2.ISubnet[];

  constructor(app: any, id: string, props?: StackProps) {
    super(app, id, props);

    // Import VPC and private subnets from VPC stack
    const vpcStack = props?.env?.account && props?.env?.region 
      ? new VPCStack(app, 'VPCStack', { env: { account: props.env.account, region: props.env.region }})
      : new VPCStack(app, 'VPCStack', {});
    
    this.vpc = vpcStack.vpc;
    this.privateSubnets = vpcStack.privateSubnets;

    // Create security group for Redis cluster
    this.redisSecurityGroup = this.createSecurityGroup();

    // Create subnet group for Redis cluster
    const subnetGroup = new elasticache.CfnSubnetGroup(this, 'RedisSubnetGroup', {
      description: 'Subnet group for Redis cluster',
      subnetIds: this.privateSubnets.map(subnet => subnet.subnetId),
      cacheSubnetGroupName: `${id}-subnet-group`
    });

    // Create Redis cluster
    this.redisCluster = this.createRedisCluster(subnetGroup);

    // Apply tags to all resources
    Object.entries(DEFAULT_TAGS).forEach(([key, value]) => {
      aws_tags.Tags.of(this).add(key, value);
    });
  }

  /**
   * Creates and configures security group for Redis cluster
   * @implements REQ-5.1: Secure access to Redis cache
   */
  private createSecurityGroup(): ec2.SecurityGroup {
    const sg = new ec2.SecurityGroup(this, 'RedisSecurityGroup', {
      vpc: this.vpc,
      description: 'Security group for Redis cluster',
      allowAllOutbound: true
    });

    // Allow inbound Redis traffic from within VPC
    sg.addIngressRule(
      ec2.Peer.ipv4(this.vpc.vpcCidrBlock),
      ec2.Port.tcp(REDIS_PORT),
      'Allow Redis traffic from within VPC'
    );

    // Apply security group tags
    Object.entries(DEFAULT_TAGS).forEach(([key, value]) => {
      aws_tags.Tags.of(sg).add(key, value);
    });

    return sg;
  }

  /**
   * Creates the Redis replication group with sharding and high availability
   * @implements REQ-5.1: High availability and fault tolerance for Redis cache
   */
  private createRedisCluster(subnetGroup: elasticache.CfnSubnetGroup): elasticache.CfnReplicationGroup {
    const cluster = new elasticache.CfnReplicationGroup(this, 'RedisCluster', {
      replicationGroupDescription: 'Redis cluster for Mint Replica Lite',
      engine: 'redis',
      engineVersion: '6.x',
      cacheNodeType: REDIS_NODE_TYPE,
      port: REDIS_PORT,
      
      // Sharding configuration
      numNodeGroups: REDIS_NUM_SHARDS,
      replicasPerNodeGroup: REDIS_REPLICAS_PER_SHARD,
      
      // Network configuration
      securityGroupIds: [this.redisSecurityGroup.securityGroupId],
      cacheSubnetGroupName: subnetGroup.ref,
      
      // Availability and reliability
      multiAzEnabled: true,
      automaticFailoverEnabled: true,
      
      // Security configuration
      atRestEncryptionEnabled: true,
      transitEncryptionEnabled: true,
      
      // Backup and maintenance
      snapshotRetentionLimit: 7,
      snapshotWindow: '02:00-03:00',
      preferredMaintenanceWindow: 'sun:03:00-sun:04:00',
      
      // Performance and monitoring
      autoMinorVersionUpgrade: true,
      
      // Tags
      tags: Object.entries(DEFAULT_TAGS).map(([key, value]) => ({
        key,
        value
      }))
    });

    return cluster;
  }
}