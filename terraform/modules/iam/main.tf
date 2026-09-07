# ==============================================================================
# IAM Module: Principle-of-Least-Privilege Roles & Policies
#
# Roles Provisioned:
# 1. Jenkins CI Role        - Scoped for ECR push, S3 upload, ECS rollout & CloudWatch
# 2. ECS Task Execution Role - Scoped for ECS agent ECR pulling & CloudWatch logging
# 3. ECS Task Role           - Scoped for application runtime inside container
# ==============================================================================

# ── 1. Jenkins CI / Deployment IAM Role ───────────────────────────────────────
data "aws_iam_policy_document" "jenkins_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "jenkins_ci" {
  name               = "${var.project_name}-jenkins-ci-role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.jenkins_trust.json
  description        = "Least-privilege role for Jenkins CI/CD pipeline automation"

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-jenkins-ci-role"
      Environment = var.environment
      Role        = "CI/CD Pipeline"
    }
  )
}

data "aws_iam_policy_document" "jenkins_ci_policy" {
  # ECR Token Retrieval (Requires * in AWS)
  statement {
    sid       = "ECRAuthToken"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  # Scoped ECR Image Operations
  statement {
    sid    = "ECRImagePushPull"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeRepositories",
      "ecr:ListImages"
    ]
    resources = [var.ecr_repository_arn]
  }

  # Scoped S3 Build Artifact Operations
  statement {
    sid    = "S3ArtifactStorage"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = [
      var.s3_bucket_arn,
      "${var.s3_bucket_arn}/*"
    ]
  }

  # Scoped ECS Service Update
  statement {
    sid    = "ECSDeploymentUpdate"
    effect = "Allow"
    actions = [
      "ecs:UpdateService",
      "ecs:DescribeServices",
      "ecs:DescribeTaskDefinition",
      "ecs:RegisterTaskDefinition"
    ]
    resources = ["*"]
  }

  # Scoped PassRole for ECS Task Execution
  statement {
    sid     = "PassRoleToECS"
    effect  = "Allow"
    actions = ["iam:PassRole"]
    resources = [
      aws_iam_role.ecs_execution.arn,
      aws_iam_role.ecs_task.arn
    ]
  }

  # Scoped CloudWatch Log Streaming
  statement {
    sid    = "CloudWatchLogging"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
    resources = ["${var.cloudwatch_log_group_arn}:*"]
  }
}

resource "aws_iam_policy" "jenkins_ci" {
  name        = "${var.project_name}-jenkins-ci-policy-${var.environment}"
  description = "Scoped least-privilege policy for Jenkins CI/CD automation"
  policy      = data.aws_iam_policy_document.jenkins_ci_policy.json
}

resource "aws_iam_role_policy_attachment" "jenkins_ci" {
  role       = aws_iam_role.jenkins_ci.name
  policy_arn = aws_iam_policy.jenkins_ci.arn
}

resource "aws_iam_instance_profile" "jenkins_ci" {
  name = "${var.project_name}-jenkins-instance-profile-${var.environment}"
  role = aws_iam_role.jenkins_ci.name
}

# ── 2. ECS Task Execution IAM Role ────────────────────────────────────────────
data "aws_iam_policy_document" "ecs_tasks_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_execution" {
  name               = "${var.project_name}-ecs-execution-role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_trust.json
  description        = "Role allowing ECS container agent to pull images and push logs"

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-ecs-execution-role"
      Environment = var.environment
    }
  )
}

resource "aws_iam_role_policy_attachment" "ecs_execution_standard" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ── 3. ECS Task Runtime IAM Role ──────────────────────────────────────────────
resource "aws_iam_role" "ecs_task" {
  name               = "${var.project_name}-ecs-task-role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_trust.json
  description        = "Application runtime role inside the container"

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-ecs-task-role"
      Environment = var.environment
    }
  )
}
