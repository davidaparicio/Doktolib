variable "qovery_access_token" {
  description = "Qovery API access token"
  type        = string
  sensitive   = true
}

variable "qovery_organization_id" {
  description = "Qovery organization ID"
  type        = string
}

variable "qovery_project_id" {
  description = "Qovery project ID"
  type        = string
}

variable "qovery_cluster_id" {
  description = "Qovery cluster ID where the environment will be deployed"
  type        = string
}

# ========================================
# Environment Configuration
# ========================================

variable "environment_name" {
  description = "Name of the Qovery environment"
  type        = string
  default     = "production"
}

variable "environment_mode" {
  description = "Environment mode (PRODUCTION, STAGING, DEVELOPMENT)"
  type        = string
  default     = "PRODUCTION"

  validation {
    condition     = contains(["PRODUCTION", "STAGING", "DEVELOPMENT"], var.environment_mode)
    error_message = "Environment mode must be PRODUCTION, STAGING, or DEVELOPMENT"
  }
}

# ========================================
# Git Repository Configuration
# ========================================

variable "git_repository_url" {
  description = "Git repository URL (e.g., https://github.com/username/repo)"
  type        = string
}

variable "git_branch" {
  description = "Git branch to deploy"
  type        = string
  default     = "main"
}

variable "auto_deploy_enabled" {
  description = "Enable automatic deployment on git push"
  type        = bool
  default     = true
}

# ========================================
# Database Configuration
# ========================================

variable "use_managed_database" {
  description = "Use managed database (RDS Aurora) instead of containerized PostgreSQL"
  type        = bool
  default     = false
}

# Note: Managed database credentials are automatically injected by
# the RDS Aurora terraform service via the 'database_url' output

# ========================================
# Backend Configuration
# ========================================

variable "backend_cpu" {
  description = "Backend CPU allocation in millicores (1000 = 1 CPU)"
  type        = number
  default     = 500
}

variable "backend_memory" {
  description = "Backend memory allocation in MB"
  type        = number
  default     = 512
}

variable "backend_min_instances" {
  description = "Minimum number of backend instances"
  type        = number
  default     = 1
}

variable "backend_max_instances" {
  description = "Maximum number of backend instances"
  type        = number
  default     = 3
}

variable "cors_allowed_origins" {
  description = "CORS allowed origins (comma-separated)"
  type        = string
  default     = "*"
}

variable "jwt_secret" {
  description = "JWT secret key for authentication"
  type        = string
  sensitive   = true
  default     = ""
}

# ========================================
# Frontend Configuration
# ========================================

variable "frontend_cpu" {
  description = "Frontend CPU allocation in millicores"
  type        = number
  default     = 500
}

variable "frontend_memory" {
  description = "Frontend memory allocation in MB"
  type        = number
  default     = 512
}

variable "frontend_min_instances" {
  description = "Minimum number of frontend instances"
  type        = number
  default     = 1
}

variable "frontend_max_instances" {
  description = "Maximum number of frontend instances"
  type        = number
  default     = 5
}

variable "visio_health_url" {
  description = "Visio conference health check URL (from Lambda)"
  type        = string
  default     = ""
}

# ========================================
# Seed Data Job Configuration
# ========================================

variable "enable_seed_job" {
  description = "Enable seed data job"
  type        = bool
  default     = true
}

variable "seed_num_doctors" {
  description = "Number of doctors to seed"
  type        = string
  default     = "100"
}

variable "seed_force" {
  description = "Force seeding even if data exists"
  type        = string
  default     = "false"
}

# ========================================
# Load Generator Configuration
# ========================================

variable "enable_load_generator" {
  description = "Enable load generator application"
  type        = bool
  default     = true
}

variable "load_scenario" {
  description = "Load testing scenario (light, normal, heavy, stress)"
  type        = string
  default     = "light"

  validation {
    condition     = contains(["light", "normal", "heavy", "stress"], var.load_scenario)
    error_message = "Load scenario must be one of: light, normal, heavy, stress"
  }
}

variable "load_duration" {
  description = "Load test duration in minutes"
  type        = string
  default     = "5"
}

# ========================================
# Terraform Services Configuration
# ========================================

# Terraform services use Kubernetes backend for state storage
# No S3 bucket configuration needed

variable "enable_rds_aurora" {
  description = "Enable RDS Aurora Serverless deployment via Terraform service"
  type        = bool
  default     = true
}

variable "enable_lambda_visio" {
  description = "Enable Lambda visio health service deployment via Terraform service"
  type        = bool
  default     = true
}

variable "enable_cloudflare_cdn" {
  description = "Enable Cloudflare CDN deployment via Terraform service"
  type        = bool
  default     = true
}

variable "cloudflare_domain_name" {
  description = "Root domain name for Cloudflare (required for Cloudflare CDN deployment)"
  type        = string
  default     = ""
}

variable "enable_s3_bucket" {
  description = "Enable S3 bucket deployment via Terraform service for medical files storage"
  type        = bool
  default     = true
}
