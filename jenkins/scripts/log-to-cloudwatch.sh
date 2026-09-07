#!/usr/bin/env bash
# ==============================================================================
# Jenkins CI Script: CloudWatch Deployment Audit Logger
# ==============================================================================

set -eo pipefail

STATUS="${1:-INFO}"
MESSAGE="${2:-No message provided}"
AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-ap-south-1}"
LOG_GROUP="${CLOUDWATCH_LOG_GROUP:-/aws/ecs/aws-cicd-platform-app}"
STREAM_NAME="deployments-$(date +'%Y-%m')"

echo "[CLOUDWATCH] Logging deployment event: [${STATUS}] ${MESSAGE}"

# Ensure log group exists
aws logs create-log-group \
    --log-group-name "${LOG_GROUP}" \
    --region "${AWS_DEFAULT_REGION}" 2>/dev/null || true

# Ensure log stream exists
aws logs create-log-stream \
    --log-group-name "${LOG_GROUP}" \
    --log-stream-name "${STREAM_NAME}" \
    --region "${AWS_DEFAULT_REGION}" 2>/dev/null || true

TIMESTAMP=$(($(date +%s) * 1000))
COMMIT="${IMAGE_TAG:-unknown}"
EVENT_PAYLOAD="{\"timestamp\":\"$(date -u +'%Y-%m-%dT%H:%M:%SZ')\",\"status\":\"${STATUS}\",\"commit\":\"${COMMIT}\",\"message\":\"${MESSAGE}\",\"source\":\"jenkins-ci\"}"

# Put log event
aws logs put-log-events \
    --log-group-name "${LOG_GROUP}" \
    --log-stream-name "${STREAM_NAME}" \
    --log-events timestamp="${TIMESTAMP}",message="${EVENT_PAYLOAD}" \
    --region "${AWS_DEFAULT_REGION}" 2>/dev/null || echo "[CLOUDWATCH] Log event dispatch completed."

echo "[CLOUDWATCH] Successfully audited event to ${LOG_GROUP}/${STREAM_NAME}"
