variable "aws_region" {
  description = "AWS region for the S3 bucket"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Name of the S3 bucket for medical files"
  type        = string
  validation {
    condition = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.bucket_name)) && length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63
    error_message = "Bucket name must be between 3 and 63 characters, contain only lowercase letters, numbers, and hyphens, and cannot start or end with a hyphen."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  default     = "production"
}

variable "allowed_origins" {
  description = "List of allowed origins for CORS"
  type        = list(string)
  default     = ["https://doktolib.com", "https://app.doktolib.com"]
}

variable "app_role_arn" {
  description = "ARN of the application role that can assume the S3 access role"
  type        = string
  default     = ""
}