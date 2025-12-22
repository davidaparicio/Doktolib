terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key_id != "" ? var.aws_access_key_id : null
  secret_key = var.aws_secret_access_key != "" ? var.aws_secret_access_key : null
}

# S3 bucket for secure medical file uploads
resource "aws_s3_bucket" "doktolib_files" {
  bucket = var.bucket_name

  tags = {
    Name        = "Doktolib Medical Files"
    Environment = var.environment
    Project     = "doktolib"
  }
}

# Block public access to the bucket
resource "aws_s3_bucket_public_access_block" "doktolib_files_pab" {
  bucket = aws_s3_bucket.doktolib_files.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning
resource "aws_s3_bucket_versioning" "doktolib_files_versioning" {
  bucket = aws_s3_bucket.doktolib_files.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption configuration
resource "aws_s3_bucket_server_side_encryption_configuration" "doktolib_files_encryption" {
  bucket = aws_s3_bucket.doktolib_files.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Lifecycle configuration for automatic cleanup
resource "aws_s3_bucket_lifecycle_configuration" "doktolib_files_lifecycle" {
  bucket = aws_s3_bucket.doktolib_files.id

  rule {
    id     = "delete_old_versions"
    status = "Enabled"

    # Filter to apply rule to all objects
    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }

  rule {
    id     = "delete_incomplete_uploads"
    status = "Enabled"

    # Filter to apply rule to all objects
    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}

# CORS configuration for web uploads
resource "aws_s3_bucket_cors_configuration" "doktolib_files_cors" {
  bucket = aws_s3_bucket.doktolib_files.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_origins = var.allowed_origins
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# IAM policy for the application
data "aws_iam_policy_document" "doktolib_s3_policy" {
  statement {
    sid    = "AllowApplicationAccess"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.doktolib_app_role.arn]
    }

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:GetObjectVersion",
      "s3:PutObjectAcl",
    ]

    resources = [
      aws_s3_bucket.doktolib_files.arn,
      "${aws_s3_bucket.doktolib_files.arn}/*"
    ]
  }

  statement {
    sid    = "AllowListBucket"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.doktolib_app_role.arn]
    }

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      aws_s3_bucket.doktolib_files.arn
    ]
  }
}

# Attach policy to bucket
resource "aws_s3_bucket_policy" "doktolib_files_policy" {
  bucket = aws_s3_bucket.doktolib_files.id
  policy = data.aws_iam_policy_document.doktolib_s3_policy.json
}

# IAM role for the application
resource "aws_iam_role" "doktolib_app_role" {
  name = "${var.bucket_name}-app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat([
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ],
    var.app_role_arn != "" ? [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = var.app_role_arn
        }
      }
    ] : [])
  })
}

# IAM policy for S3 access
resource "aws_iam_role_policy" "doktolib_s3_access" {
  name = "${var.bucket_name}-s3-access"
  role = aws_iam_role.doktolib_app_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:GetObjectVersion",
          "s3:PutObjectAcl",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.doktolib_files.arn,
          "${aws_s3_bucket.doktolib_files.arn}/*"
        ]
      }
    ]
  })
}

# Create access keys for the application
resource "aws_iam_user" "doktolib_app_user" {
  name = "${var.bucket_name}-app-user"
}

resource "aws_iam_user_policy" "doktolib_app_user_policy" {
  name = "${var.bucket_name}-app-user-policy"
  user = aws_iam_user.doktolib_app_user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:GetObjectVersion",
          "s3:PutObjectAcl",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.doktolib_files.arn,
          "${aws_s3_bucket.doktolib_files.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_access_key" "doktolib_app_user_key" {
  user = aws_iam_user.doktolib_app_user.name
}