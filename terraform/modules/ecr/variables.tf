variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "aws-cicd-platform-app"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "image_tag_mutability" {
  description = "Image tag mutability setting (MUTABLE or IMMUTABLE)"
  type        = string
  default     = "MUTABLE"
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
