# Stage 1: Builder
# Implements: API Gateway Layer (Technical Specification/5.1 High-Level Architecture Overview)
FROM node:18-alpine AS builder

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install production dependencies
# Using npm version 9.6.7 (comes with node:18-alpine)
RUN npm ci --only=production

# Copy source code
COPY src/ ./src/
COPY tsconfig.json ./

# Build application
RUN npm run build

# Stage 2: Production
# Implements: Service Integration (Technical Specification/7.3.1 Service Integration Architecture)
FROM nginx:1.25-alpine

# Create non-root user
RUN addgroup -g 101 -S nginx && \
    adduser -S -D -H -u 101 -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx

# Install required runtime dependencies
RUN apk add --no-cache \
    nodejs~=18 \
    npm~=9 \
    curl~=8

# Set working directory
WORKDIR /app

# Copy built application from builder stage
COPY --from=builder --chown=nginx:nginx /app/dist ./dist
COPY --from=builder --chown=nginx:nginx /app/node_modules ./node_modules

# Copy nginx configuration
COPY infrastructure/nginx/api-gateway.conf /etc/nginx/conf.d/default.conf

# Create required directories with correct permissions
RUN mkdir -p /app/logs /app/config && \
    chown -R nginx:nginx /app/logs /app/config /var/cache/nginx /var/log/nginx

# Configure security settings
RUN chmod 755 /app && \
    chmod -R 644 /app/dist && \
    chmod -R 644 /app/node_modules && \
    chmod 755 $(find /app/node_modules -type d) && \
    chmod -R 644 /etc/nginx/conf.d && \
    rm -rf /var/www/* && \
    touch /var/run/nginx.pid && \
    chown -R nginx:nginx /var/run/nginx.pid

# Set environment variables
ENV NODE_ENV=production \
    PORT=8080 \
    SECURE_PORT=8443 \
    RATE_LIMIT_WINDOW=60000 \
    RATE_LIMIT_MAX_REQUESTS=100

# Expose ports for HTTP, HTTPS, and Prometheus metrics
EXPOSE 8080 8443 9102

# Set up health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/healthz || exit 1

# Switch to non-root user
USER nginx

# Set security options
RUN nginx -t

# Configure read-only root filesystem
VOLUME ["/app/logs", "/app/config"]

# Set entry point
CMD ["nginx", "-g", "daemon off;"]

# Add metadata labels
LABEL maintainer="Mint Replica Development Team" \
      version="1.0.0" \
      description="API Gateway service for Mint Replica Lite" \
      org.opencontainers.image.source="https://github.com/mint-replica/api-gateway" \
      org.opencontainers.image.vendor="Mint Replica" \
      org.opencontainers.image.title="API Gateway" \
      org.opencontainers.image.description="API Gateway service for routing and managing requests" \
      org.opencontainers.image.version="1.0.0" \
      org.opencontainers.image.created="2023-07-20"