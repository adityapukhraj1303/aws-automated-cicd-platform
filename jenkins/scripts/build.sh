#!/usr/bin/env bash
# ==============================================================================
# Jenkins CI Script: Build Stage
# ==============================================================================

set -eo pipefail

echo "[BUILD] Starting build stage..."
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

IMAGE_TAG="${IMAGE_TAG:-latest}"
ECR_REPO_NAME="${ECR_REPO_NAME:-aws-cicd-platform-app}"
REGISTRY_URI="${ECR_REGISTRY_URI:-localhost}"
FULL_IMAGE_NAME="${REGISTRY_URI}/${ECR_REPO_NAME}"

echo "[BUILD] Repository root: ${REPO_ROOT}"
echo "[BUILD] Target Image: ${FULL_IMAGE_NAME}:${IMAGE_TAG}"

# Step 1: Pre-build ShellCheck Linting
if command -v shellcheck >/dev/null 2>&1; then
    echo "[BUILD] Running ShellCheck static analysis..."
    shellcheck -x app/server.sh scripts/*.sh jenkins/scripts/*.sh
    echo "[BUILD] ShellCheck passed with zero warnings!"
else
    echo "[BUILD] ShellCheck not installed locally, Docker multi-stage build will enforce it."
fi

# Step 2: Build Multi-Stage Docker Image
echo "[BUILD] Building production-ready multi-stage Docker image..."
docker build \
    --file docker/Dockerfile \
    --tag "${FULL_IMAGE_NAME}:${IMAGE_TAG}" \
    --tag "${FULL_IMAGE_NAME}:latest" \
    --tag "aws-cicd-platform-app:${IMAGE_TAG}" \
    .

echo "[BUILD] Docker image built successfully:"
docker images | grep "${ECR_REPO_NAME}" || true

echo "[BUILD] Build stage completed successfully."
