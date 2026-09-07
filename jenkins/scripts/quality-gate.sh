#!/usr/bin/env bash
# ==============================================================================
# Jenkins CI Script: Code Quality Stage (SonarQube Scanner & ShellCheck)
# ==============================================================================

set -eo pipefail

echo "[QUALITY] Starting Code Quality analysis stage..."
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

mkdir -p test-results

# Generate ShellCheck report for SonarQube ingestion if shellcheck exists
if command -v shellcheck >/dev/null 2>&1; then
    echo "[QUALITY] Generating ShellCheck checkstyle report..."
    shellcheck -f checkstyle app/server.sh scripts/*.sh jenkins/scripts/*.sh > test-results/shellcheck-report.xml || true
fi

# Run SonarQube Scanner CLI
if command -v sonar-scanner >/dev/null 2>&1; then
    echo "[QUALITY] Executing SonarQube Scanner CLI..."
    sonar-scanner \
        -Dproject.settings=sonar-project.properties \
        -Dsonar.host.url="${SONAR_HOST_URL:-http://localhost:9000}"
else
    echo "[QUALITY] sonar-scanner command not found directly in PATH."
    echo "[QUALITY] Invoking SonarScanner CLI via Docker..."
    docker run --rm \
        --network="host" \
        -e SONAR_HOST_URL="${SONAR_HOST_URL:-http://localhost:9000}" \
        -e SONAR_TOKEN="${SONAR_TOKEN:-}" \
        -v "${REPO_ROOT}:/usr/src" \
        sonarsource/sonar-scanner-cli
fi

echo "[QUALITY] SonarQube scan completed. Quality gate pending evaluation..."
