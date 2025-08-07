# GitHub Secrets Setup Guide

This document explains how to configure the required GitHub repository secrets for the CI/CD pipeline.

## Required Secrets

Configure these secrets in your GitHub repository settings (`Settings` → `Secrets and variables` → `Actions`):

### Qovery Configuration Secrets

| Secret Name | Description | How to Get |
|-------------|-------------|------------|
| `QOVERY_CLI_ACCESS_TOKEN` | Qovery CLI access token | `qovery auth` command |
| `QOVERY_ORGANIZATION_ID` | Your Qovery organization ID | `qovery organization list` |
| `QOVERY_PROJECT_ID` | Your Qovery project ID | `qovery project list` |
| `QOVERY_ENVIRONMENT_ID` | Your Qovery environment ID | `qovery environment list` |
| `QOVERY_BACKEND_APPLICATION_ID` | Backend app ID in Qovery | `qovery application list` |
| `QOVERY_FRONTEND_APPLICATION_ID` | Frontend app ID in Qovery | `qovery application list` |
| `QOVERY_LOAD_GENERATOR_APPLICATION_ID` | Load generator app ID (optional) | `qovery application list` |
| `QOVERY_SEED_DATA_JOB_ID` | Seed data job ID (optional) | `qovery job list` |

## Step-by-Step Setup

### 1. Install Qovery CLI

```bash
# Install Qovery CLI
curl -s https://get.qovery.com | bash

# Or via package managers:
# brew install qovery-cli
# scoop install qovery-cli
```

### 2. Authenticate with Qovery

```bash
# Login to Qovery
qovery auth

# This will open a browser window for authentication
# Follow the prompts to generate an access token
```

Copy the generated access token and add it as `QOVERY_CLI_ACCESS_TOKEN` secret in GitHub.

### 3. Get Organization ID

```bash
qovery organization list
```

Example output:
```
NAME           ID                                   
My Organization 12345678-1234-1234-1234-123456789012
```

Copy the ID and add it as `QOVERY_ORGANIZATION_ID` secret.

### 4. Get Project ID

```bash
qovery project list
```

Example output:
```
NAME      ID                                   ORGANIZATION        
doktolib  87654321-4321-4321-4321-210987654321 My Organization
```

Copy the ID and add it as `QOVERY_PROJECT_ID` secret.

### 5. Get Environment ID

```bash
qovery environment list
```

Example output:
```
NAME    ID                                   PROJECT   STATUS  
preview abcdef12-3456-7890-abcd-ef1234567890 doktolib  RUNNING
production ghijkl34-5678-9012-ghij-kl3456789012 doktolib  RUNNING
```

Copy the appropriate environment ID and add it as `QOVERY_ENVIRONMENT_ID` secret.

### 6. Create Qovery Applications

Before getting application IDs, you need to create the applications in Qovery:

#### Backend Application

```bash
qovery application create \
  --name "doktolib-backend" \
  --container-image "ghcr.io/your-username/doktolib/backend" \
  --container-image-tag "latest" \
  --port 8080 \
  --environment-variable "PORT=8080" \
  --environment-variable "GIN_MODE=release" \
  --environment-variable "DATABASE_URL=${{ qovery.database.DATABASE_URL }}" \
  --environment-variable "DB_SSL_MODE=require"
```

#### Frontend Application

```bash
qovery application create \
  --name "doktolib-frontend" \
  --container-image "ghcr.io/your-username/doktolib/frontend" \
  --container-image-tag "latest" \
  --port 3000 \
  --environment-variable "PORT=3000" \
  --environment-variable "NODE_ENV=production"
```

#### Load Generator (Optional)

```bash
qovery application create \
  --name "doktolib-load-generator" \
  --container-image "ghcr.io/your-username/doktolib/load-generator" \
  --container-image-tag "latest" \
  --environment-variable "API_URL=https://your-backend-url.qovery.io" \
  --environment-variable "SCENARIO=light" \
  --environment-variable "DURATION_MINUTES=5"
```

#### Seed Data Job (Optional)

```bash
qovery job create \
  --name "doktolib-seed-data" \
  --container-image "ghcr.io/your-username/doktolib/seed-data" \
  --container-image-tag "latest" \
  --schedule "on_start" \
  --environment-variable "DATABASE_URL=${{ qovery.database.DATABASE_URL }}" \
  --environment-variable "DB_SSL_MODE=require" \
  --environment-variable "DOCTOR_COUNT=1500" \
  --environment-variable "FORCE_SEED=false"
```

