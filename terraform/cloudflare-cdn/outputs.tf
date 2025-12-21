output "zone_id" {
  description = "Cloudflare Zone ID"
  value       = data.cloudflare_zone.domain.id
}

output "zone_name" {
  description = "Cloudflare Zone name"
  value       = data.cloudflare_zone.domain.name
}

output "frontend_url" {
  description = "Frontend application URL"
  value       = "https://${var.frontend_subdomain}.${var.domain_name}"
}

output "frontend_dns_record_id" {
  description = "DNS record ID for frontend"
  value       = cloudflare_record.frontend.id
}

output "frontend_dns_record_hostname" {
  description = "Frontend DNS hostname"
  value       = cloudflare_record.frontend.hostname
}

output "www_dns_record_id" {
  description = "DNS record ID for www subdomain"
  value       = var.create_www_redirect ? cloudflare_record.frontend_www[0].id : null
}

output "ssl_status" {
  description = "SSL/TLS mode"
  value       = cloudflare_zone_settings_override.frontend_settings.settings[0].ssl
}

output "cloudflare_nameservers" {
  description = "Cloudflare nameservers for domain"
  value       = data.cloudflare_zone.domain.name_servers
}

output "health_check_id" {
  description = "Health check ID (if enabled)"
  value       = var.create_health_check ? cloudflare_healthcheck.frontend[0].id : null
}

output "cache_purge_command" {
  description = "Command to purge Cloudflare cache"
  value       = "curl -X POST 'https://api.cloudflare.com/client/v4/zones/${data.cloudflare_zone.domain.id}/purge_cache' -H 'Authorization: Bearer $CLOUDFLARE_API_TOKEN' -H 'Content-Type: application/json' --data '{\"purge_everything\":true}'"
}

output "cloudflare_dashboard_url" {
  description = "Cloudflare dashboard URL for this zone"
  value       = "https://dash.cloudflare.com/${data.cloudflare_zone.domain.account_id}/${data.cloudflare_zone.domain.id}"
}

# Configuration summary
output "configuration_summary" {
  description = "Summary of Cloudflare configuration"
  value = {
    domain                = "${var.frontend_subdomain}.${var.domain_name}"
    origin                = var.origin_url
    ssl_mode              = "full"
    caching_enabled       = true
    security_level        = var.security_level
    rate_limiting_enabled = true
    health_check_enabled  = var.create_health_check
    www_redirect_enabled  = var.create_www_redirect
  }
}

# DNS configuration for domain registrar
output "dns_configuration_instructions" {
  description = "Instructions for configuring DNS at your domain registrar"
  value = <<-EOT
    Configure your domain registrar to use Cloudflare nameservers:

    Nameservers:
    ${join("\n    ", data.cloudflare_zone.domain.name_servers)}

    Once nameservers are updated (can take 24-48 hours):
    1. Your site will be: https://${var.frontend_subdomain}.${var.domain_name}
    2. Cloudflare CDN will be active
    3. SSL/TLS will be enabled automatically

    To verify:
    dig ${var.frontend_subdomain}.${var.domain_name}
    curl -I https://${var.frontend_subdomain}.${var.domain_name}
  EOT
}
