// AWS CDK v2.0.0
import * as aws_ec2 from 'aws-cdk-lib/aws-ec2';

/**
 * Human Tasks:
 * 1. Ensure AWS credentials are properly configured with permissions for VPC and subnet operations
 * 2. Verify region-specific availability zone quotas match AZ_COUNT configuration
 * 3. Review and adjust SUBNET_MASKS if network segmentation requirements change
 */

// Global subnet configuration constants
const SUBNET_MASKS = {
  PUBLIC: '/20',   // For API Gateway Layer components
  PRIVATE: '/19',  // For Service Layer components
  ISOLATED: '/20'  // For Data Layer components
} as const;

// Number of availability zones to use for high availability
const AZ_COUNT = 3;

/**
 * Interface defining subnet configuration properties
 * @implements REQ-5.1: Multi-tier architecture network segmentation
 * @implements REQ-5.2: Component isolation requirements
 */
export interface SubnetConfiguration {
  name: string;
  cidrRange: string;
  subnetType: aws_ec2.SubnetType;
}

/**
 * Calculates CIDR range for a subnet based on VPC CIDR, subnet type and index
 * @implements REQ-5.3.4: AWS infrastructure configuration
 * @param vpcCidr - The VPC CIDR range (e.g. "10.0.0.0/16")
 * @param subnetType - Type of subnet (PUBLIC, PRIVATE, or ISOLATED)
 * @param subnetIndex - Index of the subnet within its type group
 * @returns Calculated CIDR range for the subnet
 */
export function calculateSubnetCidr(
  vpcCidr: string,
  subnetType: keyof typeof SUBNET_MASKS,
  subnetIndex: number
): string {
  // Validate VPC CIDR format
  const cidrPattern = /^(\d{1,3}\.){3}\d{1,3}\/\d{1,2}$/;
  if (!cidrPattern.test(vpcCidr)) {
    throw new Error('Invalid VPC CIDR format');
  }

  // Parse VPC CIDR components
  const [baseAddress, vpcMask] = vpcCidr.split('/');
  const vpcOctets = baseAddress.split('.').map(Number);
  const subnetMask = parseInt(SUBNET_MASKS[subnetType].slice(1));
  
  // Calculate subnet size and offset
  const maskDiff = subnetMask - parseInt(vpcMask);
  const subnetsPerType = Math.pow(2, maskDiff);
  
  // Calculate base offset based on subnet type
  let typeOffset = 0;
  switch (subnetType) {
    case 'PUBLIC':
      typeOffset = 0;
      break;
    case 'PRIVATE':
      typeOffset = subnetsPerType;
      break;
    case 'ISOLATED':
      typeOffset = subnetsPerType * 2;
      break;
  }

  // Calculate final subnet address
  const subnetOffset = typeOffset + subnetIndex;
  const subnetSize = Math.pow(2, 32 - subnetMask);
  const subnetStart = (vpcOctets[0] << 24) + 
                     (vpcOctets[1] << 16) + 
                     (vpcOctets[2] << 8) + 
                     vpcOctets[3] + 
                     (subnetOffset * subnetSize);

  // Convert back to CIDR notation
  const newOctets = [
    (subnetStart >> 24) & 255,
    (subnetStart >> 16) & 255,
    (subnetStart >> 8) & 255,
    subnetStart & 255
  ];

  // Validate the calculated CIDR is within VPC range
  const vpcStart = (vpcOctets[0] << 24) + 
                  (vpcOctets[1] << 16) + 
                  (vpcOctets[2] << 8) + 
                  vpcOctets[3];
  const vpcEnd = vpcStart + Math.pow(2, 32 - parseInt(vpcMask));
  
  if (subnetStart < vpcStart || (subnetStart + subnetSize) > vpcEnd) {
    throw new Error('Calculated subnet CIDR is outside VPC range');
  }

  return `${newOctets.join('.')}${SUBNET_MASKS[subnetType]}`;
}

/**
 * Retrieves available AWS availability zones for subnet distribution
 * @implements REQ-5.3.4: AWS infrastructure configuration
 * @param vpc - The VPC instance to get availability zones for
 * @returns Promise resolving to array of AZ names
 */
export async function getAvailabilityZones(vpc: aws_ec2.IVpc): Promise<string[]> {
  // Get all AZs in the VPC's region
  const azs = await vpc.availabilityZones;
  
  // Filter for enabled AZs and sort alphabetically
  const enabledAzs = azs
    .filter(az => az.length > 0)  // Ensure AZ name is valid
    .sort((a, b) => a.localeCompare(b));
  
  // Limit to configured AZ count
  return enabledAzs.slice(0, AZ_COUNT);
}