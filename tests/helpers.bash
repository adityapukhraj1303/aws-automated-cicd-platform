#!/usr/bin/env bash
# ==============================================================================
# Bats Test Helpers for AWS CI/CD Platform Microservice
# ==============================================================================

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_SERVER="${REPO_ROOT}/app/server.sh"

send_mock_http_request() {
    local method="${1:-GET}"
    local path="${2:-/health}"
    local proto="${3:-HTTP/1.1}"

    printf "%s %s %s\r\nHost: localhost\r\nUser-Agent: Bats-Test\r\n\r\n" "$method" "$path" "$proto" | bash "$APP_SERVER" handle
}

extract_http_status() {
    echo "$1" | head -n 1 | awk '{print $2}'
}

extract_http_body() {
    echo "$1" | sed '1,/^\r\{0,1\}$/d'
}
