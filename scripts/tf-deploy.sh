#!/usr/bin/env bash
# ==============================================================================
# Terraform Automation & Deployment Helper
#
# Usage:
#   ./scripts/tf-deploy.sh init [dev|prod]
#   ./scripts/tf-deploy.sh plan [dev|prod]
#   ./scripts/tf-deploy.sh apply [dev|prod]
#   ./scripts/tf-deploy.sh destroy [dev|prod]
# ==============================================================================

set -eo pipefail

ACTION="${1:-plan}"
ENV="${2:-dev}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="${REPO_ROOT}/terraform"
VARS_FILE="${TF_DIR}/environments/${ENV}.tfvars"

cd "$TF_DIR"

if [[ ! -f "$VARS_FILE" ]]; then
    echo "[ERROR] Variables file not found: $VARS_FILE" >&2
    exit 1
fi

echo "=================================================================="
echo " Terraform Action: [${ACTION}] | Environment: [${ENV}]"
echo " Working Dir:      ${TF_DIR}"
echo " Variables File:   ${VARS_FILE}"
echo "=================================================================="

case "$ACTION" in
    init)
        echo "--> Initializing Terraform..."
        terraform init -upgrade
        ;;
    validate)
        echo "--> Validating Terraform configurations..."
        terraform validate
        ;;
    plan)
        echo "--> Generating execution plan..."
        terraform plan -var-file="$VARS_FILE" -out="${ENV}.tfplan"
        ;;
    apply)
        if [[ -f "${ENV}.tfplan" ]]; then
            echo "--> Applying pre-computed plan (${ENV}.tfplan)..."
            terraform apply "${ENV}.tfplan"
            rm -f "${ENV}.tfplan"
        else
            echo "--> Applying configuration directly..."
            terraform apply -var-file="$VARS_FILE" -auto-approve
        fi
        ;;
    destroy)
        echo "WARNING: Destroying all infrastructure in ${ENV} environment!"
        terraform destroy -var-file="$VARS_FILE"
        ;;
    output)
        terraform output
        ;;
    *)
        echo "Usage: $0 {init|validate|plan|apply|destroy|output} [dev|prod]"
        exit 1
        ;;
esac
