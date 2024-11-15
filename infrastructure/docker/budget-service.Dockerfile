# Stage 1: Builder stage
# Using Maven 3.9 with Eclipse Temurin JDK 17 for building the application
FROM maven:3.9-eclipse-temurin-17 AS builder

# Set working directory
WORKDIR /build

# Copy Maven configuration first to cache dependencies
COPY pom.xml .
COPY .mvn/ .mvn/

# Download dependencies (this layer will be cached)
RUN mvn dependency:go-offline -B

# Copy source code
COPY src/ src/

# Build application with production profile
# Implements requirement: Budget Service Component (Technical Specification/5.1 High-Level Architecture Overview)
RUN mvn clean package -DskipTests -Pprod \
    && mkdir -p target/dependency \
    && (cd target/dependency; jar -xf ../*.jar)

# Stage 2: Production stage
# Using Eclipse Temurin JRE 17 Alpine for minimal runtime footprint
FROM eclipse-temurin:17-jre-alpine

# Add labels for better maintainability
LABEL maintainer="MintReplicaLite Team" \
      description="Budget Service for MintReplicaLite" \
      version="1.0"

# Create non-root user/group
# Implements security requirements from Technical Specification
RUN addgroup -g 1000 spring && \
    adduser -u 1000 -G spring -s /bin/sh -D spring

# Create necessary directories with proper permissions
RUN mkdir -p /app/logs /app/config && \
    chown -R spring:spring /app && \
    chmod -R 755 /app

# Set working directory
WORKDIR /app

# Copy application artifacts from builder stage
COPY --from=builder --chown=spring:spring /build/target/dependency/BOOT-INF/lib /app/lib
COPY --from=builder --chown=spring:spring /build/target/dependency/META-INF /app/META-INF
COPY --from=builder --chown=spring:spring /build/target/dependency/BOOT-INF/classes /app

# Configure environment variables
# Implements requirement: Budget Management (Technical Specification/1.1 System Overview/Core Features)
ENV SPRING_PROFILES_ACTIVE=production \
    SERVER_PORT=8080 \
    JVM_OPTS="-Xms256m -Xmx512m -XX:+UseG1GC -XX:+UseContainerSupport"

# Expose service port
EXPOSE 8080

# Configure health check
# Implements monitoring requirements from Technical Specification
HEALTHCHECK --interval=30s --timeout=10s --retries=3 --start-period=30s \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/healthz || exit 1

# Set security options
# Implements requirement: Infrastructure Technology (Technical Specification/5.3 Technology Stack/5.3.4 Infrastructure)
RUN apk add --no-cache dumb-init

# Drop all capabilities and only add required ones
USER spring:spring

# Use dumb-init as entry point to handle signals properly
ENTRYPOINT ["dumb-init", "--"]

# Start the application with proper configuration
CMD ["sh", "-c", "java $JVM_OPTS \
    -XX:+ExitOnOutOfMemoryError \
    -XX:MaxRAMPercentage=75.0 \
    -Djava.security.egd=file:/dev/./urandom \
    -Dserver.port=$SERVER_PORT \
    -Dspring.profiles.active=$SPRING_PROFILES_ACTIVE \
    -Dmanagement.endpoints.web.exposure.include=health,prometheus,metrics \
    -Dmanagement.endpoint.health.probes.enabled=true \
    -Dmanagement.health.livenessState.enabled=true \
    -Dmanagement.health.readinessState.enabled=true \
    org.springframework.boot.loader.JarLauncher"]

# Security hardening
# No new privileges
# Read-only root filesystem
# Non-root user execution
# These are enforced through Kubernetes security context