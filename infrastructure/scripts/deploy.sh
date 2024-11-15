#!/bin/bash

# Human Tasks:
# 1. Configure AWS credentials with appropriate IAM permissions
# 2. Install required tools: aws-cli v2.0+, kubectl v1.25+, terraform v1.0.0+
# 3. Set up AWS ACM certificate for API Gateway SSL termination
# 4. Configure GitHub Actions secrets for automated deployments
# 5. Set up Prometheus monitoring prerequisites
# 6. Configure backup retention policies in AWS
# 7. Set up proper DNS records for services

# Implements:
# - Infrastructure Management (Technical Specification/5.3.4 Infrastructure)
# - Container Orchestration (Technical Specification/5.3.4 Infrastructure)
# - CI/CD (Technical Specification/5.3.4 Infrastructure)

# Global variables
DEPLOY_LOG_FILE="/var/log/mint-replica/deploy.log"
MAX_DEPLOY_ATTEMPTS=3
HEALTH_CHECK_TIMEOUT=300
KUBERNETES_NAMESPACES=("mint-api" "mint-auth" "mint-core")
TERRAFORM_WORKSPACE="infrastructure/terraform"

# Logging setup
mkdir -p "$(dirname "$DEPLOY_LOG_FILE")"
exec 1> >(tee -a "$DEPLOY_LOG_FILE")
exec 2>&1

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

error() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1" >&2
}

# Check prerequisites for deployment
check_prerequisites() {
    log "Checking deployment prerequisites..."
    
    # Check AWS CLI
    if ! aws --version | grep -q "aws-cli/2"; then
        error "AWS CLI v2.0+ is required"
        return 1
    fi

    # Check kubectl
    if ! kubectl version --client | grep -q "v1.25"; then
        error "kubectl v1.25+ is required"
        return 1
    }

    # Check Terraform
    if ! terraform version | grep -q "v1.0"; then
        error "Terraform v1.0.0+ is required"
        return 1
    }

    # Verify AWS credentials
    if ! aws sts get-caller-identity &>/dev/null; then
        error "Invalid AWS credentials"
        return 1
    }

    # Check kubectl cluster access
    if ! kubectl cluster-info &>/dev/null; then
        error "Cannot access Kubernetes cluster"
        return 1
    }

    # Verify Docker registry access
    if ! aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin "$(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com" &>/dev/null; then
        error "Cannot access ECR registry"
        return 1
    }

    log "Prerequisites check completed successfully"
    return 0
}

# Deploy infrastructure using Terraform
deploy_infrastructure() {
    local environment=$1
    log "Deploying infrastructure for environment: $environment"

    cd "$TERRAFORM_WORKSPACE" || exit 1

    # Initialize Terraform
    if ! terraform init; then
        error "Terraform initialization failed"
        return 1
    }

    # Select workspace
    terraform workspace select "$environment" || terraform workspace new "$environment"

    # Plan and apply infrastructure changes
    terraform plan -out=tfplan
    if ! terraform apply -auto-approve tfplan; then
        error "Terraform apply failed"
        return 1
    }

    # Verify critical infrastructure components
    log "Verifying infrastructure deployment..."

    # Check EKS cluster
    if ! aws eks describe-cluster --name "mint-replica-$environment" &>/dev/null; then
        error "EKS cluster verification failed"
        return 1
    }

    # Verify RDS instances
    if ! aws rds describe-db-instances --query 'DBInstances[?DBInstanceIdentifier==`mint-replica-'$environment'`]' &>/dev/null; then
        error "RDS verification failed"
        return 1
    }

    # Check ElastiCache clusters
    if ! aws elasticache describe-cache-clusters --query 'CacheClusters[?CacheClusterId==`mint-replica-'$environment'`]' &>/dev/null; then
        error "ElastiCache verification failed"
        return 1
    }

    log "Infrastructure deployment completed successfully"
    return 0
}

