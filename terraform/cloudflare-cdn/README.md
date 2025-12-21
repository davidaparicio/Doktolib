# Cloudflare CDN for Doktolib Frontend

This Terraform configuration sets up Cloudflare as a CDN and security layer in front of your Doktolib frontend application hosted on Qovery.

## Overview

Cloudflare provides:
- **Global CDN**: Cache static assets at 300+ edge locations worldwide
- **SSL/TLS**: Automatic HTTPS with free SSL certificates
- **DDoS Protection**: Built-in protection against attacks
- **Bot Management**: Block malicious bots and scrapers
- **Rate Limiting**: Protect against abuse
- **Performance**: Auto-minification, Brotli compression, HTTP/3
- **Analytics**: Traffic insights and performance metrics

## Architecture

```
User Browser
    ↓
Cloudflare CDN (300+ edge locations)
    ↓ (Cache MISS or dynamic content)
Qovery Origin (your Next.js app)
```

**Benefits**:
- **Faster load times**: Content served from edge locations near users
- **Reduced origin load**: Static assets cached at edge
- **Better security**: DDoS protection, WAF, bot management
- **99.99% uptime**: Cloudflare's global network

## Prerequisites

1. **Cloudflare Account** (free tier is sufficient)
   - Sign up at: https://dash.cloudflare.com/sign-up

2. **Domain added to Cloudflare**
   - Add your domain: https://dash.cloudflare.com/
   - Update nameservers at your registrar
   - Wait for activation (usually < 24 hours)

3. **Cloudflare API Token**
   - Create at: https://dash.cloudflare.com/profile/api-tokens
   - Template: "Edit zone DNS"
   - Permissions needed:
     - Zone → Zone Settings → Edit
     - Zone → Zone → Edit
     - Zone → DNS → Edit

4. **Frontend Application URL** from Qovery
   - Get from Qovery dashboard or CLI:
     ```bash
     qovery application list
     ```

5. **Terraform** installed (v1.0+)

## Quick Start

### 1. Create Cloudflare API Token

```bash
# Go to: https://dash.cloudflare.com/profile/api-tokens
# Click "Create Token"
# Use "Edit zone DNS" template
# Select your zone
# Create token and save it securely
```

### 2. Get Your Qovery Frontend URL

```bash
# From Qovery CLI
qovery application list

# Or from Qovery dashboard
# Navigate to: Environment → Applications → Frontend → External URL
# Example: doktolib-frontend-abc123.qovery.io
```

### 3. Configure Terraform

```bash
cd terraform/cloudflare-cdn
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
# Your Cloudflare API token
cloudflare_api_token = "YOUR_CLOUDFLARE_API_TOKEN"

# Your domain configuration
domain_name        = "doktolib.com"
frontend_subdomain = "app"  # Results in: app.doktolib.com

# Your Qovery frontend URL (without https://)
origin_url = "doktolib-frontend-abc123.qovery.io"
```

### 4. Deploy Cloudflare Configuration

```bash
terraform init
terraform plan
terraform apply
```

### 5. Verify DNS Configuration

```bash
# Check DNS resolution
dig app.doktolib.com

# Check SSL certificate
curl -I https://app.doktolib.com

# View configuration
terraform output configuration_summary
```

## Configuration Options

### Basic Configuration

```hcl
# terraform.tfvars
domain_name        = "doktolib.com"
frontend_subdomain = "app"
origin_url         = "doktolib-frontend-abc123.qovery.io"
```

This creates: `https://app.doktolib.com` → `https://doktolib-frontend-abc123.qovery.io`

### Root Domain Configuration

To use root domain instead of subdomain:

```hcl
frontend_subdomain = "@"  # Results in: doktolib.com
create_www_redirect = true # Redirects www.doktolib.com → doktolib.com
```

### Security Levels

```hcl
security_level = "medium"  # Options:
# - "off": No security checks
# - "essentially_off": Minimal security
# - "low": Some security checks
# - "medium": Balanced (recommended)
# - "high": Strict security
# - "under_attack": Maximum protection (shows challenges)
```

### Rate Limiting

```hcl
rate_limit_requests_per_5min = 100  # Requests per IP per 5 minutes
```

Adjust based on your traffic:
- **Low traffic**: 50-100
- **Medium traffic**: 100-300
- **High traffic**: 300-1000

### Cache Configuration

