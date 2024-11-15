// AWS CDK v2.0.0
import { Stack, StackProps } from 'aws-cdk-lib';
import * as aws_ec2 from 'aws-cdk-lib/aws-ec2';
import * as aws_tags from 'aws-cdk-lib/aws-ec2';
import { SubnetConfiguration, calculateSubnetCidr, getAvailabilityZones } from './subnets';

/**
 * Human Tasks:
 * 1. Verify AWS account limits for VPC resources (NAT Gateways, IGW, etc.)
 * 2. Ensure proper IAM permissions for CDK deployment
 * 3. Review network ACL and security group requirements
 * 4. Confirm VPC CIDR range doesn't conflict with other networks
 */

// VPC Configuration Constants
const VPC_CIDR = '10.0.0.0/16';
const MAX_AZS = 3;
const DEFAULT_TAGS = {
  Project: 'mint-replica-lite',
  Environment: 'production',
  ManagedBy: 'cdk'
};

/**
 * VPC Infrastructure Stack
 * @implements REQ-5.3.4: AWS infrastructure deployment with VPC components
 * @implements REQ-5.1: Multi-tier architecture network segmentation
 * @implements REQ-5.2: Secure network isolation
 */
export class VPCStack extends Stack {
  public readonly vpc: aws_ec2.IVpc;
  public readonly publicSubnets: aws_ec2.ISubnet[];
  public readonly privateSubnets: aws_ec2.ISubnet[];
  public readonly isolatedSubnets: aws_ec2.ISubnet[];

  constructor(app: cdk.App, id: string, props?: cdk.StackProps) {
    super(app, id, props);

    // Create VPC and networking components
    this.vpc = this.createVpc();
    
    // Store subnet references
    this.publicSubnets = this.vpc.publicSubnets;
    this.privateSubnets = this.vpc.privateSubnets;
    this.isolatedSubnets = this.vpc.isolatedSubnets;

    // Apply resource tags
    this.configureTags();
  }

  /**
   * Creates and configures the VPC with multi-tier subnet architecture
   * @implements REQ-5.1: Network segmentation for different application tiers
   * @implements REQ-5.2: Security through network isolation
   */
  private createVpc(): aws_ec2.IVpc {
    // Define subnet configurations for each tier
    const subnetConfigurations: SubnetConfiguration[] = [
      {
        name: 'Public',
        cidrRange: calculateSubnetCidr(VPC_CIDR, 'PUBLIC', 0),
        subnetType: aws_ec2.SubnetType.PUBLIC
      },
      {
        name: 'Private',
        cidrRange: calculateSubnetCidr(VPC_CIDR, 'PRIVATE', 0),
        subnetType: aws_ec2.SubnetType.PRIVATE_WITH_NAT
      },
      {
        name: 'Isolated',
        cidrRange: calculateSubnetCidr(VPC_CIDR, 'ISOLATED', 0),
        subnetType: aws_ec2.SubnetType.PRIVATE_ISOLATED
      }
    ];

    // Create VPC with specified configuration
    const vpc = new aws_ec2.Vpc(this, 'MintReplicaVPC', {
      ipAddresses: aws_ec2.IpAddresses.cidr(VPC_CIDR),
      maxAzs: MAX_AZS,
      natGateways: 1, // One NAT Gateway per AZ for cost optimization
      subnetConfiguration: subnetConfigurations.map(config => ({
        name: config.name,
        subnetType: config.subnetType,
        cidrMask: parseInt(config.cidrRange.split('/')[1])
      })),
      // Enable DNS hostnames and support
      enableDnsHostnames: true,
      enableDnsSupport: true,
      // Create flow logs for network monitoring
      flowLogs: {
        's3': {
          destination: aws_ec2.FlowLogDestination.toS3(),
          trafficType: aws_ec2.FlowLogTrafficType.ALL
        }
      }
    });

    // Configure network ACLs for additional security
    this.configureNetworkAcls(vpc);

    return vpc;
  }

  /**
   * Configures Network ACLs for each subnet tier
   * @implements REQ-5.2: Security through network isolation
   */
  private configureNetworkAcls(vpc: aws_ec2.IVpc): void {
    // Public subnet ACLs - Allow inbound HTTP/HTTPS
    const publicAcl = new aws_ec2.NetworkAcl(this, 'PublicNetworkAcl', {
      vpc: vpc,
      subnetSelection: { subnetType: aws_ec2.SubnetType.PUBLIC }
    });

    publicAcl.addEntry('AllowHTTP', {
      cidr: aws_ec2.AclCidr.anyIpv4(),
      ruleNumber: 100,
      traffic: aws_ec2.AclTraffic.tcpPort(80),
      direction: aws_ec2.TrafficDirection.INGRESS
    });

    publicAcl.addEntry('AllowHTTPS', {
      cidr: aws_ec2.AclCidr.anyIpv4(),
      ruleNumber: 110,
      traffic: aws_ec2.AclTraffic.tcpPort(443),
      direction: aws_ec2.TrafficDirection.INGRESS
    });

    // Private subnet ACLs - Allow inbound from public subnet
    const privateAcl = new aws_ec2.NetworkAcl(this, 'PrivateNetworkAcl', {
      vpc: vpc,
      subnetSelection: { subnetType: aws_ec2.SubnetType.PRIVATE_WITH_NAT }
    });

    privateAcl.addEntry('AllowFromPublic', {
      cidr: aws_ec2.AclCidr.ipv4(VPC_CIDR),
      ruleNumber: 100,
      traffic: aws_ec2.AclTraffic.allTraffic(),
      direction: aws_ec2.TrafficDirection.INGRESS
    });

    // Isolated subnet ACLs - Strict access control
    const isolatedAcl = new aws_ec2.NetworkAcl(this, 'IsolatedNetworkAcl', {
      vpc: vpc,
      subnetSelection: { subnetType: aws_ec2.SubnetType.PRIVATE_ISOLATED }
    });

    isolatedAcl.addEntry('AllowFromPrivate', {
      cidr: aws_ec2.AclCidr.ipv4(calculateSubnetCidr(VPC_CIDR, 'PRIVATE', 0)),
      ruleNumber: 100,
      traffic: aws_ec2.AclTraffic.allTraffic(),
      direction: aws_ec2.TrafficDirection.INGRESS
    });
  }

  /**
   * Applies standard resource tags
   * @implements REQ-5.3.4: AWS infrastructure management
   */
  private configureTags(): void {
    // Apply tags to all resources in the stack
    Object.entries(DEFAULT_TAGS).forEach(([key, value]) => {
      aws_tags.Tags.of(this).add(key, value);
    });

    // Add specific tags for networking components
    aws_tags.Tags.of(this.vpc).add('Component', 'Networking');
    aws_tags.Tags.of(this.vpc).add('Name', 'MintReplicaVPC');
  }
}