# Deploy Kubernetes services
deploy_kubernetes_services() {
    local version=$1
    log "Deploying Kubernetes services version: $version"

    # Create namespaces if they don't exist
    for namespace in "${KUBERNETES_NAMESPACES[@]}"; do
        kubectl create namespace "$namespace" --dry-run=client -o yaml | kubectl apply -f -
    done

    # Apply API Gateway configuration
    log "Deploying API Gateway..."
    if ! kubectl apply -f infrastructure/k8s/services/api-gateway.yaml; then
        error "API Gateway deployment failed"
        return 1
    }

    # Deploy core services
    local services=(
        "auth-service"
        "transaction-service"
        "budget-service"
        "investment-service"
        "goal-service"
        "notification-service"
        "sync-service"
    )

    for service in "${services[@]}"; do
        log "Deploying $service..."
        if ! kubectl apply -f "infrastructure/k8s/services/$service.yaml"; then
            error "$service deployment failed"
            return 1
        fi
    done

    # Configure Prometheus monitoring
    log "Setting up monitoring..."
    kubectl apply -f infrastructure/k8s/monitoring/

    log "Kubernetes services deployment completed"
    return 0
}

# Verify deployment health
verify_deployment() {
    log "Verifying deployment health..."
    local timeout=$HEALTH_CHECK_TIMEOUT
    local start_time=$(date +%s)

    # Check service health endpoints
    local services=(
        "api-gateway.mint-api:8080/healthz"
        "authentication.mint-auth:8080/health"
        "transactions.mint-transactions:8080/health"
        "budgets.mint-budgets:8080/health"
        "investments.mint-investments:8080/health"
        "goals.mint-goals:8080/health"
        "notifications.mint-notifications:8080/health"
        "sync.mint-sync:8080/health"
    )

    for service in "${services[@]}"; do
        while true; do
            if kubectl exec -it "$(kubectl get pod -l app=curl -n mint-api -o jsonpath='{.items[0].metadata.name}')" -n mint-api -- curl -s "http://$service" | grep -q "healthy"; then
                log "$service is healthy"
                break
            fi

            if [ $(($(date +%s) - start_time)) -gt "$timeout" ]; then
                error "Health check timeout for $service"
                return 1
            fi
            sleep 5
        done
    done

    # Verify database connectivity
    log "Verifying database connections..."
    for ns in "${KUBERNETES_NAMESPACES[@]}"; do
        if ! kubectl get pods -n "$ns" -l tier=database | grep -q "Running"; then
            error "Database pods not running in namespace $ns"
            return 1
        fi
    done

    # Check ElastiCache
    log "Verifying cache system..."
    if ! kubectl exec -it "$(kubectl get pod -l app=redis-client -n mint-api -o jsonpath='{.items[0].metadata.name}')" -n mint-api -- redis-cli ping | grep -q "PONG"; then
        error "Cache system verification failed"
        return 1
    fi

    # Verify SSL/TLS
    log "Verifying SSL configuration..."
    if ! curl -k -s "https://api.mint-replica.com/healthz" | grep -q "healthy"; then
        error "SSL verification failed"
        return 1
    }

    log "Deployment verification completed successfully"
    return 0
}

# Main deployment function
main() {
    local environment=$1
    local version=$2

    log "Starting deployment process for environment: $environment, version: $version"

    # Create deployment attempt counter
    local attempt=1

    while [ $attempt -le $MAX_DEPLOY_ATTEMPTS ]; do
        log "Deployment attempt $attempt of $MAX_DEPLOY_ATTEMPTS"

        # Check prerequisites
        if ! check_prerequisites; then
            error "Prerequisites check failed"
            exit 1
        fi

        # Deploy infrastructure
        if ! deploy_infrastructure "$environment"; then
            if [ $attempt -eq $MAX_DEPLOY_ATTEMPTS ]; then
                error "Infrastructure deployment failed after $MAX_DEPLOY_ATTEMPTS attempts"
                exit 1
            fi
            attempt=$((attempt + 1))
            continue
        fi

        # Deploy Kubernetes services
        if ! deploy_kubernetes_services "$version"; then
            if [ $attempt -eq $MAX_DEPLOY_ATTEMPTS ]; then
                error "Kubernetes services deployment failed after $MAX_DEPLOY_ATTEMPTS attempts"
                exit 1
            fi
            attempt=$((attempt + 1))
            continue
        fi

        # Verify deployment
        if ! verify_deployment; then
            if [ $attempt -eq $MAX_DEPLOY_ATTEMPTS ]; then
                error "Deployment verification failed after $MAX_DEPLOY_ATTEMPTS attempts"
                exit 1
            fi
            attempt=$((attempt + 1))
            continue
        fi

        log "Deployment completed successfully"
        return 0
    done
}

# Script entry point
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <environment> <version>"
    echo "Example: $0 staging v1.0.0"
    exit 1
fi

main "$1" "$2"