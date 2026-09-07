variable "bucket_prefix" {
  description = "Prefix string used for the S3 bucket name"
  type        = string
  default     = "aws-cicd-artifacts"
}

variable "environment" {
  description = "Deployment environment name (e.g. dev, prod)"
  type        = string
  default     = "dev"
}

variable "force_destroy" {
  description = "Whether to delete all objects in the bucket so that the bucket can be destroyed without error"
  type        = bool
  default     = false
}

variable "noncurrent_version_expiration_days" {
  description = "Number of days after which non-current versions of objects expire"
  type        = number
  default     = 90
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
