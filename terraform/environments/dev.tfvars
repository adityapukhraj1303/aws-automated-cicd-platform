# ==============================================================================
# environments/dev.tfvars
# Development environment variable overrides for the AWS Automated CI/CD Platform.
#
# Usage:
#   terraform plan  -var-file="environments/dev.tfvars"
#   terraform apply -var-file="environments/dev.tfvars"
#
# Source: variables.tf declares all variables; this file overrides defaults for dev.
# ==============================================================================

# ── AWS Provider ───────────────────────────────────────────────────────────────
# Region where all resources will be provisioned.
# ap-south-1 = Mumbai — matches the project default and EC2 setup guide.
aws_region = "ap-south-1"

# ── Project Identity ───────────────────────────────────────────────────────────
# Used as a prefix for every AWS resource name:
#   ECR repo, S3 bucket prefix, IAM role, EC2 Name tag, and Security Group.
# Keep consistent with Jenkins env var AWS_ECR_REPO_NAME in the Jenkinsfile.
project_name = "aws-cicd-platform"

# ── Environment Tag ────────────────────────────────────────────────────────────
# Drives the `Environment` common_tag on all resources and toggles:
#   • S3 force_destroy = true   (safe shortcut for dev; must be false in prod)
#   • IAM role name  → aws-cicd-platform-cicd-role-dev
#   • SG name        → aws-cicd-platform-web-sg-dev
#   • EC2 Name tag   → aws-cicd-platform-web-dev
# Allowed values: dev | staging | prod
environment = "dev"

# ── EC2 Compute ────────────────────────────────────────────────────────────────
# Instance type for the web server that runs the Docker container (port 80).
# t3.small (2 vCPU / 2 GB RAM) is sufficient for dev workloads.
# Upgrade to t3.medium or larger for staging/prod.
instance_type = "t3.small"
