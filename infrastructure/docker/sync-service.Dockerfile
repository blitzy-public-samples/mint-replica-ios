# Stage 1: Builder
# Using Node.js 18 Alpine as base image for build stage
FROM node:18-alpine AS builder

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install build dependencies including TypeScript
# Note: Explicitly installing TypeScript and required build tools
RUN apk add --no-cache python3 make g++ \
    && npm ci \
    && npm install typescript@4.9.5 @types/node@18

# Copy TypeScript configuration and source code
COPY tsconfig.json ./
COPY src/ ./src/

# Build TypeScript code
RUN npm run build

# Prune dev dependencies
RUN npm prune --production

# Stage 2: Production
# Using Node.js 18 Alpine as base image for production
FROM node:18-alpine

# Create app directory and set ownership
WORKDIR /app

# Create non-root user/group
RUN addgroup -g 1000 node && \
    adduser -u 1000 -G node -s /bin/sh -D node

# Install production dependencies
COPY package*.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist

# Create volume mount points with correct permissions
RUN mkdir -p /app/logs /app/config && \
    chown -R node:node /app/logs /app/config

# Install required runtime dependencies for Plaid, Redis, Bull, and Prometheus
# plaid@12.0.0, redis@4.6.7, bull@4.10.4, prom-client@14.2.0
RUN apk add --no-cache tini tzdata

# Configure security settings
RUN apk add --no-cache libcap && \
    setcap 'cap_net_bind_service=+ep' $(which node) && \
    apk del libcap

# Set environment variables
ENV NODE_ENV=production \
    PORT=8080 \
    METRICS_PORT=9090

# Expose ports for API and metrics
EXPOSE 8080 9090

# Set up healthcheck
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

# Security configurations
USER node
WORKDIR /app

# Set security options
LABEL security.capabilities="NET_BIND_SERVICE" \
      security.read-only-root-fs="true" \
      security.no-new-privileges="true"

# Use tini as init system
ENTRYPOINT ["/sbin/tini", "--"]

# Start the application
CMD ["node", "dist/index.js"]

# Security labels for container runtime
LABEL org.opencontainers.image.source="https://github.com/yourusername/mint-mobile" \
      org.opencontainers.image.description="Data synchronization service for Mint Mobile" \
      org.opencontainers.image.version="1.0.0" \
      org.opencontainers.image.vendor="Mint Mobile" \
      org.opencontainers.image.licenses="Private" \
      org.opencontainers.image.created="2023-10-20"

# Required environment variables that must be provided at runtime:
# - REDIS_URL: Redis connection URL
# - PLAID_CLIENT_ID: Plaid API client ID
# - PLAID_SECRET: Plaid API secret key
# - PLAID_ENV: Plaid environment (sandbox/development/production)