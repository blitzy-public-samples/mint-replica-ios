# Human Tasks:
# 1. Verify Node.js source code is available in the build context
# 2. Ensure package.json and package-lock.json are up to date
# 3. Verify Redis and PostgreSQL connection environment variables are configured in deployment
# 4. Review security scanning results for node:18-alpine base image
# 5. Validate memory and CPU limits are sufficient for production workload

# Implements:
# - Investment Portfolio Tracking (Technical Specification/1.1 System Overview/Core Features)
# - Container Orchestration (Technical Specification/5.3.4 Infrastructure)
# - Monitoring (Technical Specification/5.3.4 Infrastructure)

# Stage 1: Builder
FROM node:18-alpine AS builder

# Set working directory
WORKDIR /app

# Copy dependency files
COPY package*.json ./

# Install production dependencies
# Using npm ci for consistent installs
RUN npm ci --only=production

# Copy source code and TypeScript config
COPY . .

# Build TypeScript application
RUN npm run build

# Prune development dependencies
RUN npm prune --production

# Stage 2: Final
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Create non-root user and group
RUN addgroup -S nodegroup && adduser -S node -G nodegroup

# Copy built application from builder stage
COPY --from=builder --chown=node:nodegroup /app/dist ./dist
COPY --from=builder --chown=node:nodegroup /app/node_modules ./node_modules
COPY --from=builder --chown=node:nodegroup /app/package.json ./package.json

# Set correct permissions
RUN chmod -R 550 /app && \
    chmod -R 550 /app/dist && \
    chmod -R 550 /app/node_modules

# Container metadata
LABEL maintainer="Mint Replica Lite Team" \
      service="investment-service" \
      version="1.0.0"

# Expose service port
EXPOSE 8080/tcp

# Configure health check
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

# Environment variables
ENV NODE_ENV=production \
    PORT=8080

# Security configurations
USER node
WORKDIR /app

# Set security options
SECURITY_OPTS --cap-drop=ALL \
              --read-only \
              --memory=512m \
              --cpus=0.5

# Define entry point
ENTRYPOINT ["node", "dist/main.js"]