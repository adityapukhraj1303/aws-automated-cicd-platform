provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = "DevOps"
      Repository  = "https://github.com/adityapukhraj1303/aws-automated-cicd-platform"
    }
  }
}
