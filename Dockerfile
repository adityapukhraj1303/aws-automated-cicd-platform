# ==============================================================================
# AWS Automated CI/CD Platform - Hardened Lightweight Web Container
# Base Image: Alpine Linux with Nginx
# ==============================================================================

FROM nginx:alpine

LABEL maintainer="Aditya Pukhraj <https://github.com/adityapukhraj1303>"
LABEL description="AWS Automated CI/CD Platform - High Performance Cloud Web Dashboard"
LABEL org.opencontainers.image.source="https://github.com/adityapukhraj1303/aws-automated-cicd-platform"

# Remove default nginx welcome page
RUN rm -rf /usr/share/nginx/html/*

# Copy web application assets
COPY index.html /usr/share/nginx/html/index.html
COPY style.css /usr/share/nginx/html/style.css

# Configure permissions
RUN chmod 644 /usr/share/nginx/html/index.html /usr/share/nginx/html/style.css

# Port 80 for HTTP traffic
EXPOSE 80

# Production Healthcheck for AWS ECS / ALB / Docker runtime
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:80/ || exit 1

# Start Nginx in foreground
CMD ["nginx", "-g", "daemon off;"]
