# ==============================================================================
# AWS Automated CI/CD Platform - Outputs
# ==============================================================================

output "ec2_public_ip" {
  description = "Public IP address of the deployed EC2 web server"
  value       = aws_instance.web.public_ip
}

output "application_url" {
  description = "Public HTTP URL to access the deployed web dashboard"
  value       = "http://${aws_instance.web.public_ip}"
}

output "ecr_repository_url" {
  description = "AWS ECR container image registry URL"
  value       = aws_ecr_repository.app.repository_url
}

output "s3_artifact_bucket" {
  description = "Name of the S3 bucket for build artifacts"
  value       = aws_s3_bucket.artifacts.id
}

output "quick_verification_commands" {
  description = "Useful CLI commands to verify the deployment"
  value       = <<EOT
# 1. Check HTTP health of deployed app
curl -i http://${aws_instance.web.public_ip}/

# 2. SSH into the instance
ssh -i your-key.pem ec2-user@${aws_instance.web.public_ip}

# 3. Inspect running Docker containers on EC2
ssh ec2-user@${aws_instance.web.public_ip} "docker ps"

# 4. List images in ECR repository
aws ecr list-images --repository-name ${aws_ecr_repository.app.name} --region ap-south-1

# 5. List S3 artifact builds
aws s3 ls s3://${aws_s3_bucket.artifacts.id}/
EOT
}
