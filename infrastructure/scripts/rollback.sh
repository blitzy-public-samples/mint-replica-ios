#!/bin/bash

# Human Tasks:
# 1. Configure AWS credentials with appropriate IAM permissions for rollback
# 2. Install required tools: aws-cli v2.0+, kubectl v1.25+, terraform v1.0.0+
# 3. Set up proper backup retention policies in AWS
# 4. Configure monitoring alerts for rollback events
# 5. Ensure proper access to Docker registry for image rollback
# 6. Verify backup storage locations are properly configured

# Implements:
# - Infrastructure Management (Technical Specification/5.3.4 Infrastructure)
# - Container Orchestration (Technical Specification/5.3.4 Infrastructure)
# - CI/CD (Technical Specification/5.3.4 Infrastructure)

# Import configuration from deploy script
source "$(dirname "$0")/deploy.sh"

# Global variables
ROLLBACK_LOG_FILE="/var/log/mint-replica/rollback.log"
MAX_ROLLBACK_ATTEMPTS=3
HEALTH_CHECK_TIMEOUT=300
STATE_BACKUP_DIR="/var/backup/mint-replica/terraform"

# Logging setup
mkdir -p "$(dirname "$ROLLBACK_LOG_FILE")"
exec 1> >(tee -a "$ROLLBACK_LOG_FILE")
exec 2>&1

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

error() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1" >&2
}

# Check prerequisites for rollback
check_rollback_prerequisites() {
    log "Checking rollback prerequisites..."
    
    # Check AWS CLI
    if ! aws --version | grep -q "aws-cli/2"; then
        error "AWS CLI v2.0+ is required"
        return 1
    fi

    # Check kubectl
    if ! kubectl version --client | grep -q "v1.25"; then
        error "kubectl v1.25+ is required"
        return 1
    fi

    # Check Terraform
    if ! terraform version | grep -q "v1.0"; then
        error "Terraform v1.0.0+ is required"
        return 1
    fi

    # Verify AWS credentials
    if ! aws sts get-caller-identity &>/dev/null; then
        error "Invalid AWS credentials"
        return 1
    fi

    # Check kubectl cluster access
    if ! kubectl cluster-info &>/dev/null; then
        error "Cannot access Kubernetes cluster"
        return 1
    fi

    # Verify Docker registry access
    if ! aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin "$(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com" &>/dev/null; then
        error "Cannot access ECR registry"
        return 1
    fi

    # Check state backup directory
    if [ ! -d "$STATE_BACKUP_DIR" ]; then
        error "State backup directory does not exist: $STATE_BACKUP_DIR"
        return 1
    fi

    log "Prerequisites check completed successfully"
    return 0
}

# Roll back Kubernetes services
rollback_kubernetes_services() {
    local previous_version=$1
    log "Rolling back Kubernetes services to version: $previous_version"

    # Roll back services in reverse order to maintain dependencies
    local services=(
        "sync-service"
        "notification-service"
        "goal-service"
        "investment-service"
        "budget-service"
        "transaction-service"
        "auth-service"
        "api-gateway"
    )

    for service in "${services[@]}"; do
        log "Rolling back $service..."
        
        # Get previous deployment manifest
        if ! kubectl rollout undo deployment "$service" -n "${KUBERNETES_NAMESPACES[0]}"; then
            error "Failed to roll back $service"
            return 1
        fi

        # Wait for rollback to complete
        if ! kubectl rollout status deployment "$service" -n "${KUBERNETES_NAMESPACES[0]}" --timeout="${HEALTH_CHECK_TIMEOUT}s"; then
            error "Rollback timeout for $service"
            return 1
        fi

        # Verify service health
        local retries=0
        while [ $retries -lt 5 ]; do
            if kubectl exec -it "$(kubectl get pod -l app=curl -n "${KUBERNETES_NAMESPACES[0]}" -o jsonpath='{.items[0].metadata.name}')" -n "${KUBERNETES_NAMESPACES[0]}" -- curl -s "http://$service:8080/health" | grep -q "healthy"; then
                log "$service is healthy after rollback"
                break
            fi
            retries=$((retries + 1))
            sleep 10
        done

        if [ $retries -eq 5 ]; then
            error "$service health check failed after rollback"
            return 1
        fi
    done

    log "Kubernetes services rollback completed successfully"
    return 0
}

