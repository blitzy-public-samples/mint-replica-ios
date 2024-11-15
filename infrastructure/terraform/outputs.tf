# @implements REQ-5.3.4: Infrastructure as Code - Define infrastructure outputs using Terraform
# @implements REQ-5.3.4: Cloud Platform - Expose AWS infrastructure resource outputs
# @implements REQ-5.3.4: Container Orchestration - Output EKS cluster details

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.vpc.private_subnet_ids
}

# EKS Cluster Outputs
output "eks_cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

# Database Outputs
output "rds_endpoint" {
  description = "Endpoint for RDS database"
  value       = module.rds.endpoint
}

# Cache Outputs
output "redis_endpoint" {
  description = "Endpoint for Redis cache"
  value       = module.elasticache.endpoint
}

# CDN Outputs
output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = module.cloudfront.domain_name
}