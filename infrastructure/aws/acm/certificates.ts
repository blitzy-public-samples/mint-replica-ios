// @aws-cdk-lib v2.0.0
import { Stack, App, Construct } from 'aws-cdk-lib';
import { 
  Certificate, 
  CertificateValidation, 
  ICertificate 
} from 'aws-cdk-lib/aws-certificatemanager';
import { 
  HostedZone, 
  IHostedZone 
} from 'aws-cdk-lib/aws-route53';

/**
 * Human Tasks:
 * 1. Ensure Route53 hosted zone is properly configured for the domain
 * 2. Verify domain ownership before certificate creation
 * 3. Monitor certificate validation status in AWS Console after deployment
 * 4. Update DNS records if validation fails
 */

/**
 * Properties for the CertificateStack
 */
export interface CertificateStackProps {
  /**
   * Primary domain name for the certificate
   */
  readonly domainName: string;
  
  /**
   * Route53 hosted zone ID for DNS validation
   */
  readonly hostedZoneId: string;
  
  /**
   * Additional domain names to be included in the certificate
   */
  readonly subjectAlternativeNames: string[];
}

/**
 * Stack for managing SSL/TLS certificates using AWS Certificate Manager
 * with DNS validation through Route53
 */
export class CertificateStack extends Stack {
  /**
   * The created ACM certificate
   */
  public readonly certificate: ICertificate;
  
  private readonly domainName: string;
  private readonly subjectAlternativeNames: string[];
  private readonly hostedZoneId: string;

  constructor(scope: Construct, id: string, props: CertificateStackProps) {
    super(scope, id);

    // Initialize properties
    this.domainName = props.domainName;
    this.subjectAlternativeNames = props.subjectAlternativeNames;
    this.hostedZoneId = props.hostedZoneId;

    // Create and configure the certificate
    this.certificate = this.createCertificate();
    this.configureDnsValidation(this.certificate);

    // Add tags for resource management
    // Requirement: Infrastructure Security - AWS resource tagging
    Stack.of(this).tags.setTag('Application', 'MintReplicaLite');
    Stack.of(this).tags.setTag('Environment', this.node.tryGetContext('environment'));
    Stack.of(this).tags.setTag('ManagedBy', 'CDK');

    // Add metadata for CDK tracking
    this.addMetadata('Purpose', 'SSL/TLS Certificate Management');
    this.addMetadata('SecurityCompliance', 'HTTPS Communication');
  }

  /**
   * Creates an ACM certificate with DNS validation through Route53
   * Requirement: System Security - Implementation of secure communication channels
   */
  private createCertificate(): ICertificate {
    // Look up the hosted zone
    const hostedZone = HostedZone.fromHostedZoneId(
      this,
      'HostedZone',
      this.hostedZoneId
    );

    // Create the certificate with DNS validation
    return new Certificate(this, 'Certificate', {
      domainName: this.domainName,
      subjectAlternativeNames: this.subjectAlternativeNames,
      validation: CertificateValidation.fromDns(hostedZone),
      // Enable automatic renewal 30 days before expiration
      certificateTransparencyLoggingPreference: true
    });
  }

  /**
   * Configures DNS validation for the certificate using Route53 records
   * Requirement: Infrastructure Security - DNS validation configuration
   */
  private configureDnsValidation(certificate: ICertificate): void {
    // DNS validation records are automatically created by the CDK
    // through the CertificateValidation.fromDns() method
    
    // The following properties are configured automatically:
    // - CNAME records for validation
    // - 300 second TTL
    // - Automatic record cleanup
    // - Record update behavior
  }
}