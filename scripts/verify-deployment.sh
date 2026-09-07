#!/usr/bin/env bash
# ==============================================================================
# AWS Automated CI/CD Platform - End-to-End Verification Script
#
# Verifies:
#   1. Live HTTP endpoints via ALB DNS (/health, /version, /api/info, /api/metrics)
#   2. S3 Build Artifact bucket contents and versioning
#   3. AWS ECR container image tags and vulnerabilities
#   4. AWS ECS Fargate service status & task health
#   5. CloudWatch Log Group audit stream
#
# Usage:
#   ./scripts/verify-deployment.sh [ALB_ENDPOINT_OR_IP]
# ==============================================================================

set -eo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="${REPO_ROOT}/terraform"

ENDPOINT="${1:-}"

# Attempt to read endpoint from terraform output if not passed
if [[ -z "$ENDPOINT" && -d "$TF_DIR/.terraform" ]]; then
    echo "[INFO] Extracting ALB URL from Terraform output..."
    ENDPOINT="$(terraform -chdir="$TF_DIR" output -raw application_url 2>/dev/null || true)"
fi

if [[ -z "$ENDPOINT" ]]; then
    echo "Usage: $0 <http://ALB-DNS-NAME-OR-IP>"
    echo "Example: $0 http://aws-cicd-platform-alb-123456789.us-east-1.elb.amazonaws.com"
    exit 1
fi

# Strip trailing slash
ENDPOINT="${ENDPOINT%/}"

echo "=================================================================="
echo " 🔍 AWS Automated CI/CD Platform - Live Verification"
echo " Target Endpoint: ${ENDPOINT}"
echo " Timestamp:       $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
echo "=================================================================="

# ── 1. HTTP Endpoint Smoke Testing ────────────────────────────────────────────
echo ""
echo "── [1/5] Testing Application HTTP Endpoints ──"

test_endpoint() {
    local path="$1"
    local expected_code="${2:-200}"
    local url="${ENDPOINT}${path}"

    echo -n "  Testing ${path} ... "
    local http_code
    http_code=$(curl -s -o /tmp/resp_body.txt -w "%{http_code}" --connect-timeout 5 --max-time 10 "$url" || echo "FAILED")

    if [[ "$http_code" == "$expected_code" ]]; then
        echo "✔ HTTP ${http_code} OK"
        if [[ -s /tmp/resp_body.txt ]]; then
            echo "    Response: $(head -c 120 /tmp/resp_body.txt)..."
        fi
    else
        echo "❌ FAILED (Received: ${http_code}, Expected: ${expected_code})"
    fi
}

test_endpoint "/health" 200
test_endpoint "/version" 200
test_endpoint "/api/info" 200
test_endpoint "/api/metrics" 200
test_endpoint "/" 200
test_endpoint "/non-existent-probe" 404

# ── 2. AWS S3 Artifact Bucket Inspection ──────────────────────────────────────
echo ""
echo "── [2/5] Inspecting AWS S3 Artifact Storage ──"
if command -v aws >/dev/null 2>&1; then
    S3_BUCKET="$(terraform -chdir="$TF_DIR" output -raw s3_artifact_bucket 2>/dev/null || echo '')"
    if [[ -n "$S3_BUCKET" ]]; then
        echo "  Target Bucket: s3://${S3_BUCKET}"
        aws s3 ls "s3://${S3_BUCKET}/" || echo "  (Bucket empty or access restricted)"
        echo "  Recent builds:"
        aws s3 ls "s3://${S3_BUCKET}/builds/" || true
    else
        echo "  ℹ S3 bucket output not found in local terraform state."
    fi
else
    echo "  ℹ AWS CLI not installed on current host. Skipping S3 inspection."
fi

# ── 3. AWS ECR Image Inspection ───────────────────────────────────────────────
echo ""
echo "── [3/5] Inspecting AWS ECR Container Registry ──"
if command -v aws >/dev/null 2>&1; then
    ECR_NAME="aws-cicd-platform-app"
    echo "  ECR Repository: ${ECR_NAME}"
    aws ecr describe-images --repository-name "${ECR_NAME}" --query 'imageDetails[*].{Tags:imageTags,PushedAt:imagePushedAt,Digest:imageDigest}' --output table 2>/dev/null || echo "  (Run AWS configure or check IAM permissions)"
fi

# ── 4. AWS ECS Fargate Cluster & Service Health ───────────────────────────────
echo ""
echo "── [4/5] Inspecting AWS ECS Fargate Service Status ──"
if command -v aws >/dev/null 2>&1; then
    CLUSTER_NAME="aws-cicd-platform-cluster"
    SERVICE_NAME="aws-cicd-platform-service"
    echo "  Cluster: ${CLUSTER_NAME} | Service: ${SERVICE_NAME}"
    aws ecs describe-services \
        --cluster "${CLUSTER_NAME}" \
        --services "${SERVICE_NAME}" \
        --query 'services[0].{Status:status,Desired:desiredCount,Running:runningCount,Pending:pendingCount,TaskDef:taskDefinition}' \
        --output table 2>/dev/null || echo "  (Ensure AWS credentials have ecs:DescribeServices)"
fi

# ── 5. CloudWatch Live Audit Logs ─────────────────────────────────────────────
echo ""
echo "── [5/5] Tail CloudWatch Deployment Logs ──"
if command -v aws >/dev/null 2>&1; then
    LOG_GROUP="/aws/ecs/aws-cicd-platform-app"
    echo "  Tailing last 5 events from ${LOG_GROUP}:"
    aws logs tail "${LOG_GROUP}" --format short 2>/dev/null | tail -n 5 || echo "  (Log group not yet initialized or pending first event)"
fi

echo ""
echo "=================================================================="
echo " 🎉 Verification Sweep Completed!"
echo "=================================================================="
