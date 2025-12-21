# Qovery Deployment Guide for Doktolib

This guide explains how to deploy the complete Doktolib application stack using Qovery with Terraform.

## Overview

The Qovery Terraform configuration deploys:
- **PostgreSQL Database** (containerized or managed RDS Aurora)
- **Backend API** (Go + Gin framework)
- **Frontend Application** (Next.js)
- **Seed Data Job** (Node.js - populates database)
- **Load Generator** (optional - for performance testing)

All services are deployed with:
- Automatic health checks
- Auto-scaling capabilities
- Sequential deployment stages
- Environment variable management
- SSL/TLS encryption

## Prerequisites

### 1. Qovery Account

Sign up at: https://www.qovery.com/

### 2. Qovery CLI (Optional but Recommended)

```bash
# macOS
brew tap qovery/qovery-cli
brew install qovery-cli

# Linux/WSL
curl -s https://get.qovery.com | bash

# Login
qovery auth
```

### 3. Get Qovery IDs

#### Option A: Via Qovery CLI

```bash
# Get organization ID
qovery organization list

# Get project ID
qovery project list

# Get cluster ID
qovery cluster list
```

#### Option B: Via Qovery Console

1. Go to: https://console.qovery.com
2. **Organization ID**: Organization Settings → API
3. **Project ID**: Click on your project → URL shows project ID
4. **Cluster ID**: Clusters → Click on cluster → URL shows cluster ID

### 4. Create Qovery API Token

```bash
# Via Qovery Console
# 1. Go to: https://console.qovery.com
# 2. Organization Settings → API
# 3. Click "Generate Token"
# 4. Copy the token (starts with "qov_")

# Or via CLI
qovery token
```

### 5. Terraform Installed

```bash
# macOS
brew install terraform

# Linux
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
```

## Quick Start

### 1. Configure Qovery Credentials

```bash
# Copy example configuration
cp qovery.tfvars.example qovery.tfvars

# Edit with your Qovery details
vim qovery.tfvars
```

Required configuration:

```hcl
qovery_access_token    = "qov_your_token_here"
qovery_organization_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
qovery_project_id      = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
qovery_cluster_id      = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

git_repository_url = "https://github.com/evoxmusic/qovery-doktolib"
git_branch         = "main"

environment_name = "doktolib-production"
environment_mode = "PRODUCTION"
```

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Review Deployment Plan

```bash
terraform plan -var-file="qovery.tfvars"
```

This will show you:
- 1 Environment
- 4 Deployment Stages
- 1 Database (PostgreSQL)
- 2 Applications (Backend, Frontend)
- 1 Job (Seed Data)
- All environment variables and configurations

### 4. Deploy to Qovery

```bash
terraform apply -var-file="qovery.tfvars"
```

Type `yes` to confirm. Deployment takes approximately 10-15 minutes.

### 5. Get Deployment Information

```bash
# Get all application URLs
terraform output application_urls

# Get frontend URL
terraform output frontend_url

# Get backend URL
terraform output backend_url

# Get complete summary
terraform output deployment_summary
```

### 6. Access Your Application

```bash
# Frontend
open $(terraform output -raw frontend_url)

# Backend Health Check
curl $(terraform output -raw backend_url)/api/v1/health

# Qovery Console
open $(terraform output -raw environment_url)
```

## Configuration Options

### Database Options

#### Option 1: Qovery-Managed Container (Default)

```hcl
use_managed_database = false
```

**Pros:**
- Simple setup, no AWS account needed
- Included in Qovery pricing
- Good for development/staging

**Cons:**
- Limited scaling
- No built-in high availability

#### Option 2: AWS RDS Aurora Serverless

First, deploy Aurora using terraform/rds-aurora:

```bash
cd terraform/rds-aurora
./deploy.sh
# Note the connection details
```

Then configure Qovery:

```hcl
use_managed_database = true
managed_database_host = "doktolib-aurora.cluster-xxxxx.us-east-1.rds.amazonaws.com"
managed_database_port = "5432"
managed_database_name = "doktolib"
managed_database_user = "postgres"
managed_database_password = "your-secure-password"
```

**Pros:**
- Auto-scaling (0.5-128 ACUs)
- High availability (Multi-AZ)
- Automated backups
- Better performance at scale

**Cons:**
- Additional AWS cost (~$50-200/month)
- More complex setup

### Resource Allocation

#### Development Environment

