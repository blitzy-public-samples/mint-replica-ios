// @aws-cdk-lib v2.0.0
import { Stack, Duration, CfnOutput } from 'aws-cdk-lib';
import { 
  HostedZone, 
  ARecord, 
  AaaaRecord, 
  RecordTarget, 
  IHostedZone 
} from 'aws-cdk-lib/aws-route53';
// @aws-cdk-lib/aws-route53-targets v2.0.0
import { CloudFrontTarget } from 'aws-cdk-lib/aws-route53-targets';
import { CloudFrontStack } from '../cloudfront/main';
import { CertificateStack } from '../acm/certificates';

/**
 * Human Tasks:
 * 1. Verify domain ownership and DNS nameserver configuration
 * 2. Monitor DNS propagation after record creation
 * 3. Validate DNS resolution for both IPv4 and IPv6 endpoints
 * 4. Set up DNS health checks in AWS Console if needed
 * 5. Configure Route53 monitoring alerts in CloudWatch
 */

interface Route53RecordsStackProps {
  readonly domainName: string;
  readonly cloudFrontStack: CloudFrontStack;
  readonly certificateStack: CertificateStack;
  readonly hostedZoneId?: string;
}

/**
 * Stack for managing Route53 DNS records including A records, AAAA records,
 * and certificate validation records
 * @implements REQ-DNS Configuration: Implementation of DNS routing and domain name resolution
 * @implements REQ-Infrastructure: AWS Route53 for DNS management
 */
export class Route53RecordsStack extends Stack {
  public readonly hostedZone: IHostedZone;
  public readonly domainName: string;
  public readonly aliasRecords: ARecord[] = [];

  constructor(scope: Construct, id: string, props: Route53RecordsStackProps) {
    super(scope, id);

    this.domainName = props.domainName;

    // Look up existing hosted zone or create new one
    this.hostedZone = props.hostedZoneId 
      ? HostedZone.fromHostedZoneId(this, 'HostedZone', props.hostedZoneId)
      : new HostedZone(this, 'HostedZone', {
          zoneName: this.domainName,
          comment: 'Managed by CDK for Mint Replica Lite'
        });

    // Create A record for IPv4
    const aRecord = this.createAliasRecord(props.cloudFrontStack.distribution);
    this.aliasRecords.push(aRecord);

    // Create AAAA record for IPv6
    this.createAaaaRecord(props.cloudFrontStack.distribution);

    // Create certificate validation records if needed
    this.createValidationRecords(props.certificateStack.certificate);

    // Add CloudFormation outputs
    new CfnOutput(this, 'HostedZoneId', {
      value: this.hostedZone.hostedZoneId,
      description: 'Route53 Hosted Zone ID'
    });

    new CfnOutput(this, 'NameServers', {
      value: this.hostedZone.hostedZoneNameServers?.join(', ') || 'N/A',
      description: 'Route53 Hosted Zone Nameservers'
    });

    // Add resource tags
    Stack.of(this).tags.setTag('Application', 'MintReplicaLite');
    Stack.of(this).tags.setTag('Environment', this.node.tryGetContext('environment'));
    Stack.of(this).tags.setTag('ManagedBy', 'CDK');
  }

  /**
   * Creates an A record alias pointing to CloudFront distribution
   * @implements REQ-DNS Configuration: IPv4 DNS routing configuration
   */
  private createAliasRecord(distribution: Distribution): ARecord {
    return new ARecord(this, 'AliasRecord', {
      zone: this.hostedZone,
      recordName: this.domainName,
      target: RecordTarget.fromAlias(new CloudFrontTarget(distribution)),
      ttl: Duration.seconds(300),
      comment: 'CloudFront distribution alias record'
    });
  }

  /**
   * Creates an AAAA record for IPv6 support
   * @implements REQ-DNS Configuration: IPv6 DNS routing configuration
   */
  private createAaaaRecord(distribution: Distribution): AaaaRecord {
    return new AaaaRecord(this, 'AaaaRecord', {
      zone: this.hostedZone,
      recordName: this.domainName,
      target: RecordTarget.fromAlias(new CloudFrontTarget(distribution)),
      ttl: Duration.seconds(300),
      comment: 'CloudFront distribution IPv6 alias record'
    });
  }

  /**
   * Creates DNS validation records for ACM certificate
   * @implements REQ-Infrastructure: DNS validation for SSL/TLS certificates
   */
  private createValidationRecords(certificate: ICertificate): void {
    // DNS validation records are automatically created by the CDK
    // through the CertificateValidation.fromDns() method used in CertificateStack
    
    // The following are configured automatically:
    // - CNAME records for validation
    // - 300 second TTL
    // - Automatic record cleanup
    // - Record update behavior
  }
}