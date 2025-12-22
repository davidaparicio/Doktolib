variable "aws_region" {
  description = "AWS region where Lambda will be deployed"
  type        = string
  default     = "us-east-1"
}

variable "assume_role_arn" {
  description = "ARN of the IAM role to assume for AWS operations"
  type        = string
  default     = ""
}

variable "assume_role_external_id" {
  description = "External ID to use when assuming the IAM role"
  type        = string
  default     = ""
  sensitive   = true
}

variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "qovery-doktolib-visio-health"
}

variable "environment" {
  description = "Environment name (development, staging, production)"
  type        = string
  default     = "production"
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 10
}

variable "lambda_memory" {
  description = "Lambda function memory in MB"
  type        = number
  default     = 128
}

variable "log_retention_days" {
  description = "CloudWatch logs retention in days"
  type        = number
  default     = 7
}

variable "cors_allow_origins" {
  description = "List of allowed origins for CORS"
  type        = list(string)
  default     = ["*"]
}

variable "error_threshold" {
  description = "Number of errors before triggering alarm"
  type        = number
  default     = 10
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "Doktolib"
    Service     = "Visio-Conference"
    ManagedBy   = "Terraform"
  }
}
