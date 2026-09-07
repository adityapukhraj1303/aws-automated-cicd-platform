variable "project_name" {
  description = "Project name"
  type        = string
  default     = "aws-cicd-platform"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "log_group_name" {
  description = "Name of the CloudWatch Log Group"
  type        = string
  default     = "/aws/ecs/aws-cicd-platform-app"
}

variable "retention_in_days" {
  description = "Days of log retention"
  type        = number
  default     = 30
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "ecs_service_name" {
  description = "Name of the ECS service"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ARN suffix of the Application Load Balancer"
  type        = string
}

variable "alb_target_group_arn_suffix" {
  description = "ARN suffix of the ALB Target Group"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
