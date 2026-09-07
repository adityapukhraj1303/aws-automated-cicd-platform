terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.30"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Backend configuration for remote S3 state and DynamoDB locking.
  # Run `terraform init -backend-config="bucket=<YOUR_BUCKET>" ...`
  # backend "s3" {
  #   bucket         = "aws-cicd-tfstate-<account-id>"
  #   key            = "platform/terraform.tfstate"
  #   region         = "ap-south-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-lock-table"
  # }
}
