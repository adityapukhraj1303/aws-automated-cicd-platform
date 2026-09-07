# ==============================================================================
# AWS Automated CI/CD Platform - Root Module Orchestrator
#
# Composes:
#   1. modules/s3         - Versioned build artifact storage & state bucket
#   2. modules/ecr        - Private image registry with automated scanning
#   3. modules/iam        - Principle-of-least-privilege CI/CD and runtime roles
#   4. modules/ecs        - High-availability VPC, ALB & ECS Fargate deployment
#   5. modules/cloudwatch - Log streaming, metric alarms & operational dashboard
# ==============================================================================

locals {
  app_name = "${var.project_name}-app"
}

# ── 1. S3 Artifacts & State Storage ───────────────────────────────────────────
module "s3" {
  source = "./modules/s3"

  bucket_prefix                      = "${var.project_name}-artifacts"
  environment                        = var.environment
  force_destroy                      = var.environment == "dev" ? true : false
  noncurrent_version_expiration_days = 90
}

# ── 2. ECR Container Registry ─────────────────────────────────────────────────
module "ecr" {
  source = "./modules/ecr"

  repository_name      = local.app_name
  environment          = var.environment
  image_tag_mutability = "MUTABLE"
}

# ── 3. CloudWatch Logging & Dashboards ────────────────────────────────────────
module "cloudwatch" {
  source = "./modules/cloudwatch"

  project_name                = var.project_name
  environment                 = var.environment
  log_group_name              = "/aws/ecs/${local.app_name}"
  retention_in_days           = var.log_retention_days
  ecs_cluster_name            = module.ecs.cluster_name
  ecs_service_name            = module.ecs.service_name
  alb_arn_suffix              = module.ecs.alb_arn_suffix
  alb_target_group_arn_suffix = module.ecs.target_group_arn_suffix
  aws_region                  = var.aws_region
}

# ── 4. Least-Privilege IAM Roles ──────────────────────────────────────────────
module "iam" {
  source = "./modules/iam"

  project_name             = var.project_name
  environment              = var.environment
  s3_bucket_arn            = module.s3.bucket_arn
  ecr_repository_arn       = module.ecr.repository_arn
  cloudwatch_log_group_arn = module.cloudwatch.log_group_arn
}

# ── 5. ECS Fargate & ALB Networking ───────────────────────────────────────────
module "ecs" {
  source = "./modules/ecs"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  cluster_name       = "${var.project_name}-cluster"
  service_name       = "${var.project_name}-service"
  container_port     = var.container_port
  desired_count      = var.desired_count
  task_cpu           = var.task_cpu
  task_memory        = var.task_memory
  image_uri          = var.initial_image_uri
  execution_role_arn = module.iam.ecs_execution_role_arn
  task_role_arn      = module.iam.ecs_task_role_arn
  log_group_name     = module.cloudwatch.log_group_name
  aws_region         = var.aws_region
}
