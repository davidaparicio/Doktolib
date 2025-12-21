variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the Aurora Serverless cluster"
  type        = string
  default     = "doktolib-aurora"
}

variable "database_name" {
  description = "Name of the default database to create"
  type        = string
  default     = "doktolib"
}

variable "master_username" {
  description = "Master username for the database"
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  description = "Aurora PostgreSQL engine version"
  type        = string
  default     = "15.5"
}

variable "min_capacity" {
  description = "Minimum Aurora Serverless v2 capacity units (0.5 to 128)"
  type        = number
  default     = 0.5
}

variable "max_capacity" {
  description = "Maximum Aurora Serverless v2 capacity units (0.5 to 128)"
  type        = number
  default     = 2
}

variable "instance_count" {
  description = "Number of Aurora instances to create (1 for single-AZ, 2+ for Multi-AZ)"
  type        = number
  default     = 1
}

variable "use_default_vpc" {
  description = "Whether to use the default VPC"
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "VPC ID where Aurora will be deployed (required if use_default_vpc is false)"
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "List of subnet IDs for the DB subnet group (if empty, all subnets in VPC will be used)"
  type        = list(string)
  default     = []
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access the database"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "publicly_accessible" {
  description = "Whether the database should be publicly accessible"
  type        = bool
  default     = true
}

variable "backup_retention_period" {
  description = "Number of days to retain backups (1-35)"
  type        = number
  default     = 7
}

variable "preferred_backup_window" {
  description = "Preferred backup window (UTC)"
  type        = string
  default     = "03:00-04:00"
}

variable "preferred_maintenance_window" {
  description = "Preferred maintenance window (UTC)"
  type        = string
  default     = "mon:04:00-mon:05:00"
}

variable "skip_final_snapshot" {
  description = "Whether to skip final snapshot when destroying the cluster"
  type        = bool
  default     = false
}

variable "apply_immediately" {
  description = "Whether to apply changes immediately or during maintenance window"
  type        = bool
  default     = false
}

variable "kms_key_id" {
  description = "KMS key ID for encryption (if not specified, default AWS key will be used)"
  type        = string
  default     = ""
}

variable "performance_insights_enabled" {
  description = "Whether to enable Performance Insights"
  type        = bool
  default     = true
}

variable "secret_recovery_days" {
  description = "Number of days to retain deleted secrets (0-30, 0 for immediate deletion)"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "Doktolib"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
