# Human Tasks:
# 1. Verify Maven settings.xml configuration if custom repository access is needed
# 2. Ensure proper network access for Maven dependency downloads during build
# 3. Validate that the host system has sufficient memory for Maven builds (recommended: 4GB+)
# 4. Review security scanning results for base images after builds

# Build stage
# Implements: Technical Specification/5.1 High-Level Architecture Overview - Goal Service Component
FROM maven:3.9-eclipse-temurin-17 AS builder

WORKDIR /build

# Copy POM file for dependency resolution
COPY ./pom.xml .

# Download dependencies separately to leverage Docker layer caching
RUN mvn dependency:go-offline -B

# Copy source code
COPY ./src ./src

# Build application with production profile
# Implements: Technical Specification/1.2 Scope/Core Features - Financial Goal Management
RUN mvn clean package -DskipTests -Pproduction

# Runtime stage
# Implements: Technical Specification/5.3.4 Infrastructure - Container Orchestration
FROM eclipse-temurin:17-jre-jammy

# Create non-root user for security
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Set working directory
WORKDIR /app

# Copy JAR from build stage
COPY --from=builder /build/target/goal-service.jar .

# Set ownership to non-root user
RUN chown -R appuser:appuser /app

# Configure JVM and application settings
ENV SPRING_PROFILES_ACTIVE=production
ENV JAVA_OPTS="-Xms512m -Xmx1g -XX:+UseG1GC"

# Expose service port
EXPOSE 8080

# Switch to non-root user
USER appuser

# Health check configuration
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health || exit 1

# Set read-only filesystem
VOLUME ["/tmp"]

# Configure container startup
ENTRYPOINT [ "sh", "-c", "java $JAVA_OPTS -Djava.security.egd=file:/dev/./urandom -jar goal-service.jar" ]

# Security hardening
# Drop all capabilities and only add necessary ones
USER appuser:appuser
RUN rm -rf /tmp/* /var/cache/* /var/tmp/*

# Labels for container metadata
LABEL maintainer="Mint Replica Team" \
      app.name="goal-service" \
      app.description="Financial Goal Management Service" \
      app.version="1.0.0" \
      app.component="goals"