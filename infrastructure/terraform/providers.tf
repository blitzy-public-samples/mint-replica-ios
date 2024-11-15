# @implements REQ-5.3.4: Infrastructure as Code - Define infrastructure using Terraform with appropriate provider configurations
# @implements REQ-5.3.4: Cloud Platform Selection - AWS specified as the cloud platform for infrastructure deployment
# @implements REQ-5.3.4: Container Orchestration - Kubernetes specified for container orchestration requiring AWS EKS provider

# Human Tasks:
# 1. Ensure AWS credentials are properly configured in the environment or AWS credentials file
# 2. Create the DynamoDB table 'mint-replica-lite-terraform-locks' for state locking
# 3. Verify the S3 bucket specified in var.terraform_state_bucket exists and is properly configured for versioning
# 4. Ensure proper IAM permissions are set up for EKS cluster access

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    # AWS Provider v4.0 for infrastructure provisioning
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }

    # Kubernetes Provider v2.0 for EKS cluster configuration
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }

    # Helm Provider v2.0 for Kubernetes package management
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }

  backend "s3" {
    bucket         = "${var.terraform_state_bucket}"
    key            = "terraform.tfstate"
    region         = "${var.aws_region}"
    encrypt        = true
    dynamodb_table = "mint-replica-lite-terraform-locks"
  }
}

# AWS Provider Configuration
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "MintReplicaLite"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# Kubernetes Provider Configuration for EKS
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

# Helm Provider Configuration for Kubernetes package management
provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}