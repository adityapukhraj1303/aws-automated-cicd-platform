output "jenkins_role_arn" {
  description = "ARN of the Jenkins CI IAM role"
  value       = aws_iam_role.jenkins_ci.arn
}

output "jenkins_instance_profile_name" {
  description = "Name of the Jenkins EC2 instance profile"
  value       = aws_iam_instance_profile.jenkins_ci.name
}

output "ecs_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_execution.arn
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS task runtime role"
  value       = aws_iam_role.ecs_task.arn
}
