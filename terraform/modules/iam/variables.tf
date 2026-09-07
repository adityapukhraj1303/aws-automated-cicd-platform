variable "project_name" {
  description = "Project name prefix for IAM resources"
  type        = string
  default     = "aws-cicd-platform"
}

variable "environment" {
  description = "Deployment environment name"
  type        = string
  default     = "dev"
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 artifacts bucket"
  type        = string
}

variable "ecr_repository_arn" {
  description = "ARN of the ECR repository"
  type        = string
}

variable "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch Log Group"
  type        = string
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
