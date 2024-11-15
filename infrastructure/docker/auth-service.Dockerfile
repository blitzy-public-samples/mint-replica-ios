# Human Tasks:
# 1. Ensure Firebase service account JSON is available during deployment
# 2. Configure JWT secret in deployment environment
# 3. Set up log volume persistence strategy
# 4. Configure container registry access
# 5. Verify network policies allow access to Firebase Auth services

# Build stage
# Base image: node:18-alpine
FROM node:18-alpine AS builder

# Set working directory
WORKDIR /app

# Copy dependency files
COPY package*.json ./

# Install dependencies
# Implements: Technical Specification/5.1 High-Level Architecture Overview
# Using npm ci for consistent, clean installs
RUN npm ci

# Copy source code and configuration
COPY tsconfig.json ./
COPY src/ ./src/
COPY config/ ./config/

# Build TypeScript application
RUN npm run build

# Prune development dependencies
RUN npm prune --production

# Production stage
# Base image: node:18-alpine
FROM node:18-alpine AS production

# Create non-root user/group
RUN addgroup -g 1000 node && \
    adduser -u 1000 -G node -s /bin/sh -D node

# Set working directory
WORKDIR /app

# Copy built application from builder stage
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/config ./config

# Set production environment
ENV NODE_ENV=production \
    PORT=8080 \
    LOG_LEVEL=INFO \
    LOG_FORMAT=JSON

# Configure security settings
# Implements: Technical Specification/8.3.4 API Authentication Flow
RUN chown -R node:node /app && \
    chmod -R 550 /app && \
    chmod -R 770 /app/logs && \
    chmod -R 660 /app/config

# Create volume mount points
VOLUME ["/app/logs", "/app/config"]

# Expose application port
EXPOSE 8080

# Health check configuration
# Implements: Technical Specification/5.1 High-Level Architecture Overview
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/healthz || exit 1

# Set security options
# Implements: Technical Specification/7.3 Security Implementation
RUN apk add --no-cache dumb-init && \
    rm -rf /var/cache/apk/*

# Drop privileges
USER node

# Use dumb-init as entry point to handle signals properly
ENTRYPOINT ["/usr/bin/dumb-init", "--"]

# Start the application
CMD ["node", "dist/server.js"]

# Build-time metadata
LABEL maintainer="Mint Replica Development Team" \
      description="Authentication service for Mint Replica Lite" \
      version="1.0.0" \
      org.opencontainers.image.source="https://github.com/mint-replica/auth-service" \
      org.opencontainers.image.vendor="Mint Replica" \
      org.opencontainers.image.title="Authentication Service" \
      org.opencontainers.image.description="Handles user authentication, session management, and token validation" \
      org.opencontainers.image.version="1.0.0" \
      org.opencontainers.image.created="2023-10-01" \
      org.opencontainers.image.documentation="https://docs.mint-replica.com/auth-service"

# Required dependencies versions:
# - firebase-admin: 11.0.0
# - express: 4.18.2
# - jsonwebtoken: 9.0.0