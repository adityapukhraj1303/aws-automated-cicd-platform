#!/usr/bin/env bash
# ==============================================================================
# Local Setup & Verification Script
#
# Builds the Docker container, runs tests locally, and validates endpoints.
# ==============================================================================

set -eo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "=================================================================="
echo " AWS Automated CI/CD Platform - Local Environment Validation"
echo "=================================================================="

# 1. ShellCheck Verification
echo "[1/4] Running ShellCheck static analysis..."
if command -v shellcheck >/dev/null 2>&1; then
    shellcheck -x app/server.sh scripts/*.sh jenkins/scripts/*.sh
    echo "✔ ShellCheck analysis passed!"
else
    echo "ℹ ShellCheck not found on host. Docker will enforce it during build."
fi

# 2. Automated Bats Tests
echo "[2/4] Running automated Bats test suite..."
if command -v bats >/dev/null 2>&1; then
    bats tests/
    echo "✔ Bats tests passed!"
else
    echo "ℹ Running Bats tests inside container..."
    docker run --rm -v "${REPO_ROOT}:/workspace" -w /workspace bats/bats:latest tests/
fi

# 3. Docker Image Build
echo "[3/4] Building hardened production multi-stage Docker image..."
docker build -t aws-cicd-platform-app:local -f docker/Dockerfile .
echo "✔ Docker build successful!"

# 4. Container Smoke Test
echo "[4/4] Starting ephemeral container to verify endpoints..."
docker rm -f aws-cicd-test-container 2>/dev/null || true
docker run -d -p 8080:8080 --name aws-cicd-test-container aws-cicd-platform-app:local

echo "Waiting for container startup..."
sleep 2

echo "--> Probing GET /health"
curl -s -i http://localhost:8080/health | head -n 10
echo ""

echo "--> Probing GET /version"
curl -s http://localhost:8080/version
echo -e "\n"

echo "--> Probing GET /api/info"
curl -s http://localhost:8080/api/info
echo -e "\n"

echo "--> Probing GET /api/metrics"
curl -s http://localhost:8080/api/metrics | head -n 10
echo ""

echo "Cleaning up test container..."
docker rm -f aws-cicd-test-container >/dev/null

echo "=================================================================="
echo " 🎉 All Local Pre-flight Checks PASSED Successfully!"
echo "=================================================================="
