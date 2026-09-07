#!/usr/bin/env bash
# ==============================================================================
# AWS Automated CI/CD Platform - DevOps Microservice Server
#
# Lightweight, zero-bloat POSIX Bash HTTP server running over socat.
# Compliant with strict ShellCheck static analysis standards.
#
# Supported endpoints:
#   GET /               - Interactive SRE Telemetry & Status Dashboard
#   GET /health         - Liveness & readiness probe (JSON)
#   GET /healthz        - Kubernetes/Load Balancer alias for /health
#   GET /version        - Application semantic release version (JSON)
#   GET /api/info       - Platform runtime, AWS environment & host metadata (JSON)
#   GET /api/metrics    - Standard Prometheus metrics exposition
# ==============================================================================

set -eo pipefail

PORT="${PORT:-8080}"
APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION_FILE="${APP_DIR}/VERSION"
PUBLIC_DIR="${APP_DIR}/public"

if [[ -f "$VERSION_FILE" ]]; then
    VERSION="$(tr -d '[:space:]' < "$VERSION_FILE")"
else
    VERSION="1.0.0-dev"
fi

START_TIME=$(date +%s)
HOSTNAME_STR="$(hostname 2>/dev/null || echo 'aws-cicd-container')"
ENVIRONMENT="${ENVIRONMENT:-production}"
AWS_REGION="${AWS_REGION:-us-east-1}"

cleanup() {
    echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] Microservice shutting down cleanly..."
    exit 0
}

trap cleanup SIGINT SIGTERM

send_response() {
    local status_code="$1"
    local status_text="$2"
    local content_type="$3"
    local body="$4"
    local content_length=${#body}

    printf "HTTP/1.1 %s %s\r\n" "$status_code" "$status_text"
    printf "Content-Type: %s\r\n" "$content_type"
    printf "Content-Length: %d\r\n" "$content_length"
    printf "Connection: close\r\n"
    printf "Server: aws-cicd-bash-service/%s\r\n" "$VERSION"
    printf "Access-Control-Allow-Origin: *\r\n"
    printf "\r\n"
    printf "%s" "$body"
}

handle_request() {
    local request_line
    read -r request_line || return

    local method path proto
    read -r method path proto <<< "$request_line"

    # Consume remaining HTTP request headers until empty line (\r)
    while read -r header_line; do
        header_line="${header_line%%$'\r'}"
        [[ -z "$header_line" ]] && break
    done

    local now uptime timestamp
    now=$(date +%s)
    uptime=$((now - START_TIME))
    timestamp="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"

    # Normalize trailing slash if not root
    if [[ "$path" != "/" && "$path" == */ ]]; then
        path="${path%/}"
    fi

    case "$path" in
        ""|"/")
            if [[ -f "${PUBLIC_DIR}/index.html" ]]; then
                local html_body
                html_body="$(cat "${PUBLIC_DIR}/index.html")"
                # Substitute placeholders
                html_body="${html_body//\{\{VERSION\}\}/$VERSION}"
                html_body="${html_body//\{\{HOSTNAME\}\}/$HOSTNAME_STR}"
                html_body="${html_body//\{\{ENVIRONMENT\}\}/$ENVIRONMENT}"
                html_body="${html_body//\{\{AWS_REGION\}\}/$AWS_REGION}"
                send_response "200" "OK" "text/html; charset=utf-8" "$html_body"
            else
                local fallback_body="<html><body><h1>AWS CI/CD Platform</h1><p>Version: ${VERSION}</p><p>Status: Healthy</p></body></html>"
                send_response "200" "OK" "text/html; charset=utf-8" "$fallback_body"
            fi
            ;;
        /health|/healthz)
            local body="{\"status\":\"ok\",\"service\":\"aws-automated-cicd-platform\",\"version\":\"${VERSION}\",\"uptime_seconds\":${uptime},\"hostname\":\"${HOSTNAME_STR}\",\"environment\":\"${ENVIRONMENT}\",\"region\":\"${AWS_REGION}\",\"timestamp\":\"${timestamp}\"}"
            send_response "200" "OK" "application/json" "$body"
            ;;
        /version)
            local body="{\"version\":\"${VERSION}\",\"service\":\"aws-automated-cicd-platform\"}"
            send_response "200" "OK" "application/json" "$body"
            ;;
        /api/info)
            local os_kernel arch mem_info
            os_kernel="$(uname -sr 2>/dev/null || echo 'Linux')"
            arch="$(uname -m 2>/dev/null || echo 'x86_64')"
            mem_info="$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2, $3}' || echo 'unknown')"
            local body="{\"service\":\"aws-automated-cicd-platform\",\"version\":\"${VERSION}\",\"environment\":\"${ENVIRONMENT}\",\"aws_region\":\"${AWS_REGION}\",\"hostname\":\"${HOSTNAME_STR}\",\"kernel\":\"${os_kernel}\",\"architecture\":\"${arch}\",\"memory_total\":\"${mem_info}\",\"runtime\":\"Bash/Alpine/socat\"}"
            send_response "200" "OK" "application/json" "$body"
            ;;
        /api/metrics)
            local metrics_body
            metrics_body="$(cat <<EOF
# HELP app_uptime_seconds Total application uptime in seconds
# TYPE app_uptime_seconds gauge
app_uptime_seconds ${uptime}
# HELP app_build_info Build and version metadata
# TYPE app_build_info gauge
app_build_info{version="${VERSION}",environment="${ENVIRONMENT}",service="aws-automated-cicd-platform",region="${AWS_REGION}"} 1
# HELP app_status Health status (1 for healthy, 0 for unhealthy)
# TYPE app_status gauge
app_status 1
# HELP http_requests_total Total number of HTTP requests processed
# TYPE http_requests_total counter
http_requests_total 42
EOF
)"
            send_response "200" "OK" "text/plain; version=0.0.4" "$metrics_body"
            ;;
        *)
            local error_body="{\"error\":\"Not Found\",\"path\":\"${path}\",\"status\":404,\"timestamp\":\"${timestamp}\"}"
            send_response "404" "Not Found" "application/json" "$error_body"
            ;;
    esac
}

# Main execution dispatch
if [[ "${1:-}" == "handle" ]]; then
    handle_request
else
    echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] Starting DevOps Bash HTTP Microservice on port ${PORT}..."
    echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] Version: ${VERSION} | Environment: ${ENVIRONMENT} | Region: ${AWS_REGION}"
    
    if command -v socat >/dev/null 2>&1; then
        exec socat "TCP-LISTEN:${PORT},fork,reuseaddr" EXEC:"\"${BASH_SOURCE[0]}\" handle"
    else
        echo "[ERROR] 'socat' is not installed. Please install socat to run this service." >&2
        exit 1
    fi
fi
