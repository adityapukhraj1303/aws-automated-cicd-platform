# ==============================================================================
# AWS Automated CI/CD Platform - Root Outputs
# ==============================================================================

output "application_url" {
  description = "Public HTTP endpoint to access the deployed web microservice"
  value       = "http://${module.ecs.alb_dns_name}"
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = module.ecs.alb_dns_name
}

output "s3_artifact_bucket" {
  description = "Name of the S3 bucket storing build artifacts"
  value       = module.s3.bucket_id
}

output "ecr_repository_url" {
  description = "URL of the private ECR image repository"
  value       = module.ecr.repository_url
}

output "ecs_cluster_name" {
  description = "Name of the ECS Cluster"
  value       = module.ecs.cluster_name
}

output "ecs_service_name" {
  description = "Name of the ECS Service"
  value       = module.ecs.service_name
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group name for application and deployment logs"
  value       = module.cloudwatch.log_group_name
}

output "cloudwatch_dashboard" {
  description = "Name of the CloudWatch platform monitoring dashboard"
  value       = module.cloudwatch.dashboard_name
}

output "jenkins_ci_role_arn" {
  description = "IAM Role ARN to configure in Jenkins AWS credentials"
  value       = module.iam.jenkins_role_arn
}

output "quick_verification_commands" {
  description = "Helpful CLI commands to verify deployment health"
  value       = <<EOT
# 1. Test Application Health Endpoint
curl -i http://${module.ecs.alb_dns_name}/health

# 2. Inspect ECR Images
aws ecr list-images --repository-name ${module.ecr.repository_name}

# 3. List Build Artifacts in S3
aws s3 ls s3://${module.s3.bucket_id}/builds/

# 4. Tail Live Container & Deployment Logs
aws logs tail ${module.cloudwatch.log_group_name} --follow

# 5. Check ECS Service & Running Tasks Status
aws ecs describe-services --cluster ${module.ecs.cluster_name} --services ${module.ecs.service_name}
EOT
}