### 7. Get Application and Job IDs

**Get Application IDs:**
```bash
qovery application list
```

Example output:
```
NAME                   ID                                   ENVIRONMENT STATUS  
doktolib-backend       backend123-4567-8901-2345-678901234 preview     RUNNING
doktolib-frontend      frontend456-7890-1234-5678-901234567 preview     RUNNING  
doktolib-load-generator loadgen789-0123-4567-8901-234567890 preview     STOPPED
```

**Get Job IDs:**
```bash
qovery job list
```

Example output:
```
NAME                 ID                                   ENVIRONMENT STATUS  
doktolib-seed-data   seedjob123-4567-8901-2345-678901234 preview     SUCCESS
```

Copy the IDs and add them as GitHub secrets:
- `QOVERY_BACKEND_APPLICATION_ID`
- `QOVERY_FRONTEND_APPLICATION_ID` 
- `QOVERY_LOAD_GENERATOR_APPLICATION_ID`
- `QOVERY_SEED_DATA_JOB_ID`

## Database Setup

### Create Database

```bash
qovery database create \
  --name "doktolib-postgres" \
  --type "POSTGRESQL" \
  --version "15" \
  --mode "MANAGED"
```

### Get Database Connection Info

The database URL will be automatically injected as an environment variable in your applications:
- `QOVERY_DATABASE_DOKTOLIB_POSTGRES_DATABASE_URL`

Update your backend application to use this environment variable:

```bash
qovery application update \
  --application $QOVERY_BACKEND_APPLICATION_ID \
  --environment-variable "DATABASE_URL=${{ qovery.database.QOVERY_DATABASE_DOKTOLIB_POSTGRES_DATABASE_URL }}"
```

## Custom Domains (Optional)

### Add Custom Domain

```bash
qovery application domain create \
  --application $QOVERY_FRONTEND_APPLICATION_ID \
  --domain "app.yourdomain.com"

qovery application domain create \
  --application $QOVERY_BACKEND_APPLICATION_ID \
  --domain "api.yourdomain.com"
```

### Update Environment Variables

Update frontend application to use custom backend domain:

```bash
qovery application update \
  --application $QOVERY_FRONTEND_APPLICATION_ID \
  --environment-variable "NEXT_PUBLIC_API_URL=https://api.yourdomain.com"
```

## Environment Variables Summary

### Backend Application
```bash
PORT=8080
GIN_MODE=release
DATABASE_URL=${{ qovery.database.DATABASE_URL }}
DB_SSL_MODE=require
```

### Frontend Application
```bash
PORT=3000
NODE_ENV=production
NEXT_PUBLIC_API_URL=https://api.yourdomain.com
```

### Load Generator
```bash
API_URL=https://api.yourdomain.com
SCENARIO=light
DURATION_MINUTES=5
LOG_LEVEL=info
```

## Verification

### Test CLI Access

```bash
# Verify authentication
qovery auth whoami

# Test organization access
qovery organization list

# Test project access
qovery project list

# Test application access
qovery application list
```

### Test Deployment

```bash
# Manual deployment test
qovery application deploy \
  --application $QOVERY_BACKEND_APPLICATION_ID \
  --image-tag "latest" \
  --watch
```

## Security Best Practices

1. **Never commit secrets to version control**
2. **Use environment-specific secrets** for different deployments
3. **Rotate access tokens regularly**
4. **Use least-privilege access** - only grant necessary permissions
5. **Monitor secret usage** through GitHub audit logs

## Troubleshooting

### Common Issues

**Invalid Token:**
- Re-run `qovery auth` to generate a new token
- Check token expiration

**Permission Denied:**
- Verify organization/project access
- Check Qovery user permissions

**Application Not Found:**
- Verify application IDs are correct
- Check if applications exist in the specified environment

**Database Connection Issues:**
- Verify database is created and running
- Check environment variable names
- Test database connectivity

### Debug Commands

```bash
# Check current authentication
qovery auth whoami

# List all resources
qovery organization list
qovery project list  
qovery environment list
qovery application list
qovery database list

# Check application status
qovery application status --application $APP_ID

# View application logs
qovery application logs --application $APP_ID --follow
```

## Support

For additional help:
- [Qovery Documentation](https://hub.qovery.com/docs/)
- [Qovery Community](https://discuss.qovery.com/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)