resource "random_string" "terraform_random_suffix" {
  length  = 8
  upper   = false
  special = false
}

resource "aws_s3_bucket" "terraform_state_bucket" {
  bucket = "tfstate-bucket-${var.environment_name}-${var.aws_region}-${random_string.terraform_random_suffix.result}"
  lifecycle {
    prevent_destroy = false
  }
  tags = merge(local.global_tags, {
    Name        = "tfstate-${var.environment_name}-${var.aws_region}"
    Environment = var.environment_name
    Project     = "remote-backend-for-devops-real-world-course"
    Purpose     = "terraform-backend"
  })
}

resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
  bucket = aws_s3_bucket.terraform_state_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_encryption" {
  bucket = aws_s3_bucket.terraform_state_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state_block_public" {
  bucket                  = aws_s3_bucket.terraform_state_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Lifecycle Policy to manage old versions of your state files
resource "aws_s3_bucket_lifecycle_configuration" "state_lifecycle" {
  depends_on = [aws_s3_bucket_versioning.terraform_state_versioning]
  bucket     = aws_s3_bucket.terraform_state_bucket.id

  rule {
    id     = "expire-old-state-versions"
    status = "Enabled"

    # Keeps your active state file untouched, but manages the historical versions
    noncurrent_version_expiration {
      noncurrent_days = 180 # Deletes state versions older than 180 days
    }
  }
}