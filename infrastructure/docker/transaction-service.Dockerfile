# Base image version pinned for reproducibility
# node:18-alpine - Official Node.js v18 Alpine-based image
FROM node:18-alpine AS builder

# Human Tasks:
# 1. Ensure npm registry is configured and accessible
# 2. Verify that required build secrets are configured in CI/CD pipeline
# 3. Validate that container registry permissions are set up correctly
# 4. Review security scanning results for base image vulnerabilities

# Implements:
# - Transaction Service Container (Technical Specification/5.1 High-Level Architecture Overview/Service Layer)
# - Container Orchestration (Technical Specification/5.3.4 Infrastructure)

# Set working directory for build stage
WORKDIR /app

# Copy package files first to leverage Docker layer caching
COPY package*.json ./

# Install dependencies using clean install for reproducible builds
# npm v9.x
RUN npm ci --only=production

# Copy TypeScript configuration and source code
COPY tsconfig.json ./
COPY src/ ./src/

# Build TypeScript code
RUN npm run build

# Remove development dependencies to reduce image size
RUN npm prune --production

# Start fresh with new base image for final stage
FROM node:18-alpine

# Set working directory for application
WORKDIR /app

# Copy built application from builder stage
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./

# Set environment variables
ENV NODE_ENV=production
ENV PORT=8080

# Expose port that matches Kubernetes service configuration
EXPOSE 8080/tcp

# Configure health check matching Kubernetes probe configuration
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

# Set security configurations
# Run as non-root user for security
USER node

# Define entry point
CMD ["node", "dist/index.js"]

# Apply security labels
LABEL maintainer="Mint Replica Lite Team" \
    description="Transaction Service for processing and managing financial transactions" \
    security.credentials="none" \
    version="1.0"