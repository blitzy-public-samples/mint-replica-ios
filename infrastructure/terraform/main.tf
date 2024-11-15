# Human Tasks:
# 1. Verify AWS account limits and service quotas
# 2. Configure AWS credentials and access keys
# 3. Create S3 bucket for Terraform state storage
# 4. Create DynamoDB table for state locking
# 5. Review and approve security group configurations
# 6. Validate CIDR ranges don't conflict with existing networks
# 7. Configure DNS records in Route 53 hosted zone
# 8. Set up monitoring alerts in Grafana

# Required Terraform version and providers
# @implements REQ-5.3.4: Infrastructure as Code - Define infrastructure using Terraform
terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws" # v4.0.0
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes" # v2.0.0
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm" # v2.0.0
      version = "~> 2.0"
    }
  }

  # @implements REQ-5.3.4: Infrastructure - Remote state management
  backend "s3" {
    bucket         = "mint-replica-lite-terraform-state"
    key            = "terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

# AWS Provider configuration
# @implements REQ-5.3.4: Cloud Platform - Configure AWS as cloud platform
provider "aws" {
  region = local.aws_region

  default_tags {
    tags = {
      Environment = "production"
      Project     = "mint-replica-lite"
      ManagedBy   = "terraform"
    }
  }
}

# Local variables
locals {
  aws_region    = "us-west-2"
  environment   = "production"
  project_name  = "mint-replica-lite"
  vpc_cidr      = "10.0.0.0/16"
  max_azs       = 3
}

# VPC Module
# @implements REQ-5.3.4: Infrastructure - Network configuration
module "vpc" {
  source = "../aws/vpc"

  vpc_cidr     = local.vpc_cidr
  max_azs      = local.max_azs
  environment  = local.environment
  project_name = local.project_name

  tags = {
    Component = "Networking"
  }
}

# EKS Module
# @implements REQ-5.3.4: Container Orchestration - Set up Kubernetes using AWS EKS
module "eks" {
  source = "../aws/eks"

  cluster_name    = "${local.project_name}-cluster"
  cluster_version = "1.24"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnet_ids
  environment     = local.environment

  node_groups = {
    general = {
      desired_size = 2
      min_size     = 1
      max_size     = 4
      instance_types = ["t3.medium"]
    }
    compute = {
      desired_size = 2
      min_size     = 1
      max_size     = 6
      instance_types = ["t3.large"]
    }
  }

  tags = {
    Component = "Container-Orchestration"
  }
}

# RDS Module for PostgreSQL
module "rds" {
  source = "../aws/rds"

  identifier     = "${local.project_name}-db"
  engine         = "postgres"
  engine_version = "14.6"
  instance_class = "db.t3.medium"
  
  vpc_id               = module.vpc.vpc_id
  subnet_ids           = module.vpc.isolated_subnet_ids
  security_group_ids   = [module.vpc.database_security_group_id]
  
  database_name = "mintreplicadb"
  port         = 5432
  
  backup_retention_period = 7
  multi_az               = true
  
  tags = {
    Component = "Database"
  }
}

# ElastiCache Module for Redis
module "elasticache" {
  source = "../aws/elasticache"

  cluster_id           = "${local.project_name}-cache"
  engine              = "redis"
  engine_version      = "6.x"
  node_type           = "cache.t3.medium"
  
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.isolated_subnet_ids
  security_group_ids = [module.vpc.cache_security_group_id]
  
  num_cache_nodes    = 2
  port              = 6379
  
  tags = {
    Component = "Caching"
  }
}

# Monitoring Stack
# @implements REQ-5.3.4: Monitoring - Configure Prometheus & Grafana
module "monitoring" {
  source = "../aws/monitoring"

  cluster_name = module.eks.cluster_name
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.private_subnet_ids

  prometheus_retention_period = "15d"
  grafana_admin_password     = data.aws_secretsmanager_secret_version.grafana_password.secret_string

  tags = {
    Component = "Monitoring"
  }
}

# Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "isolated_subnet_ids" {
  description = "Isolated subnet IDs"
  value       = module.vpc.isolated_subnet_ids
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_security_group_id" {
  description = "EKS cluster security group ID"
  value       = module.eks.cluster_security_group_id
}

output "cluster_iam_role_arn" {
  description = "EKS cluster IAM role ARN"
  value       = module.eks.cluster_iam_role_arn
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.rds.endpoint
}

output "rds_port" {
  description = "RDS instance port"
  value       = module.rds.port
}

output "elasticache_endpoint" {
  description = "ElastiCache cluster endpoint"
  value       = module.elasticache.endpoint
}

output "elasticache_port" {
  description = "ElastiCache cluster port"
  value       = module.elasticache.port
}