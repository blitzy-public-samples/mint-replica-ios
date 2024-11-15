// @aws-cdk-lib v2.0.0
import { Stack, Duration, Construct } from 'aws-cdk-lib';
import {
  Distribution,
  OriginAccessIdentity,
  ViewerProtocolPolicy,
  SecurityPolicyProtocol,
  AllowedMethods,
  CachePolicy,
  OriginRequestPolicy,
  CacheCookieBehavior,
  CacheHeaderBehavior,
  CacheQueryStringBehavior,
  ResponseHeadersPolicy,
  ResponseHeadersPolicyProps,
  BehaviorOptions
} from 'aws-cdk-lib/aws-cloudfront';
import { S3Origin } from 'aws-cdk-lib/aws-cloudfront-origins';
import { S3BucketStack } from '../s3/buckets';
import { CertificateStack } from '../acm/certificates';

/**
 * Human Tasks:
 * 1. Verify Route53 DNS records are properly configured for custom domain
 * 2. Monitor CloudFront distribution deployment status after creation
 * 3. Review and adjust cache settings based on application needs
 * 4. Set up CloudWatch alarms for distribution metrics
 * 5. Configure WAF rules if additional security is needed
 */

interface CloudFrontStackProps {
  readonly s3BucketStack: S3BucketStack;
  readonly certificateStack: CertificateStack;
  readonly domainNames: string[];
}

/**
 * CloudFront CDN Stack for content delivery and caching
 * @implements REQ-Content Delivery Network: AWS CloudFront configuration with global edge locations
 * @implements REQ-Infrastructure: Secure and scalable content delivery setup
 * @implements REQ-System Security: SSL/TLS and secure origin access implementation
 */
export class CloudFrontStack extends Stack {
  public readonly distribution: Distribution;
  public readonly originAccessIdentity: OriginAccessIdentity;

  constructor(scope: Construct, id: string, props: CloudFrontStackProps) {
    super(scope, id);

    // Create Origin Access Identity for secure S3 access
    this.originAccessIdentity = new OriginAccessIdentity(this, 'CloudFrontOAI', {
      comment: 'OAI for Mint Replica Lite assets access'
    });

    // Grant CloudFront OAI read access to the S3 bucket
    props.s3BucketStack.assetsBucket.grantRead(this.originAccessIdentity);

    // Create the CloudFront distribution
    this.distribution = this.createDistribution(props);

    // Add resource tags
    Stack.of(this).tags.setTag('Application', 'MintReplicaLite');
    Stack.of(this).tags.setTag('Environment', this.node.tryGetContext('environment'));
    Stack.of(this).tags.setTag('ManagedBy', 'CDK');
  }

  /**
   * Creates and configures the CloudFront distribution
   * @implements REQ-Content Delivery Network: Optimized caching and content delivery
   */
  private createDistribution(props: CloudFrontStackProps): Distribution {
    // Configure S3 origin with OAI
    const s3Origin = new S3Origin(props.s3BucketStack.assetsBucket, {
      originAccessIdentity: this.originAccessIdentity
    });

    // Create the distribution
    return new Distribution(this, 'CloudFrontDistribution', {
      // SSL/TLS Configuration
      certificate: props.certificateStack.certificate,
      domainNames: props.domainNames,
      minimumProtocolVersion: SecurityPolicyProtocol.TLS_V1_2_2021,
      
      // Default behavior configuration
      defaultBehavior: this.configureCacheBehavior('/*', s3Origin),
      
      // Enable additional security headers
      responseHeadersPolicy: this.createSecurityHeadersPolicy(),
      
      // Enable compression
      enableIpv6: true,
      enableLogging: true,
      logBucket: props.s3BucketStack.assetsBucket,
      logFilePrefix: 'cloudfront-logs/',
      
      // Price class optimization
      priceClass: 'PriceClass_100',
      
      // HTTP/2 and HTTP/3 support
      httpVersion: 'http2and3',
      
      // Enable WAF integration
      enabled: true,
      comment: 'Mint Replica Lite CDN Distribution'
    });
  }

  /**
   * Configures cache behaviors for content delivery
   * @implements REQ-Content Delivery Network: Optimized caching configuration
   */
  private configureCacheBehavior(pathPattern: string, origin: S3Origin): BehaviorOptions {
    return {
      origin,
      viewerProtocolPolicy: ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
      allowedMethods: AllowedMethods.ALLOW_GET_HEAD_OPTIONS,
      cachedMethods: AllowedMethods.ALLOW_GET_HEAD_OPTIONS,
      compress: true,
      cachePolicy: new CachePolicy(this, `CachePolicy-${pathPattern}`, {
        comment: `Cache policy for ${pathPattern}`,
        defaultTtl: Duration.days(1),
        minTtl: Duration.minutes(1),
        maxTtl: Duration.days(365),
        enableAcceptEncodingBrotli: true,
        enableAcceptEncodingGzip: true,
        cookieBehavior: CacheCookieBehavior.none(),
        headerBehavior: CacheHeaderBehavior.allowList('Accept', 'Accept-Encoding'),
        queryStringBehavior: CacheQueryStringBehavior.none()
      }),
      originRequestPolicy: OriginRequestPolicy.CORS_S3_ORIGIN
    };
  }

  /**
   * Creates security headers policy for the distribution
   * @implements REQ-System Security: Secure content delivery configuration
   */
  private createSecurityHeadersPolicy(): ResponseHeadersPolicy {
    return new ResponseHeadersPolicy(this, 'SecurityHeadersPolicy', {
      responseHeadersPolicyName: 'MintReplicaSecurityHeaders',
      securityHeadersBehavior: {
        contentSecurityPolicy: {
          contentSecurityPolicy: "default-src 'self'; img-src 'self' data: https:;",
          override: true
        },
        strictTransportSecurity: {
          accessControlMaxAge: Duration.days(365),
          includeSubdomains: true,
          preload: true,
          override: true
        },
        contentTypeOptions: { override: true },
        frameOptions: { frameOption: 'DENY', override: true },
        referrerPolicy: {
          referrerPolicy: 'strict-origin-when-cross-origin',
          override: true
        },
        xssProtection: { protection: true, modeBlock: true, override: true }
      },
      customHeadersBehavior: {
        customHeaders: [
          {
            header: 'Permissions-Policy',
            value: 'camera=(), microphone=(), geolocation=()',
            override: true
          }
        ]
      }
    } as ResponseHeadersPolicyProps);
  }
}