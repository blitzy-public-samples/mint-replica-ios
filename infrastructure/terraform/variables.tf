# @implements REQ-5.3.4: Infrastructure as Code - Define infrastructure variables using Terraform for AWS cloud platform deployment
# @implements REQ-5.3.4: Cloud Platform - Configure AWS as the cloud platform for hosting the application
# @implements REQ-5.3.4: Container Orchestration - Set up Kubernetes using AWS EKS

# Global Variables
variable "aws_region" {
  type        = string
  description = "AWS region where resources will be created"
  default     = "us-west-2"
}

variable "environment" {
  type        = string
  description = "Environment name for resource tagging"
  default     = "production"
}

variable "project_name" {
  type        = string
  description = "Project name for resource tagging and naming"
  default     = "mint-replica-lite"
}

variable "max_azs" {
  type        = number
  description = "Maximum number of availability zones to use"
  default     = 3
}

# Network Variables
variable "vpc_cidr" {
  type        = string
  description = "CIDR block for VPC network"
  default     = "10.0.0.0/16"
}

# EKS Variables
variable "eks_cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
  default     = "mint-replica-lite-cluster"
}

# Database Variables
variable "db_instance_class" {
  type        = string
  description = "RDS instance type"
  default     = "db.t3.medium"
}

# Cache Variables
variable "redis_node_type" {
  type        = string
  description = "ElastiCache Redis node type"
  default     = "cache.t3.medium"
}

# DNS Variables
variable "domain_name" {
  type        = string
  description = "Domain name for the application"
}

# Resource Tagging
variable "tags" {
  type        = map(string)
  description = "Common tags to apply to all resources"
  default = {
    Environment = "production"
    Project     = "mint-replica-lite"
    ManagedBy   = "terraform"
  }
}

# State Management
variable "terraform_state_bucket" {
  type        = string
  description = "S3 bucket name for storing Terraform state"
  default     = "mint-replica-lite-terraform-state"
}