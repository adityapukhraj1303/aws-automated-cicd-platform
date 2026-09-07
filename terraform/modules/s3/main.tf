# ==============================================================================
# S3 Module: Main Resource Definitions
#
# Versioned, encrypted S3 bucket for build artifacts and remote Terraform state
# Strict public access block & lifecycle expiration rules applied.
# ==============================================================================

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

locals {
  bucket_name = "${var.bucket_prefix}-${var.environment}-${random_id.bucket_suffix.hex}"
}

resource "aws_s3_bucket" "artifacts" {
  bucket        = local.bucket_name
  force_destroy = var.force_destroy

  tags = merge(
    var.tags,
    {
      Name        = local.bucket_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Purpose     = "CI/CD Build Artifacts & Remote State"
    }
  )
}

# ── Bucket Versioning ─────────────────────────────────────────────────────────
resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}

# ── Server-Side Encryption (SSE-S3 AES256) ────────────────────────────────────
resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ── Strict Public Access Block ────────────────────────────────────────────────
resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ── Lifecycle Expiration Rules ────────────────────────────────────────────────
resource "aws_s3_bucket_lifecycle_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  rule {
    id     = "expire-old-build-artifacts"
    status = "Enabled"

    filter {
      prefix = "builds/"
    }

    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_version_expiration_days
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}
