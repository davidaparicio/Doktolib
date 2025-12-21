variable "cloudflare_api_token" {
  description = "Cloudflare API token with Zone:Edit permissions"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "Root domain name (e.g., doktolib.com)"
  type        = string
}

variable "frontend_subdomain" {
  description = "Subdomain for frontend application (e.g., 'app' for app.doktolib.com, or '@' for root domain)"
  type        = string
  default     = "app"
}

variable "origin_url" {
  description = "Origin URL where your frontend is hosted (e.g., Qovery-provided URL)"
  type        = string
}

variable "create_www_redirect" {
  description = "Create www subdomain redirect"
  type        = bool
  default     = false
}

variable "create_admin_bypass" {
  description = "Create cache bypass rule for /admin/* paths"
  type        = bool
  default     = false
}

variable "create_api_bypass" {
  description = "Create cache bypass rule for /api/* paths"
  type        = bool
  default     = true
}

variable "create_health_check" {
  description = "Create Cloudflare health check monitoring"
  type        = bool
  default     = true
}

variable "rate_limit_requests_per_5min" {
  description = "Maximum requests per 5 minutes before rate limiting"
  type        = number
  default     = 100
}

variable "security_level" {
  description = "Cloudflare security level (off, essentially_off, low, medium, high, under_attack)"
  type        = string
  default     = "medium"

  validation {
    condition     = contains(["off", "essentially_off", "low", "medium", "high", "under_attack"], var.security_level)
    error_message = "Security level must be one of: off, essentially_off, low, medium, high, under_attack"
  }
}

variable "enable_cache_purge_on_deploy" {
  description = "Purge Cloudflare cache on Terraform apply"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources (where supported)"
  type        = map(string)
  default = {
    Project    = "Doktolib"
    Component  = "Frontend-CDN"
    ManagedBy  = "Terraform"
  }
}