# Roll back infrastructure using Terraform
rollback_infrastructure() {
    local state_backup_path=$1
    log "Rolling back infrastructure using state from: $state_backup_path"

    cd "$TERRAFORM_WORKSPACE" || exit 1

    # Initialize Terraform
    if ! terraform init; then
        error "Terraform initialization failed"
        return 1
    fi

    # Restore previous state
    if ! cp "$state_backup_path" terraform.tfstate; then
        error "Failed to restore Terraform state"
        return 1
    fi

    # Apply previous state
    if ! terraform apply -auto-approve; then
        error "Terraform apply failed during rollback"
        return 1
    fi

    # Verify critical infrastructure components
    log "Verifying infrastructure after rollback..."

    # Check EKS cluster
    if ! aws eks describe-cluster --name "mint-replica-${environment}" &>/dev/null; then
        error "EKS cluster verification failed after rollback"
        return 1
    fi

    # Verify RDS instances
    if ! aws rds describe-db-instances --query "DBInstances[?DBInstanceIdentifier=='mint-replica-${environment}']" &>/dev/null; then
        error "RDS verification failed after rollback"
        return 1
    fi

    # Check ElastiCache clusters
    if ! aws elasticache describe-cache-clusters --query "CacheClusters[?CacheClusterId=='mint-replica-${environment}']" &>/dev/null; then
        error "ElastiCache verification failed after rollback"
        return 1
    fi

    log "Infrastructure rollback completed successfully"
    return 0
}

# Verify system stability after rollback
verify_rollback() {
    log "Verifying system stability after rollback..."
    local start_time=$(date +%s)

    # Check service health endpoints
    local services=(
        "api-gateway:8080/healthz"
        "auth-service:8080/health"
        "transaction-service:8080/health"
        "budget-service:8080/health"
        "investment-service:8080/health"
        "goal-service:8080/health"
        "notification-service:8080/health"
        "sync-service:8080/health"
    )

    for service in "${services[@]}"; do
        while true; do
            if kubectl exec -it "$(kubectl get pod -l app=curl -n "${KUBERNETES_NAMESPACES[0]}" -o jsonpath='{.items[0].metadata.name}')" -n "${KUBERNETES_NAMESPACES[0]}" -- curl -s "http://$service" | grep -q "healthy"; then
                log "$service is healthy"
                break
            fi

            if [ $(($(date +%s) - start_time)) -gt "$HEALTH_CHECK_TIMEOUT" ]; then
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
    if ! kubectl exec -it "$(kubectl get pod -l app=redis-client -n "${KUBERNETES_NAMESPACES[0]}" -o jsonpath='{.items[0].metadata.name}')" -n "${KUBERNETES_NAMESPACES[0]}" -- redis-cli ping | grep -q "PONG"; then
        error "Cache system verification failed"
        return 1
    fi

    # Verify SSL/TLS
    log "Verifying SSL configuration..."
    if ! curl -k -s "https://api.mint-replica.com/healthz" | grep -q "healthy"; then
        error "SSL verification failed"
        return 1
    fi

    # Check Prometheus metrics
    log "Verifying monitoring system..."
    if ! curl -s "http://prometheus-server:9090/-/healthy" | grep -q "Healthy"; then
        error "Monitoring system verification failed"
        return 1
    fi

    log "System verification completed successfully"
    return 0
}

# Main rollback function
main() {
    local environment=$1
    local previous_version=$2
    local state_backup_path="$STATE_BACKUP_DIR/$environment/terraform.tfstate"

    log "Starting rollback process for environment: $environment to version: $previous_version"

    # Create rollback attempt counter
    local attempt=1

    while [ $attempt -le $MAX_ROLLBACK_ATTEMPTS ]; do
        log "Rollback attempt $attempt of $MAX_ROLLBACK_ATTEMPTS"

        # Check prerequisites
        if ! check_rollback_prerequisites; then
            error "Prerequisites check failed"
            exit 1
        fi

        # Roll back infrastructure
        if ! rollback_infrastructure "$state_backup_path"; then
            if [ $attempt -eq $MAX_ROLLBACK_ATTEMPTS ]; then
                error "Infrastructure rollback failed after $MAX_ROLLBACK_ATTEMPTS attempts"
                exit 1
            fi
            attempt=$((attempt + 1))
            continue
        fi

        # Roll back Kubernetes services
        if ! rollback_kubernetes_services "$previous_version"; then
            if [ $attempt -eq $MAX_ROLLBACK_ATTEMPTS ]; then
                error "Kubernetes services rollback failed after $MAX_ROLLBACK_ATTEMPTS attempts"
                exit 1
            fi
            attempt=$((attempt + 1))
            continue
        fi

        # Verify rollback
        if ! verify_rollback; then
            if [ $attempt -eq $MAX_ROLLBACK_ATTEMPTS ]; then
                error "Rollback verification failed after $MAX_ROLLBACK_ATTEMPTS attempts"
                exit 1
            fi
            attempt=$((attempt + 1))
            continue
        fi

        log "Rollback completed successfully"
        return 0
    done
}

# Script entry point
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <environment> <previous_version>"
    echo "Example: $0 staging v1.0.0"
    exit 1
fi

main "$1" "$2"