```hcl
backend_cpu           = 250   # 0.25 CPU
backend_memory        = 256   # 256MB
backend_min_instances = 1
backend_max_instances = 1

frontend_cpu           = 250
frontend_memory        = 256
frontend_min_instances = 1
frontend_max_instances = 1
```

**Cost**: ~$20-30/month

#### Production Environment

```hcl
backend_cpu           = 1000  # 1 CPU
backend_memory        = 1024  # 1GB
backend_min_instances = 2
backend_max_instances = 10

frontend_cpu           = 1000
frontend_memory        = 1024
frontend_min_instances = 2
frontend_max_instances = 20
```

**Cost**: ~$100-500/month (depends on traffic)

### Auto-Deployment

```hcl
auto_deploy_enabled = true  # Deploy automatically on git push
```

When enabled:
- Push to `git_branch` triggers automatic deployment
- New Docker images are built
- Rolling update with zero downtime

### Seed Data Job

```hcl
enable_seed_job  = true
seed_num_doctors = "100"   # Number of doctors to generate
seed_force       = "false" # Don't override existing data
```

The seed job runs automatically when the environment starts. To run manually:

```bash
# Via Qovery Console
# 1. Go to Environment → Jobs → doktolib-seed-data
# 2. Click "Run Job"

# Via CLI
qovery job deploy --job-id $(terraform output -raw seed_job_id)
```

### Load Testing

```hcl
enable_load_generator = true
load_scenario         = "light"  # light, normal, heavy, stress
load_duration         = "5"      # minutes
```

**Load scenarios:**
- **light**: 15 concurrent users, 30 RPS
- **normal**: 75 concurrent users, 150 RPS
- **heavy**: 250 concurrent users, 500 RPS
- **stress**: 500 concurrent users, 1000 RPS

To run load tests:

```bash
# Start load generator
qovery application scale --application-id $(terraform output -raw load_generator_id) --instances 1

# Stop load generator
qovery application scale --application-id $(terraform output -raw load_generator_id) --instances 0
```

## Deployment Stages

The deployment happens in stages to ensure proper initialization:

```
Stage 1: Database
   ↓
Stage 2: Backend (waits for database)
   ↓
Stage 3: Frontend (waits for backend)
   ↓
Stage 4: Jobs (waits for backend)
```

Each stage must complete successfully before the next stage begins.

## Environment Variables

### Automatic Configuration

Qovery automatically configures:
- Database connection details (when using Qovery-managed DB)
- Internal service URLs
- SSL certificates
- Health check endpoints

### Custom Environment Variables

Add custom variables in `qovery.tf`:

```hcl
environment_variables = [
  {
    key   = "YOUR_CUSTOM_VAR"
    value = "your_value"
  }
]
```

### Secrets

For sensitive data:

```hcl
secrets = [
  {
    key   = "API_KEY"
    value = var.api_key
  }
]
```

## Monitoring and Debugging

### View Logs

```bash
# Via CLI
qovery application log --application-id <app-id> --follow

# Or use output helper
terraform output backend_console_url
# Click "Logs" tab in console
```

### Health Checks

```bash
# Backend health
curl $(terraform output -raw backend_url)/api/v1/health

# Expected response:
# {"status":"OK","database":"connected"}
```

### Application Status

```bash
# Via CLI
qovery application list

# Via Console
open $(terraform output -raw environment_url)
```

### Troubleshooting

**Issue: Application won't start**

```bash
# Check logs
qovery application log --application-id <app-id> --follow

# Check environment variables
qovery application env list --application-id <app-id>

# Restart application
qovery application restart --application-id <app-id>
```

**Issue: Database connection failed**

```bash
# Check database status
qovery database list

# Verify environment variables are set correctly
terraform output deployment_summary

# Check backend logs for connection errors
```

**Issue: Build failed**

```bash
# Check build logs in Qovery console
# Common issues:
# - Dockerfile not found (check root_path in git_repository)
# - Build dependencies missing
# - Docker image too large
```

## Updating Your Deployment

### Update Configuration

```bash
# Edit configuration
vim qovery.tfvars

# Apply changes
terraform apply -var-file="qovery.tfvars"
```

### Update Application Code

When `auto_deploy_enabled = true`:

```bash
# Push to git
git add .
git commit -m "Update application"
git push origin main

# Qovery automatically detects and deploys
```

When `auto_deploy_enabled = false`:

```bash
# Via CLI
qovery application deploy --application-id <app-id>

# Or via Terraform
terraform apply -var-file="qovery.tfvars"
```

