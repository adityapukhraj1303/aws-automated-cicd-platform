#!/usr/bin/env bash
# ==============================================================================
# Jenkins CI Script: Deployment Stage
#
# 1. Authenticate with AWS ECR & Push Docker Images
# 2. Package & Archive Build Artifacts to Versioned S3 Bucket
# 3. Trigger Zero-Downtime ECS Fargate Service Rollout
# 4. Wait for ECS Service Stability
# ==============================================================================

set -eo pipefail

echo "[DEPLOY] ============================================================"
echo "[DEPLOY] Starting AWS Production Deployment"
echo "[DEPLOY] ============================================================"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-east-1}"
ECR_REPO_NAME="${ECR_REPO_NAME:-aws-cicd-platform-app}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
ECS_CLUSTER_NAME="${ECS_CLUSTER_NAME:-aws-cicd-platform-cluster}"
ECS_SERVICE_NAME="${ECS_SERVICE_NAME:-aws-cicd-platform-service}"
S3_ARTIFACT_BUCKET="${S3_ARTIFACT_BUCKET:-}"

# Derive AWS Account ID if not pre-set
if [[ -z "${AWS_ACCOUNT_ID:-}" ]]; then
    AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
fi

ECR_REGISTRY_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com"
FULL_IMAGE_NAME="${ECR_REGISTRY_URI}/${ECR_REPO_NAME}"

echo "[DEPLOY] AWS Region:      ${AWS_DEFAULT_REGION}"
echo "[DEPLOY] AWS Account ID:  ${AWS_ACCOUNT_ID}"
echo "[DEPLOY] ECR Registry:    ${ECR_REGISTRY_URI}"
echo "[DEPLOY] Target Image:    ${FULL_IMAGE_NAME}:${IMAGE_TAG}"
echo "[DEPLOY] ECS Cluster:     ${ECS_CLUSTER_NAME}"
echo "[DEPLOY] ECS Service:     ${ECS_SERVICE_NAME}"
echo "[DEPLOY] S3 Bucket:       ${S3_ARTIFACT_BUCKET}"

# ── 1. AWS ECR Authentication & Image Push ────────────────────────────────────
echo "[DEPLOY] [1/4] Authenticating with AWS ECR..."
aws ecr get-login-password --region "${AWS_DEFAULT_REGION}" | \
    docker login --username AWS --password-stdin "${ECR_REGISTRY_URI}"

echo "[DEPLOY] [2/4] Tagging and pushing Docker images to ECR..."
docker tag "${FULL_IMAGE_NAME}:${IMAGE_TAG}" "${FULL_IMAGE_NAME}:latest" || true

docker push "${FULL_IMAGE_NAME}:${IMAGE_TAG}"
docker push "${FULL_IMAGE_NAME}:latest"
echo "[DEPLOY] Successfully pushed images to ECR."

# ── 2. Package & Archive Build Artifacts to S3 ────────────────────────────────
if [[ -n "${S3_ARTIFACT_BUCKET}" ]]; then
    echo "[DEPLOY] [3/4] Archiving release bundle to S3 (${S3_ARTIFACT_BUCKET})..."
    ARTIFACT_TAR="build-artifact-${IMAGE_TAG}.tar.gz"
    
    tar -czf "${ARTIFACT_TAR}" \
        app/ \
        docker/ \
        tests/ \
        artifacts/ \
        sonar-project.properties

    aws s3 cp "${ARTIFACT_TAR}" \
        "s3://${S3_ARTIFACT_BUCKET}/builds/${IMAGE_TAG}/${ARTIFACT_TAR}" \
        --metadata "commit=${IMAGE_TAG},service=aws-automated-cicd-platform"

    aws s3 cp "${ARTIFACT_TAR}" \
        "s3://${S3_ARTIFACT_BUCKET}/latest/build-artifact-latest.tar.gz"

    rm -f "${ARTIFACT_TAR}"
    echo "[DEPLOY] Artifacts uploaded successfully to S3."
else
    echo "[DEPLOY] [3/4] S3_ARTIFACT_BUCKET variable not set. Skipping S3 upload."
fi

# ── 3. Trigger ECS Fargate Service Deployment ─────────────────────────────────
echo "[DEPLOY] [4/4] Triggering zero-downtime rolling update on ECS Fargate..."
aws ecs update-service \
    --cluster "${ECS_CLUSTER_NAME}" \
    --service "${ECS_SERVICE_NAME}" \
    --force-new-deployment \
    --region "${AWS_DEFAULT_REGION}" > /dev/null

echo "[DEPLOY] Waiting for ECS service to reach steady state..."
aws ecs wait services-stable \
    --cluster "${ECS_CLUSTER_NAME}" \
    --services "${ECS_SERVICE_NAME}" \
    --region "${AWS_DEFAULT_REGION}"

echo "[DEPLOY] ============================================================"
echo "[DEPLOY] Deployment Complete & ECS Tasks Healthy!"
echo "[DEPLOY] ============================================================"
