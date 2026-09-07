# ==============================================================================
# AWS Automated CI/CD Platform - Multi-Stage Hardened Dockerfile
#
# Stage 1: Static Code Analysis & ShellCheck Linting
# Stage 2: Minimal, Hardened Alpine Production Runtime (Non-root user)
# ==============================================================================

# ── Stage 1: Quality Gate & Static Analysis ───────────────────────────────────
FROM koalaman/shellcheck:stable AS linter

WORKDIR /workspace
COPY app/ /workspace/app/
RUN shellcheck -x /workspace/app/server.sh

# ── Stage 2: Production Minimal Alpine Runtime ────────────────────────────────
FROM alpine:3.19 AS runner

LABEL maintainer="Aditya Pukhraj <https://github.com/adityapukhraj1303>"
LABEL description="AWS Automated CI/CD Platform - Zero-Bloat DevOps Microservice"
LABEL org.opencontainers.image.source="https://github.com/adityapukhraj1303/aws-automated-cicd-platform"

# Install minimal required utilities
RUN apk add --no-cache \
    bash=~5.2 \
    socat=~1.8 \
    curl=~8.5 \
    jq=~1.7 \
    coreutils \
    tzdata && \
    rm -rf /var/cache/apk/*

# Security Hardening: Create non-root unprivileged devops user and group
ENV APP_USER=devops \
    APP_UID=10001 \
    APP_GID=10001 \
    APP_DIR=/opt/app \
    PORT=8080 \
    ENVIRONMENT=production \
    AWS_REGION=ap-south-1

RUN addgroup -g ${APP_GID} ${APP_USER} && \
    adduser -u ${APP_UID} -G ${APP_USER} -h ${APP_DIR} -s /bin/bash -D ${APP_USER}

WORKDIR ${APP_DIR}

# Copy application files with appropriate permissions
COPY --chown=${APP_USER}:${APP_USER} app/ ${APP_DIR}/

RUN chmod +x ${APP_DIR}/server.sh

# Switch to non-root user
USER ${APP_UID}:${APP_GID}

EXPOSE 8080

# Production Healthcheck for ECS / ALB / Docker swarm
HEALTHCHECK --interval=15s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

ENTRYPOINT ["/opt/app/server.sh"]
