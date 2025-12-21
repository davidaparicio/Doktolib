terraform {
  required_version = ">= 1.0"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# Get zone information
data "cloudflare_zone" "domain" {
  name = var.domain_name
}

# DNS Record for frontend application
resource "cloudflare_record" "frontend" {
  zone_id = data.cloudflare_zone.domain.id
  name    = var.frontend_subdomain
  value   = var.origin_url
  type    = "CNAME"
  ttl     = 1 # Auto (orange cloud)
  proxied = true # Enable Cloudflare proxy (CDN)

  comment = "Doktolib frontend application - managed by Terraform"
}

# DNS Record for www (optional)
resource "cloudflare_record" "frontend_www" {
  count = var.create_www_redirect ? 1 : 0

  zone_id = data.cloudflare_zone.domain.id
  name    = "www.${var.frontend_subdomain}"
  value   = var.origin_url
  type    = "CNAME"
  ttl     = 1
  proxied = true

  comment = "Doktolib frontend WWW redirect - managed by Terraform"
}

# Page Rules for caching and optimization
resource "cloudflare_page_rule" "cache_static_assets" {
  zone_id  = data.cloudflare_zone.domain.id
  target   = "${var.frontend_subdomain}.${var.domain_name}/_next/static/*"
  priority = 1

  actions {
    cache_level         = "cache_everything"
    edge_cache_ttl      = 31536000 # 1 year for immutable assets
    browser_cache_ttl   = 31536000
    cache_on_cookie     = ".*"
  }
}

resource "cloudflare_page_rule" "cache_images" {
  zone_id  = data.cloudflare_zone.domain.id
  target   = "${var.frontend_subdomain}.${var.domain_name}/*.(jpg|jpeg|png|gif|ico|svg|webp|avif)"
  priority = 2

  actions {
    cache_level         = "cache_everything"
    edge_cache_ttl      = 2592000 # 30 days
    browser_cache_ttl   = 2592000
    cache_on_cookie     = ".*"
  }
}

resource "cloudflare_page_rule" "cache_fonts" {
  zone_id  = data.cloudflare_zone.domain.id
  target   = "${var.frontend_subdomain}.${var.domain_name}/*.(woff|woff2|ttf|eot|otf)"
  priority = 3

  actions {
    cache_level         = "cache_everything"
    edge_cache_ttl      = 31536000 # 1 year
    browser_cache_ttl   = 31536000
    cache_on_cookie     = ".*"
  }
}

resource "cloudflare_page_rule" "bypass_admin" {
  count = var.create_admin_bypass ? 1 : 0

  zone_id  = data.cloudflare_zone.domain.id
  target   = "${var.frontend_subdomain}.${var.domain_name}/admin/*"
  priority = 4

  actions {
    cache_level = "bypass"
  }
}

resource "cloudflare_page_rule" "bypass_api" {
  count = var.create_api_bypass ? 1 : 0

  zone_id  = data.cloudflare_zone.domain.id
  target   = "${var.frontend_subdomain}.${var.domain_name}/api/*"
  priority = 5

  actions {
    cache_level = "bypass"
  }
}

# Firewall Rules
resource "cloudflare_ruleset" "rate_limiting" {
  zone_id     = data.cloudflare_zone.domain.id
  name        = "Rate limiting for ${var.frontend_subdomain}"
  description = "Rate limiting rules for Doktolib frontend"
  kind        = "zone"
  phase       = "http_ratelimit"

  rules {
    action = "block"
    description = "Rate limit aggressive requests"

    expression = "(http.request.uri.path contains \"/api/\" and rate(5m) > ${var.rate_limit_requests_per_5min})"

    action_parameters {
      response {
        status_code = 429
        content = jsonencode({
          error = "Rate limit exceeded"
          message = "Too many requests. Please try again later."
        })
        content_type = "application/json"
      }
    }
  }
}

# Firewall rule to block common threats
resource "cloudflare_ruleset" "security" {
  zone_id     = data.cloudflare_zone.domain.id
  name        = "Security rules for ${var.frontend_subdomain}"
  description = "Security and bot protection for Doktolib frontend"
  kind        = "zone"
  phase       = "http_request_firewall_custom"

  # Block known bad bots
  rules {
    action = "block"
    description = "Block known bad bots"
    expression = "(cf.client.bot) and not (cf.verified_bot_category in {\"Search Engine Crawler\" \"Advertising and Marketing\" \"Monitoring and Analytics\"})"
  }

  # Challenge suspicious traffic
  rules {
    action = "challenge"
    description = "Challenge suspicious traffic"
    expression = "(cf.threat_score > 20)"
  }
}

# SSL/TLS settings
resource "cloudflare_zone_settings_override" "frontend_settings" {
  zone_id = data.cloudflare_zone.domain.id

  settings {
    # SSL/TLS
    ssl                      = "full" # or "strict" if origin has valid cert
    always_use_https         = "on"
    automatic_https_rewrites = "on"
    min_tls_version          = "1.2"
    tls_1_3                  = "on"

    # Performance
    brotli                   = "on"
    early_hints              = "on"
    http2                    = "on"
    http3                    = "on"
    zero_rtt                 = "on"
    minify {
      css  = "on"
      js   = "on"
      html = "on"
    }

    # Security
    security_header {
      enabled = true
      max_age = 31536000
      include_subdomains = true
      preload = true
      nosniff = true
    }

    # Caching
    browser_cache_ttl        = 14400 # 4 hours
    browser_check            = "on"

    # DDoS & Bot Protection
    challenge_ttl            = 1800
    security_level           = var.security_level

    # Other
    opportunistic_encryption = "on"
    opportunistic_onion      = "on"
    pseudo_ipv4              = "off"
    ip_geolocation           = "on"
    websockets               = "on"
  }
}

# Transform Rules for Headers
resource "cloudflare_ruleset" "transform_headers" {
  zone_id     = data.cloudflare_zone.domain.id
  name        = "Transform response headers"
  description = "Add security and performance headers"
  kind        = "zone"
  phase       = "http_response_headers_transform"

  rules {
    action = "rewrite"
    description = "Add security headers"
    expression = "(http.host eq \"${var.frontend_subdomain}.${var.domain_name}\")"

    action_parameters {
      headers {
        name      = "X-Frame-Options"
        operation = "set"
        value     = "SAMEORIGIN"
      }
      headers {
        name      = "X-Content-Type-Options"
        operation = "set"
        value     = "nosniff"
      }
      headers {
        name      = "X-XSS-Protection"
        operation = "set"
        value     = "1; mode=block"
      }
      headers {
        name      = "Referrer-Policy"
        operation = "set"
        value     = "strict-origin-when-cross-origin"
      }
      headers {
        name      = "Permissions-Policy"
        operation = "set"
        value     = "geolocation=(), microphone=(), camera=()"
      }
    }
  }
}

# Cache Rules (new Cloudflare API)
resource "cloudflare_ruleset" "cache_rules" {
  zone_id     = data.cloudflare_zone.domain.id
  name        = "Cache rules for frontend"
  description = "Custom caching rules for Next.js application"
  kind        = "zone"
  phase       = "http_request_cache_settings"

  # Cache Next.js static assets
  rules {
    action = "set_cache_settings"
    description = "Cache Next.js static files"
    expression = "(http.request.uri.path contains \"/_next/static/\")"

    action_parameters {
      cache = true
      edge_ttl {
        mode = "override_origin"
        default = 31536000 # 1 year
      }
      browser_ttl {
        mode = "override_origin"
        default = 31536000
      }
    }
  }

  # Cache images
  rules {
    action = "set_cache_settings"
    description = "Cache images"
    expression = "(http.request.uri.path matches \"\\.(jpg|jpeg|png|gif|ico|svg|webp|avif)$\")"

    action_parameters {
      cache = true
      edge_ttl {
        mode = "override_origin"
        default = 2592000 # 30 days
      }
      browser_ttl {
        mode = "override_origin"
        default = 604800 # 7 days
      }
    }
  }

  # Bypass cache for API routes
  rules {
    action = "set_cache_settings"
    description = "Bypass cache for API routes"
    expression = "(http.request.uri.path contains \"/api/\")"

    action_parameters {
      cache = false
    }
  }
}

# Health check (optional)
resource "cloudflare_healthcheck" "frontend" {
  count = var.create_health_check ? 1 : 0

  zone_id     = data.cloudflare_zone.domain.id
  name        = "doktolib-frontend-health"
  address     = "${var.frontend_subdomain}.${var.domain_name}"
  type        = "HTTPS"
  port        = 443
  interval    = 60
  retries     = 2
  timeout     = 5
  method      = "GET"
  path        = "/"
  description = "Health check for Doktolib frontend"

  check_regions = [
    "WNAM", # Western North America
    "ENAM", # Eastern North America
    "WEU",  # Western Europe
    "EEU",  # Eastern Europe
  ]
}

# Cache Purge on deployment (via null_resource trigger)
resource "terraform_data" "cache_purge_trigger" {
  count = var.enable_cache_purge_on_deploy ? 1 : 0

  input = timestamp()

  provisioner "local-exec" {
    command = <<-EOT
      curl -X POST "https://api.cloudflare.com/client/v4/zones/${data.cloudflare_zone.domain.id}/purge_cache" \
        -H "Authorization: Bearer ${var.cloudflare_api_token}" \
        -H "Content-Type: application/json" \
        --data '{"purge_everything":true}'
    EOT
  }
}