The configuration automatically caches:
- **Next.js static files** (`/_next/static/*`): 1 year
- **Images** (`.jpg`, `.png`, `.svg`, etc.): 30 days
- **Fonts** (`.woff`, `.woff2`, etc.): 1 year

Dynamic content and API routes are **not cached**.

### Optional Features

```hcl
create_www_redirect  = true   # Create www subdomain
create_admin_bypass  = true   # Bypass cache for /admin/*
create_api_bypass    = true   # Bypass cache for /api/* (recommended)
create_health_check  = true   # Enable health monitoring
```

## Cloudflare Settings Applied

### SSL/TLS
- **Mode**: Full (encryption between Cloudflare and origin)
- **Always Use HTTPS**: Enabled
- **Automatic HTTPS Rewrites**: Enabled
- **Minimum TLS Version**: 1.2
- **TLS 1.3**: Enabled

### Performance
- **Brotli Compression**: Enabled
- **HTTP/2**: Enabled
- **HTTP/3**: Enabled
- **Early Hints**: Enabled
- **Auto Minify**: CSS, JS, HTML

### Security
- **HSTS**: Enabled (max-age: 1 year)
- **Security Headers**: Added automatically
  - `X-Frame-Options: SAMEORIGIN`
  - `X-Content-Type-Options: nosniff`
  - `X-XSS-Protection: 1; mode=block`
  - `Referrer-Policy: strict-origin-when-cross-origin`

### Bot Protection
- **Block malicious bots**: Enabled
- **Allow search engines**: Enabled
- **Challenge suspicious traffic**: Enabled (threat score > 20)

## Testing Your Setup

### 1. Test DNS Resolution

```bash
# Check if DNS points to Cloudflare
dig app.doktolib.com

# Should show Cloudflare IPs (104.x.x.x or similar)
```

### 2. Test SSL Certificate

```bash
curl -I https://app.doktolib.com

# Should show:
# HTTP/2 200
# cf-ray: ... (Cloudflare serving)
# cf-cache-status: HIT or MISS
```

### 3. Test Caching

```bash
# First request (MISS)
curl -I https://app.doktolib.com/_next/static/some-file.js

# Second request (HIT)
curl -I https://app.doktolib.com/_next/static/some-file.js

# Check cf-cache-status header
```

### 4. Test Rate Limiting

```bash
# Send multiple rapid requests
for i in {1..150}; do
  curl -s -o /dev/null -w "%{http_code}\n" https://app.doktolib.com/api/test
done

# Should see 429 (Too Many Requests) after threshold
```

## Maintenance

### Purge Cache

After deploying new frontend code:

```bash
# Purge all cache
$(terraform output -raw cache_purge_command)

# Or via Terraform (set enable_cache_purge_on_deploy = true)
terraform apply

# Or via Cloudflare Dashboard
# Go to: Caching → Configuration → Purge Everything
```

### Update Configuration

```bash
# Edit terraform.tfvars
vim terraform.tfvars

# Apply changes
terraform plan
terraform apply
```

### View Cloudflare Analytics

```bash
# Get dashboard URL
terraform output cloudflare_dashboard_url

# Or visit: https://dash.cloudflare.com
```

## Monitoring

### Cloudflare Analytics

View in dashboard:
1. Total requests
2. Bandwidth saved
3. Threats blocked
4. Cache hit ratio
5. Geographic distribution

### Health Checks

If enabled (`create_health_check = true`):
- Checks frontend availability every 60 seconds
- Monitors from multiple regions
- Alerts on failures (configure in Cloudflare dashboard)

### Logs

Cloudflare doesn't provide full logs in free tier. Upgrade to Pro ($20/month) for:
- Request logs
- Firewall event logs
- Advanced analytics

## Cost

### Cloudflare Free Tier (included)
- Unlimited DDoS protection
- Global CDN
- Free SSL certificates
- 100,000 requests/day (soft limit)
- Basic analytics

**Cost**: FREE

### Cloudflare Pro ($20/month)
- Everything in Free
- Advanced DDoS
- WAF (Web Application Firewall)
- Image optimization
- 20+ Page Rules
- Full logs

### Cloudflare Business ($200/month)
- Everything in Pro
- Custom SSL certificates
- 100% uptime SLA
- Priority support
- Advanced security

**For Doktolib, the Free tier is sufficient.**

## Troubleshooting

### Issue: DNS not resolving

