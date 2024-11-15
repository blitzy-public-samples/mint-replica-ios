# Implements:
# - Real-time notifications and alerts (Technical Specification/1.2 Scope/Core Features)
# - Push Notification Services (Technical Specification/5.1 High-Level Architecture Overview/External Services)

# Human Tasks:
# 1. Ensure FCM credentials file (fcm-credentials.json) is available during deployment
# 2. Verify Redis connectivity from the container network
# 3. Confirm Prometheus metrics scraping endpoints are accessible
# 4. Review security scanning results for node:18-alpine base image

# Stage 1: Dependencies
FROM node:18-alpine AS dependencies

WORKDIR /usr/src/app

# Install system dependencies
RUN apk add --no-cache \
    curl=~8.4 \
    redis-tools=~7.0

# Copy package files
COPY package*.json ./

# Install production dependencies
RUN npm ci --only=production \
    && npm cache clean --force

# Stage 2: Build
FROM node:18-alpine AS build

WORKDIR /usr/src/app

# Copy package files and installed dependencies
COPY --from=dependencies /usr/src/app/node_modules ./node_modules
COPY package*.json ./
COPY tsconfig.json ./
COPY src ./src

# Build TypeScript files
RUN npm run build \
    && npm prune --production \
    && rm -rf src tsconfig.json

# Stage 3: Final
FROM node:18-alpine

# Set working directory
WORKDIR /usr/src/app

# Install curl for health checks
RUN apk add --no-cache curl=~8.4 \
    && addgroup -g 1001 nodegroup \
    && adduser -u 1001 -G nodegroup -s /bin/sh -D nodeuser \
    && chown -R nodeuser:nodegroup /usr/src/app

# Copy built application
COPY --from=build --chown=nodeuser:nodegroup /usr/src/app/node_modules ./node_modules
COPY --from=build --chown=nodeuser:nodegroup /usr/src/app/dist ./dist

# Set environment variables
ENV NODE_ENV=production \
    PORT=8080 \
    METRICS_PORT=9090 \
    REDIS_HOST=redis.data-store.svc.cluster.local \
    REDIS_PORT=6379

# Expose ports for API and metrics
EXPOSE 8080 9090

# Switch to non-root user
USER nodeuser

# Configure read-only root filesystem
RUN chmod -R 555 /usr/src/app

# Health check configuration
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Set security options
LABEL security.capabilities.drop=all \
      security.read-only-root-filesystem=true \
      security.no-new-privileges=true

# Start the application
CMD ["node", "dist/index.js"]