### Scale Applications

```bash
# Update qovery.tfvars
backend_min_instances = 3
backend_max_instances = 10

# Apply changes
terraform apply -var-file="qovery.tfvars"
```

Or via CLI:

```bash
qovery application scale --application-id <app-id> --instances 5
```

## Complete Deployment Stack

After deploying with Qovery, complete your stack with:

### 1. Lambda Visio Health Check

```bash
cd terraform/visio-service
./deploy.sh

# Get health URL
terraform output health_endpoint

# Update Qovery configuration
vim qovery.tfvars
# Set: visio_health_url = "https://...lambda-url.../health"

terraform apply -var-file="qovery.tfvars"
```

### 2. Cloudflare CDN

```bash
cd terraform/cloudflare-cdn

# Configure
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars

# Set origin_url to Qovery frontend URL
# Get it with: cd ../.. && terraform output -raw cloudflare_origin_url

terraform init
terraform apply
```

### 3. RDS Aurora (Optional - Deployed via Terraform Service)

RDS Aurora is automatically deployed as a Terraform service when:
- `enable_rds_aurora = true` (default)
- `terraform_state_bucket` is configured

**No AWS credentials needed** - Qovery automatically injects cluster credentials using `use_cluster_credentials = true`.

To manually deploy or update:
```bash
# Ensure terraform_state_bucket is configured in qovery.tfvars
terraform_state_bucket = "doktolib-terraform-state"
terraform_state_region = "us-east-1"

# Apply configuration - RDS Aurora will be deployed as a Terraform service
terraform apply -var-file="qovery.tfvars"

# Once deployed, update managed database configuration
vim qovery.tfvars
# Set use_managed_database = true
# Configure managed_database_* variables with Aurora endpoint

terraform apply -var-file="qovery.tfvars"
```

## Cost Estimation

### Qovery Costs

Based on resource allocation:

**Development** (~$20-30/month):
- Backend: 0.25 CPU, 256MB RAM, 1 instance
- Frontend: 0.25 CPU, 256MB RAM, 1 instance
- Database: Container, 10GB storage

**Staging** (~$50-80/month):
- Backend: 0.5 CPU, 512MB RAM, 1-2 instances
- Frontend: 0.5 CPU, 512MB RAM, 1-3 instances
- Database: Container, 10GB storage

**Production** (~$100-500/month):
- Backend: 1 CPU, 1GB RAM, 2-10 instances
- Frontend: 1 CPU, 1GB RAM, 2-20 instances
- Database: Container or RDS Aurora

### Additional Costs

- **RDS Aurora Serverless**: ~$50-200/month
- **Lambda Visio Service**: ~$0.20-2/month
- **Cloudflare CDN**: FREE (Free tier sufficient)

**Total Production Cost**: ~$150-700/month depending on traffic

## Best Practices

1. **Use Staging Environment**: Test changes before production
2. **Enable Auto-Deploy**: For faster iteration
3. **Monitor Costs**: Check Qovery billing regularly
4. **Use Managed Database**: For production workloads
5. **Configure Alerts**: Set up Qovery alerts for failures
6. **Regular Backups**: Enable database backups
7. **Secrets Management**: Never commit secrets to git
8. **Resource Limits**: Set appropriate CPU/memory limits
9. **Health Checks**: Always configure health checks
10. **Logging**: Aggregate logs for debugging

## Cleanup

To destroy the entire environment:

```bash
terraform destroy -var-file="qovery.tfvars"
```

**Warning**: This will permanently delete:
- All applications
- Database and data
- Environment configuration
- Deployment stages

## Support

- **Qovery Documentation**: https://hub.qovery.com/
- **Qovery Discord**: https://discord.qovery.com/
- **Terraform Provider**: https://registry.terraform.io/providers/Qovery/qovery/latest/docs
- **GitHub Issues**: https://github.com/evoxmusic/qovery-doktolib/issues

## Next Steps

1. Deploy to Qovery: `terraform apply -var-file="qovery.tfvars"`
2. Verify deployment: Check Qovery console
3. Test applications: Visit frontend and backend URLs
4. Run seed job: Populate database with test data
5. Configure Cloudflare: Add CDN for better performance
6. Deploy Lambda: Add visio health check
7. Monitor: Watch logs and metrics in Qovery console

## License

This deployment configuration is part of the Doktolib project and is provided for demonstration purposes.
