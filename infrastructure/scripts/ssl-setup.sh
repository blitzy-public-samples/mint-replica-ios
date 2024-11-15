#!/bin/bash

# Human Tasks:
# 1. Configure AWS CLI with appropriate credentials and permissions
# 2. Set AWS_REGION environment variable before running the script
# 3. Ensure Route53 hosted zone exists for the domain
# 4. Verify domain ownership and DNS nameserver configuration
# 5. Monitor certificate validation in AWS Console after script execution

# Required tool versions:
# aws-cli v2.0.0+
# jq v1.6+

# Set strict error handling
set -euo pipefail

# Script constants
readonly TIMEOUT_SECONDS=3600
readonly LOG_FILE="/var/log/ssl-setup.log"

# Logging function
log() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] $1" | tee -a "${LOG_FILE}"
}

# Check prerequisites for SSL certificate setup
# Requirement: Infrastructure Security - AWS specified as the infrastructure provider
check_prerequisites() {
    log "Checking prerequisites..."

    # Verify AWS CLI installation and version
    if ! command -v aws >/dev/null 2>&1; then
        log "ERROR: AWS CLI not found. Please install AWS CLI v2.0.0 or higher"
        return 1
    fi
    
    local aws_version
    aws_version=$(aws --version | cut -d/ -f2 | cut -d. -f1)
    if [[ ${aws_version} -lt 2 ]]; then
        log "ERROR: AWS CLI version 2.0.0+ required"
        return 1
    }

    # Check jq installation
    if ! command -v jq >/dev/null 2>&1; then
        log "ERROR: jq not found. Please install jq v1.6 or higher"
        return 1
    }

    # Verify AWS credentials
    if ! aws sts get-caller-identity >/dev/null 2>&1; then
        log "ERROR: AWS credentials not configured or invalid"
        return 1
    }

    # Check AWS_REGION
    if [[ -z "${AWS_REGION:-}" ]]; then
        log "ERROR: AWS_REGION environment variable not set"
        return 1
    }

    # Verify ACM and Route53 permissions
    if ! aws acm list-certificates >/dev/null 2>&1; then
        log "ERROR: Insufficient permissions for ACM"
        return 1
    }

    if ! aws route53 list-hosted-zones >/dev/null 2>&1; then
        log "ERROR: Insufficient permissions for Route53"
        return 1
    }

    log "Prerequisites check completed successfully"
    return 0
}

# Request SSL/TLS certificate from ACM
# Requirement: System Security - Implementation of secure communication channels
request_certificate() {
    local domain_name=$1
    local hosted_zone_id=$2

    log "Requesting certificate for domain: ${domain_name}"

    local certificate_arn
    certificate_arn=$(aws acm request-certificate \
        --domain-name "${domain_name}" \
        --validation-method DNS \
        --tags Key=Application,Value=MintReplicaLite Key=ManagedBy,Value=Script \
        --region "${AWS_REGION}" \
        --output text)

    if [[ -z "${certificate_arn}" ]]; then
        log "ERROR: Failed to request certificate"
        return 1
    }

    log "Certificate requested successfully. ARN: ${certificate_arn}"
    echo "${certificate_arn}"
}

# Setup DNS validation records in Route53
setup_dns_validation() {
    local certificate_arn=$1
    local hosted_zone_id=$2

    log "Setting up DNS validation records..."

    # Get validation records from certificate
    local validation_records
    validation_records=$(aws acm describe-certificate \
        --certificate-arn "${certificate_arn}" \
        --region "${AWS_REGION}" \
        --query 'Certificate.DomainValidationOptions[].ResourceRecord')

    if [[ -z "${validation_records}" ]]; then
        log "ERROR: No validation records found"
        return 1
    }

    # Create validation records in Route53
    local record_name
    local record_value
    record_name=$(echo "${validation_records}" | jq -r '.[0].Name')
    record_value=$(echo "${validation_records}" | jq -r '.[0].Value')

    aws route53 change-resource-record-sets \
        --hosted-zone-id "${hosted_zone_id}" \
        --change-batch "{
            \"Changes\": [{
                \"Action\": \"UPSERT\",
                \"ResourceRecordSet\": {
                    \"Name\": \"${record_name}\",
                    \"Type\": \"CNAME\",
                    \"TTL\": 300,
                    \"ResourceRecords\": [{
                        \"Value\": \"${record_value}\"
                    }]
                }
            }]
        }"

    log "DNS validation records created successfully"
    return 0
}

# Wait for certificate validation to complete
wait_for_validation() {
    local certificate_arn=$1
    local start_time
    start_time=$(date +%s)

    log "Waiting for certificate validation..."

    while true; do
        local status
        status=$(aws acm describe-certificate \
            --certificate-arn "${certificate_arn}" \
            --region "${AWS_REGION}" \
            --query 'Certificate.Status' \
            --output text)

        if [[ "${status}" == "ISSUED" ]]; then
            log "Certificate validated successfully"
            return 0
        elif [[ "${status}" == "FAILED" ]]; then
            log "ERROR: Certificate validation failed"
            return 1
        fi

        local current_time
        current_time=$(date +%s)
        if (( current_time - start_time >= TIMEOUT_SECONDS )); then
            log "ERROR: Certificate validation timed out"
            return 1
        fi

        sleep 30
    done
}

# Cleanup DNS validation records
cleanup_validation_records() {
    local hosted_zone_id=$1

    log "Cleaning up DNS validation records..."

    # List validation records
    local validation_records
    validation_records=$(aws route53 list-resource-record-sets \
        --hosted-zone-id "${hosted_zone_id}" \
        --query "ResourceRecordSets[?Type=='CNAME']")

    # Remove validation records
    for record in $(echo "${validation_records}" | jq -c '.[]'); do
        local record_name
        record_name=$(echo "${record}" | jq -r '.Name')
        if [[ "${record_name}" == *"acm-validations"* ]]; then
            aws route53 change-resource-record-sets \
                --hosted-zone-id "${hosted_zone_id}" \
                --change-batch "{
                    \"Changes\": [{
                        \"Action\": \"DELETE\",
                        \"ResourceRecordSet\": ${record}
                    }]
                }"
        fi
    done

    log "DNS validation records cleaned up successfully"
    return 0
}

# Main execution
main() {
    if [[ $# -ne 2 ]]; then
        echo "Usage: $0 <domain_name> <hosted_zone_id>"
        exit 1
    }

    local domain_name=$1
    local hosted_zone_id=$2

    # Initialize log file
    mkdir -p "$(dirname "${LOG_FILE}")"
    touch "${LOG_FILE}"
    log "Starting SSL certificate setup for ${domain_name}"

    # Execute setup process
    if ! check_prerequisites; then
        log "Prerequisites check failed"
        exit 1
    fi

    local certificate_arn
    certificate_arn=$(request_certificate "${domain_name}" "${hosted_zone_id}")
    if [[ $? -ne 0 ]]; then
        log "Certificate request failed"
        exit 1
    fi

    if ! setup_dns_validation "${certificate_arn}" "${hosted_zone_id}"; then
        log "DNS validation setup failed"
        exit 1
    fi

    if ! wait_for_validation "${certificate_arn}"; then
        log "Certificate validation failed"
        exit 1
    fi

    if ! cleanup_validation_records "${hosted_zone_id}"; then
        log "Validation record cleanup failed"
        exit 1
    fi

    log "SSL certificate setup completed successfully"
    exit 0
}

# Execute main function with provided arguments
main "$@"