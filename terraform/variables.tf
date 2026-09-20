# ==============================================================================
# AWS Automated CI/CD Platform - Input Variables
# ==============================================================================

variable "aws_region" {
  description = "AWS deployment region"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name used as prefix for all resource names"
  type        = string
  default     = "aws-cicd-platform"
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod"
  }
}

variable "instance_type" {
  description = "EC2 instance type for the web server"
  type        = string
  default     = "t3.small"
}
