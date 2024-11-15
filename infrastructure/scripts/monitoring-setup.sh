#!/bin/bash

# Human Tasks:
# 1. Ensure kubectl is installed and configured with cluster admin access
# 2. Ensure helm v3.0+ is installed
# 3. Configure persistent storage class for Prometheus and Grafana if needed
# 4. Set up external access/ingress if required
# 5. Configure alertmanager endpoints and notification channels
# 6. Generate and set secure credentials for Grafana admin user

# Implements:
# - Infrastructure Monitoring (Technical Specification/5.3.4 Infrastructure)
# - Service Monitoring (Technical Specification/5.1 High-Level Architecture Overview)

set -euo pipefail

# Source common utilities
. "$(dirname "${BASH_SOURCE[0]}")/../common/utils.sh"

# Script constants
MONITORING_NAMESPACE="monitoring"
PROMETHEUS_VERSION="2.45.0"
GRAFANA_VERSION="9.5.3"

# Function to check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed"
        return 1
    fi
    
    # Check helm
    if ! command -v helm &> /dev/null; then
        log_error "helm is not installed"
        return 1
    fi
    
    # Check cluster access
    if ! kubectl auth can-i create namespace --all-namespaces &> /dev/null; then
        log_error "Insufficient cluster permissions"
        return 1
    }
    
    return 0
}

# Function to setup monitoring namespace
setup_monitoring_namespace() {
    log_info "Setting up monitoring namespace..."
    
    # Create namespace if not exists
    kubectl create namespace ${MONITORING_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
    
    # Create service accounts
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: prometheus
  namespace: ${MONITORING_NAMESPACE}
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: grafana
  namespace: ${MONITORING_NAMESPACE}
EOF
    
    # Setup RBAC roles
    cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: prometheus
rules:
- apiGroups: [""]
  resources:
  - nodes
  - nodes/proxy
  - services
  - endpoints
  - pods
  verbs: ["get", "list", "watch"]
- apiGroups: ["extensions"]
  resources:
  - ingresses
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: prometheus
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: prometheus
subjects:
- kind: ServiceAccount
  name: prometheus
  namespace: ${MONITORING_NAMESPACE}
EOF
}

# Function to deploy Prometheus
deploy_prometheus() {
    log_info "Deploying Prometheus v${PROMETHEUS_VERSION}..."
    
    # Apply Prometheus configuration
    kubectl apply -f ../k8s/config/prometheus.yaml
    
    # Wait for Prometheus to be ready
    kubectl rollout status statefulset/prometheus -n ${MONITORING_NAMESPACE} --timeout=300s
    
    # Verify Prometheus endpoint
    local prometheus_pod=$(kubectl get pods -n ${MONITORING_NAMESPACE} -l app=prometheus -o jsonpath="{.items[0].metadata.name}")
    kubectl port-forward -n ${MONITORING_NAMESPACE} ${prometheus_pod} 9090:9090 &
    local port_forward_pid=$!
    
    sleep 5
    if ! curl -s http://localhost:9090/-/healthy > /dev/null; then
        log_error "Prometheus health check failed"
        kill ${port_forward_pid}
        return 1
    }
    kill ${port_forward_pid}
}

# Function to deploy Grafana
deploy_grafana() {
    log_info "Deploying Grafana v${GRAFANA_VERSION}..."
    
    # Generate secure credentials for Grafana
    local admin_password=$(openssl rand -base64 32)
    local secret_key=$(openssl rand -base64 32)
    
    # Create Grafana secrets
    kubectl create secret generic grafana-secrets \
        --from-literal=admin-password="${admin_password}" \
        --from-literal=secret-key="${secret_key}" \
        -n ${MONITORING_NAMESPACE} \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Apply Grafana configuration
    kubectl apply -f ../k8s/config/grafana.yaml
    
    # Wait for Grafana to be ready
    kubectl rollout status deployment/grafana -n ${MONITORING_NAMESPACE} --timeout=300s
    
    log_info "Grafana admin password: ${admin_password}"
}

# Function to configure service monitoring
configure_service_monitoring() {
    log_info "Configuring service monitoring..."
    
    # Apply ServiceMonitor CRDs for each service
    cat <<EOF | kubectl apply -f -
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: api-gateway
  namespace: ${MONITORING_NAMESPACE}
spec:
  selector:
    matchLabels:
      app: api-gateway
  endpoints:
  - port: metrics
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: auth-service
  namespace: ${MONITORING_NAMESPACE}
spec:
  selector:
    matchLabels:
      app: auth-service
  endpoints:
  - port: metrics
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: transaction-service
  namespace: ${MONITORING_NAMESPACE}
spec:
  selector:
    matchLabels:
      app: transaction-service
  endpoints:
  - port: metrics
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: budget-service
  namespace: ${MONITORING_NAMESPACE}
spec:
  selector:
    matchLabels:
      app: budget-service
  endpoints:
  - port: metrics
EOF
}

# Function to verify monitoring stack
verify_monitoring_stack() {
    log_info "Verifying monitoring stack..."
    
    # Check Prometheus targets
    local prometheus_pod=$(kubectl get pods -n ${MONITORING_NAMESPACE} -l app=prometheus -o jsonpath="{.items[0].metadata.name}")
    local targets_status=$(kubectl exec -n ${MONITORING_NAMESPACE} ${prometheus_pod} -- curl -s http://localhost:9090/api/v1/targets)
    
    if ! echo "${targets_status}" | grep -q "\"health\":\"up\""; then
        log_error "Some Prometheus targets are not healthy"
        return 1
    }
    
    # Check Grafana
    local grafana_pod=$(kubectl get pods -n ${MONITORING_NAMESPACE} -l app=grafana -o jsonpath="{.items[0].metadata.name}")
    if ! kubectl exec -n ${MONITORING_NAMESPACE} ${grafana_pod} -- curl -s http://localhost:3000/api/health | grep -q "ok"; then
        log_error "Grafana health check failed"
        return 1
    }
    
    return 0
}

# Main function
main() {
    log_info "Starting monitoring setup..."
    
    if ! check_prerequisites; then
        log_error "Prerequisites check failed"
        exit 1
    }
    
    if ! setup_monitoring_namespace; then
        log_error "Failed to setup monitoring namespace"
        exit 1
    }
    
    if ! deploy_prometheus; then
        log_error "Failed to deploy Prometheus"
        exit 1
    }
    
    if ! deploy_grafana; then
        log_error "Failed to deploy Grafana"
        exit 1
    }
    
    if ! configure_service_monitoring; then
        log_error "Failed to configure service monitoring"
        exit 1
    }
    
    if ! verify_monitoring_stack; then
        log_error "Monitoring stack verification failed"
        exit 1
    }
    
    log_info "Monitoring setup completed successfully"
    
    # Display access information
    echo "Access Information:"
    echo "Prometheus: http://localhost:9090 (after port-forward)"
    echo "Grafana: http://localhost:3000 (after port-forward)"
    echo "Run the following commands to access the services:"
    echo "kubectl port-forward -n ${MONITORING_NAMESPACE} svc/prometheus 9090:9090"
    echo "kubectl port-forward -n ${MONITORING_NAMESPACE} svc/grafana 3000:3000"
}

# Execute main function
main "$@"