**Solution**: Check nameservers at your domain registrar
```bash
dig NS doktolib.com

# Should show Cloudflare nameservers:
# ... cloudflare.com
```

If not, update nameservers at your registrar with values from:
```bash
terraform output cloudflare_nameservers
```

### Issue: SSL errors

**Solution**: Check SSL/TLS mode in Cloudflare
```bash
# Verify mode is "Full" not "Flexible"
terraform output ssl_status
```

If using "Full", ensure your Qovery origin has a valid SSL certificate.

### Issue: Cache not working

**Solution**: Check cache status header
```bash
curl -I https://app.doktolib.com/_next/static/test.js | grep cf-cache-status

# Should show: HIT (cached) or MISS (not cached yet)
```

If always MISS, check Page Rules in Cloudflare dashboard.

### Issue: Origin errors (502/503)

**Solution**: Check Qovery application status
```bash
qovery application status

# Verify origin URL is correct
terraform output configuration_summary
```

### Issue: Rate limiting too aggressive

**Solution**: Increase threshold
```hcl
# terraform.tfvars
rate_limit_requests_per_5min = 300  # Increase from 100

terraform apply
```

## Security Best Practices

1. **Secure API Token**: Never commit `terraform.tfvars` to git
2. **Use Full SSL Mode**: Not "Flexible" (insecure)
3. **Enable HSTS**: Automatically enabled in this config
4. **Monitor Firewall Events**: Check Cloudflare dashboard regularly
5. **Keep Security Level at Medium+**: Don't use "low" or "off" in production
6. **Enable Bot Management**: Automatically configured
7. **Review Page Rules**: Ensure sensitive paths bypass cache

## Integration with Qovery

### Option 1: Manual Update

When Qovery updates your frontend URL:

```hcl
# terraform.tfvars
origin_url = "new-doktolib-frontend-xyz789.qovery.io"

terraform apply
```

### Option 2: Automated with CI/CD

In your GitHub Actions workflow:

```yaml
- name: Update Cloudflare CDN
  env:
    CLOUDFLARE_API_TOKEN: ${{ secrets.CLOUDFLARE_API_TOKEN }}
  run: |
    cd terraform/cloudflare-cdn
    terraform init
    terraform apply -auto-approve \
      -var="origin_url=${{ env.QOVERY_FRONTEND_URL }}"
```

### Option 3: Use Qovery Custom Domain

Instead of Cloudflare DNS, use Qovery's custom domain feature and let Qovery handle DNS, then use Cloudflare only for CDN caching via CNAME setup.

## Advanced Features

### Custom Cache Rules

Add custom cache rules in `main.tf`:

```hcl
resource "cloudflare_ruleset" "custom_cache" {
  zone_id = data.cloudflare_zone.domain.id
  name    = "Custom cache rules"
  kind    = "zone"
  phase   = "http_request_cache_settings"

  rules {
    action = "set_cache_settings"
    expression = "(http.request.uri.path contains \"/blog/\")"

    action_parameters {
      cache = true
      edge_ttl {
        mode = "override_origin"
        default = 86400  # 24 hours
      }
    }
  }
}
```

### Geographic Blocking

Block specific countries:

```hcl
resource "cloudflare_ruleset" "geo_block" {
  zone_id = data.cloudflare_zone.domain.id
  name    = "Geographic blocking"
  kind    = "zone"
  phase   = "http_request_firewall_custom"

  rules {
    action = "block"
    expression = "(ip.geoip.country in {\"XX\" \"YY\"})"
  }
}
```

### Custom Error Pages

Create custom 404/500 pages in Cloudflare dashboard:
1. Go to: Customization → Error Pages
2. Upload custom HTML for each error code

## Cleanup

To remove Cloudflare configuration:

```bash
terraform destroy
```

**Warning**: This will:
- Remove DNS records
- Disable CDN
- Remove firewall rules
- Your site will be inaccessible until you reconfigure DNS

## Resources

- [Cloudflare Documentation](https://developers.cloudflare.com/)
- [Terraform Cloudflare Provider](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs)
- [Cloudflare Dashboard](https://dash.cloudflare.com/)
- [Cloudflare Status](https://www.cloudflarestatus.com/)

## Support

- **Cloudflare Community**: https://community.cloudflare.com/
- **Terraform Discussions**: https://discuss.hashicorp.com/
- **Qovery Discord**: https://discord.qovery.com/

## License

This Terraform configuration is part of the Doktolib project and is provided for demonstration purposes.
