// AWS CDK v2.0.0
// @aws-cdk/aws-eks v2.0.0
// @aws-cdk/aws-iam v2.0.0

/**
 * Human Tasks:
 * 1. Verify AWS service quotas for EKS cluster resources
 * 2. Review IAM permissions for cluster role creation
 * 3. Ensure kubectl is configured for cluster access
 * 4. Validate Kubernetes version compatibility
 * 5. Review cluster endpoint access configuration
 */

import { Stack, StackProps } from 'aws-cdk-lib';
import * as eks from 'aws-cdk-lib/aws-eks';
import * as iam from 'aws-cdk-lib/aws-iam';
import { VpcStack } from '../vpc/main';
import { NodeGroups } from './node-groups';

/**
 * Properties for EKS cluster stack configuration
 * @implements REQ-5.3.4: Container Orchestration - EKS configuration
 */
export interface EksClusterStackProps extends StackProps {
  vpc: VpcStack;
  clusterVersion: eks.KubernetesVersion;
  environment: string;
}

/**
 * CDK Stack class that creates and configures the EKS cluster infrastructure
 * @implements REQ-5.3.4: Container Orchestration - EKS implementation
 * @implements REQ-5.1: High-Level Architecture - Container orchestration infrastructure
 */
export class EksClusterStack extends Stack {
  public readonly cluster: eks.Cluster;
  public readonly vpc: VpcStack;
  public readonly nodeGroups: NodeGroups;

  constructor(scope: Construct, id: string, props: EksClusterStackProps) {
    super(scope, id, props);

    // Store VPC reference
    this.vpc = props.vpc;

    // Create cluster IAM role
    const clusterRole = this.createClusterRole();

    // Create EKS cluster
    this.cluster = this.createCluster(clusterRole);

    // Initialize node groups
    this.nodeGroups = new NodeGroups(this, this.cluster, this.vpc);

    // Install required add-ons
    this.installAddOns();
  }

  /**
   * Creates IAM role for EKS cluster with required policies
   * @implements REQ-5.3.4: Container Orchestration - Cluster IAM configuration
   */
  private createClusterRole(): iam.Role {
    const role = new iam.Role(this, 'ClusterRole', {
      assumedBy: new iam.ServicePrincipal('eks.amazonaws.com'),
      description: 'EKS cluster role for Mint Replica Lite',
    });

    // Attach required AWS managed policies
    role.addManagedPolicy(
      iam.ManagedPolicy.fromAwsManagedPolicyName('AmazonEKSClusterPolicy')
    );
    role.addManagedPolicy(
      iam.ManagedPolicy.fromAwsManagedPolicyName('AmazonEKSVPCResourceController')
    );

    // Add custom policy for cluster operations
    role.addToPolicy(new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      actions: [
        'ec2:CreateVpcEndpoint',
        'ec2:DeleteVpcEndpoints',
        'ec2:DescribeVpcEndpoints',
        'ec2:ModifyVpcEndpoint',
        'ecr:GetAuthorizationToken',
        'ecr:BatchCheckLayerAvailability',
        'ecr:GetDownloadUrlForLayer',
        'ecr:GetRepositoryPolicy',
        'ecr:DescribeRepositories',
        'ecr:ListImages',
        'ecr:BatchGetImage'
      ],
      resources: ['*']
    }));

    return role;
  }

  /**
   * Creates EKS cluster with specified configuration
   * @implements REQ-5.3.4: Container Orchestration - Cluster configuration
   * @implements REQ-5.1: High-Level Architecture - Service infrastructure
   */
  private createCluster(role: iam.Role): eks.Cluster {
    return new eks.Cluster(this, 'MintReplicaCluster', {
      version: this.props.clusterVersion,
      clusterName: `mint-replica-${this.props.environment}`,
      role: role,
      vpc: this.vpc.vpc,
      vpcSubnets: [{ subnets: this.vpc.privateSubnets }],
      defaultCapacity: 0, // Managed by NodeGroups class
      endpointAccess: eks.EndpointAccess.PRIVATE,
      secretsEncryptionKey: new kms.Key(this, 'ClusterKey', {
        enableKeyRotation: true,
        description: 'EKS Secrets Encryption Key'
      }),
      // Enable control plane logging
      clusterLogging: [
        eks.ClusterLoggingTypes.API,
        eks.ClusterLoggingTypes.AUDIT,
        eks.ClusterLoggingTypes.AUTHENTICATOR,
        eks.ClusterLoggingTypes.CONTROLLER_MANAGER,
        eks.ClusterLoggingTypes.SCHEDULER
      ],
      // Configure Kubernetes API security
      securityGroup: new ec2.SecurityGroup(this, 'ClusterSecurityGroup', {
        vpc: this.vpc.vpc,
        description: 'EKS cluster security group',
        allowAllOutbound: true
      }),
      // Enable service account IRSA
      serviceAccountRole: true,
      // Configure cluster tags
      tags: {
        Environment: this.props.environment,
        Project: 'mint-replica-lite',
        ManagedBy: 'cdk'
      }
    });
  }

  /**
   * Installs required EKS add-ons
   * @implements REQ-5.3.4: Container Orchestration - Cluster add-ons
   */
  private installAddOns(): void {
    // Install VPC CNI
    this.cluster.addHelmChart('aws-vpc-cni', {
      chart: 'aws-vpc-cni',
      repository: 'https://aws.github.io/eks-charts',
      namespace: 'kube-system',
      version: '1.12.0',
      values: {
        env: {
          ENABLE_PREFIX_DELEGATION: 'true',
          ENABLE_POD_ENI: 'true'
        }
      }
    });

    // Install CoreDNS
    this.cluster.addHelmChart('coredns', {
      chart: 'coredns',
      repository: 'https://coredns.github.io/helm',
      namespace: 'kube-system',
      version: '1.8.7'
    });

    // Install kube-proxy
    this.cluster.addHelmChart('kube-proxy', {
      chart: 'kube-proxy',
      repository: 'https://kubernetes.github.io/kube-proxy',
      namespace: 'kube-system',
      version: '1.23.7'
    });

    // Install metrics-server
    this.cluster.addHelmChart('metrics-server', {
      chart: 'metrics-server',
      repository: 'https://kubernetes-sigs.github.io/metrics-server',
      namespace: 'kube-system',
      version: '0.6.1'
    });

    // Install cluster-autoscaler
    this.cluster.addHelmChart('cluster-autoscaler', {
      chart: 'cluster-autoscaler',
      repository: 'https://kubernetes.github.io/autoscaler',
      namespace: 'kube-system',
      version: '1.23.0',
      values: {
        autoDiscovery: {
          clusterName: this.cluster.clusterName
        },
        awsRegion: this.region
      }
    });
  }
}