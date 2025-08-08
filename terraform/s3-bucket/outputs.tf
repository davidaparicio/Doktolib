output "bucket_name" {
  description = "Name of the created S3 bucket"
  value       = aws_s3_bucket.doktolib_files.bucket
}

output "bucket_arn" {
  description = "ARN of the created S3 bucket"
  value       = aws_s3_bucket.doktolib_files.arn
}

output "bucket_regional_domain_name" {
  description = "Regional domain name of the S3 bucket"
  value       = aws_s3_bucket.doktolib_files.bucket_regional_domain_name
}

output "app_user_access_key_id" {
  description = "Access key ID for the application user"
  value       = aws_iam_access_key.doktolib_app_user_key.id
}

output "app_user_secret_access_key" {
  description = "Secret access key for the application user"
  value       = aws_iam_access_key.doktolib_app_user_key.secret
  sensitive   = true
}

output "app_role_arn" {
  description = "ARN of the application IAM role"
  value       = aws_iam_role.doktolib_app_role.arn
}