// AWS CDK v2.0.0
// @aws-cdk/aws-eks v2.0.0
// @aws-cdk/aws-iam v2.0.0
// @aws-cdk/aws-autoscaling v2.0.0

/**
 * Human Tasks:
 * 1. Verify AWS service quotas for EKS node groups and EC2 instances
 * 2. Review IAM permissions for node group role creation
 * 3. Ensure AWS CLI and kubectl are configured for cluster access
 * 4. Validate instance types are available in target regions
 */

import { Construct } from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as eks from 'aws-cdk-lib/aws-eks';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as autoscaling from 'aws-cdk-lib/aws-autoscaling';
import { VpcStack } from '../vpc/main';

/**
 * Configuration interface for service-specific node groups
 * @implements REQ-5.3.4: Container Orchestration - EKS node group configuration
 */
interface ServiceNodeGroupConfig {
  minSize: number;
  maxSize: number;
  desiredSize: number;
  instanceTypes: ec2.InstanceType[];
  labels: Record<string, string>;
  taints: eks.Taint[];
}

/**
 * Manages EKS node group configurations and lifecycle
 * @implements REQ-5.1: High-Level Architecture - Worker node infrastructure
 * @implements REQ-5.3.4: Container Orchestration - EKS implementation
 */
export class NodeGroups {
  public readonly defaultNodeGroup: eks.NodeGroup;
  public readonly serviceNodeGroups: Map<string, eks.NodeGroup>;

  constructor(scope: Construct, cluster: eks.Cluster, vpc: VpcStack) {
    this.serviceNodeGroups = new Map<string, eks.NodeGroup>();

    // Create default node group
    this.defaultNodeGroup = this.createDefaultNodeGroup(scope, cluster, vpc);
  }

  /**
   * Creates the default node group for general workloads
   * @implements REQ-5.3.4: Container Orchestration - Default node configuration
   */
  private createDefaultNodeGroup(scope: Construct, cluster: eks.Cluster, vpc: VpcStack): eks.NodeGroup {
    const nodeRole = this.createNodeRole(scope, 'default');

    return new eks.NodeGroup(scope, 'DefaultNodeGroup', {
      cluster,
      nodeRole,
      subnets: { subnets: vpc.privateSubnets },
      instanceTypes: [ec2.InstanceType.of(ec2.InstanceClass.T3, ec2.InstanceSize.MEDIUM)],
      minSize: 2,
      maxSize: 5,
      desiredSize: 3,
      labels: {
        'role': 'default',
        'environment': 'production',
        'nodegroup': 'default'
      },
      // Configure capacity optimization
      capacityType: eks.CapacityType.ON_DEMAND,
      amiType: eks.NodegroupAmiType.AL2_X86_64,
      // Enable auto-scaling features
      scaling: {
        minInstancesInService: 2,
        cooldownPeriod: 300,
        targetCpuUtilization: 80,
        targetMemoryUtilization: 80
      }
    });
  }

  /**
   * Creates a dedicated node group for specific service workloads
   * @implements REQ-5.1: High-Level Architecture - Service-specific infrastructure
   */
  public createServiceNodeGroup(
    scope: Construct,
    cluster: eks.Cluster,
    vpc: VpcStack,
    name: string,
    config: ServiceNodeGroupConfig
  ): eks.NodeGroup {
    const nodeRole = this.createNodeRole(scope, name);

    const nodeGroup = new eks.NodeGroup(scope, `${name}NodeGroup`, {
      cluster,
      nodeRole,
      subnets: { subnets: vpc.privateSubnets },
      instanceTypes: config.instanceTypes,
      minSize: config.minSize,
      maxSize: config.maxSize,
      desiredSize: config.desiredSize,
      labels: {
        ...config.labels,
        'nodegroup': name,
        'environment': 'production'
      },
      taints: config.taints,
      // Configure capacity optimization
      capacityType: eks.CapacityType.ON_DEMAND,
      amiType: eks.NodegroupAmiType.AL2_X86_64,
      // Enable auto-scaling features
      scaling: {
        minInstancesInService: config.minSize,
        cooldownPeriod: 300,
        targetCpuUtilization: 80,
        targetMemoryUtilization: 80
      }
    });

    this.serviceNodeGroups.set(name, nodeGroup);
    return nodeGroup;
  }

  /**
   * Creates IAM role for node groups with required policies
   * @implements REQ-5.3.4: Container Orchestration - Node IAM configuration
   */
  private createNodeRole(scope: Construct, name: string): iam.Role {
    const role = new iam.Role(scope, `${name}NodeRole`, {
      assumedBy: new iam.ServicePrincipal('ec2.amazonaws.com'),
      description: `EKS node group role for ${name}`,
    });

    // Attach required AWS managed policies
    role.addManagedPolicy(
      iam.ManagedPolicy.fromAwsManagedPolicyName('AmazonEKSWorkerNodePolicy')
    );
    role.addManagedPolicy(
      iam.ManagedPolicy.fromAwsManagedPolicyName('AmazonEKS_CNI_Policy')
    );
    role.addManagedPolicy(
      iam.ManagedPolicy.fromAwsManagedPolicyName('AmazonEC2ContainerRegistryReadOnly')
    );
    role.addManagedPolicy(
      iam.ManagedPolicy.fromAwsManagedPolicyName('CloudWatchAgentServerPolicy')
    );

    // Add custom policy for node group operations
    role.addToPolicy(new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      actions: [
        'autoscaling:DescribeAutoScalingGroups',
        'autoscaling:DescribeAutoScalingInstances',
        'autoscaling:DescribeLaunchConfigurations',
        'autoscaling:DescribeTags',
        'autoscaling:SetDesiredCapacity',
        'autoscaling:TerminateInstanceInAutoScalingGroup'
      ],
      resources: ['*']
    }));

    return role;
  }
}