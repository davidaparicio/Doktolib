# Doktolib Terraform Configuration

This directory contains Terraform configuration files to deploy the Doktolib application using Qovery.

## Prerequisites

1. **Qovery Account**: You need a Qovery account and an API token
2. **Terraform**: Install Terraform >= 1.0
3. **Git Repository**: Your code should be in a Git repository accessible by Qovery

## Quick Start

1. **Copy the variables file**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Fill in your values in `terraform.tfvars`**:
   ```hcl
   qovery_api_token       = "your-qovery-api-token"
   qovery_organization_id = "your-organization-id"
   qovery_cluster_id      = "your-cluster-id"
   git_repository_url     = "https://github.com/your-username/doktolib.git"
   ```

3. **Initialize Terraform**:
   ```bash
   terraform init
   ```

4. **Plan the deployment**:
   ```bash
   terraform plan
   ```

5. **Apply the configuration**:
   ```bash
   terraform apply
   ```

## What Gets Deployed

### Infrastructure
- **Qovery Project**: `doktolib`
- **Environment**: `production`
- **PostgreSQL Database**: Version 15, 10GB storage
- **Backend Application**: Golang API (0.5 vCPU, 512MB RAM)
- **Frontend Application**: Next.js app (0.5 vCPU, 512MB RAM)

### Features
- **Auto-deployment**: Automatically deploys on git push to main branch
- **Health checks**: Both applications have readiness and liveness probes
- **SSL certificates**: Automatic HTTPS with Let's Encrypt
- **Database connection**: Automatic database URL injection
- **Custom domain support**: Optional custom domain configuration

## Configuration

### Required Variables
- `qovery_api_token`: Your Qovery API token
- `qovery_organization_id`: Your Qovery organization ID
- `qovery_cluster_id`: The cluster where to deploy the application

### Optional Variables
- `git_repository_url`: Git repository URL (default: example URL)
- `custom_domain`: Custom domain for the frontend
- `environment_name`: Environment name (default: "production")
- `backend_cpu/memory`: Backend resource allocation
- `frontend_cpu/memory`: Frontend resource allocation
- `database_storage`: Database storage size in GB

## How to Get Required IDs

### Qovery API Token
1. Go to [Qovery Console](https://console.qovery.com)
2. Navigate to your organization settings
3. Go to "API Tokens" section
4. Create a new token

### Organization ID
1. In Qovery Console, go to your organization
2. The organization ID is in the URL: `https://console.qovery.com/platform/organization/{org-id}`

### Cluster ID
1. In Qovery Console, go to "Infrastructure" 
2. Select your cluster
3. The cluster ID is in the URL: `https://console.qovery.com/platform/organization/{org-id}/infrastructure/clusters/{cluster-id}`

## Outputs

After successful deployment, Terraform will output:
- **Frontend URL**: Your application's public URL
- **Backend URL**: API endpoint URL
- **Qovery Console URL**: Direct link to manage your deployment
- **Custom Domain URL**: If configured

## Environment Variables

The configuration automatically sets up:
- Database connection strings
- Service discovery between frontend and backend
- Health check endpoints
- SSL/TLS termination

## Customization

You can modify the `main.tf` file to:
- Add more environments (staging, development)
- Configure different resource sizes
- Add additional services (Redis, etc.)
- Set up monitoring and logging
- Configure autoscaling

## Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```

## Troubleshooting

1. **API Token Issues**: Make sure your token has the right permissions
2. **Git Repository Access**: Ensure Qovery can access your repository
3. **Resource Limits**: Check your cluster has enough resources
4. **Domain Configuration**: Verify DNS settings for custom domains

For more help, check the [Qovery Documentation](https://hub.qovery.com/docs/) or [Terraform Provider Documentation](https://registry.terraform.io/providers/qovery/qovery/latest/docs).