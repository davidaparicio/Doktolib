variable "qovery_api_token" {
  description = "Qovery API token for authentication"
  type        = string
  sensitive   = true
}

variable "qovery_organization_id" {
  description = "Your Qovery organization ID"
  type        = string
}

variable "qovery_cluster_id" {
  description = "Qovery cluster ID where the application will be deployed"
  type        = string
}

variable "git_repository_url" {
  description = "Git repository URL containing the Doktolib application"
  type        = string
  default     = "https://github.com/your-username/doktolib.git"
}

variable "custom_domain" {
  description = "Custom domain for the frontend application (optional)"
  type        = string
  default     = ""
}

variable "environment_name" {
  description = "Environment name (production, staging, development)"
  type        = string
  default     = "production"
}

variable "backend_cpu" {
  description = "CPU allocation for backend (in millicores)"
  type        = number
  default     = 500
}

variable "backend_memory" {
  description = "Memory allocation for backend (in MB)"
  type        = number
  default     = 512
}

variable "frontend_cpu" {
  description = "CPU allocation for frontend (in millicores)"
  type        = number
  default     = 500
}

variable "frontend_memory" {
  description = "Memory allocation for frontend (in MB)"
  type        = number
  default     = 512
}

variable "database_storage" {
  description = "Database storage size (in GB)"
  type        = number
  default     = 10
}

variable "db_ssl_mode" {
  description = "PostgreSQL SSL mode (disable, require, verify-ca, verify-full)"
  type        = string
  default     = "disable"
  
  validation {
    condition = contains(["disable", "require", "verify-ca", "verify-full"], var.db_ssl_mode)
    error_message = "The db_ssl_mode must be one of: disable, require, verify-ca, verify-full."
  }
}