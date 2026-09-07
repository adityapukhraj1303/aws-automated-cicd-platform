variable "aws_region" {
  description = "AWS deployment region"
  type        = string
  default     = "ap-south-1"
}

variable "instance_type" {
  description = "EC2 instance type for runner or compute"
  type        = string
  default     = "t3.small"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "aws-cicd-platform"
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "container_port" {
  description = "Port exposed by the web microservice"
  type        = number
  default     = 8080
}

variable "desired_count" {
  description = "Number of ECS tasks to maintain"
  type        = number
  default     = 2
}

variable "task_cpu" {
  description = "ECS Fargate CPU allocation"
  type        = string
  default     = "256"
}

variable "task_memory" {
  description = "ECS Fargate Memory allocation"
  type        = string
  default     = "512"
}

variable "initial_image_uri" {
  description = "Initial container image URI for ECS task definition"
  type        = string
  default     = "public.ecr.aws/ecs-sample-image/amazon-ecs-sample:latest"
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}
