# GitHub Actions CI/CD Pipeline

This repository includes a comprehensive CI/CD pipeline that automatically builds, tests, and deploys the Doktolib application to Qovery.

## Workflow Overview

The CI/CD pipeline (`ci-cd.yml`) performs the following steps:

1. **Build**: Builds Docker images for all services (backend, frontend, load-generator)
2. **Push**: Pushes images to GitHub Container Registry (GHCR)  
3. **Security Scan**: Runs vulnerability scans on all images
4. **Deploy**: Deploys to Qovery using the Qovery CLI
5. **Health Check**: Verifies deployment health
6. **Load Test**: Runs optional load testing
7. **Notify**: Sends deployment notifications

## Triggers

- **Push to main**: Full CI/CD pipeline with deployment
- **Pull Request**: Build and test only (no deployment)
- **Manual Dispatch**: Choose environment (preview/production)

## Required Secrets

Configure these secrets in your GitHub repository settings:

### Qovery Configuration
```
QOVERY_CLI_ACCESS_TOKEN          # Qovery CLI access token
QOVERY_ORGANIZATION_ID           # Your Qovery organization ID
QOVERY_PROJECT_ID                # Your Qovery project ID  
QOVERY_ENVIRONMENT_ID            # Your Qovery environment ID
QOVERY_BACKEND_APPLICATION_ID    # Backend application ID in Qovery
QOVERY_FRONTEND_APPLICATION_ID   # Frontend application ID in Qovery
QOVERY_LOAD_GENERATOR_APPLICATION_ID  # Load generator application ID (optional)
```

### How to Get Qovery IDs

1. **CLI Access Token**: 
   ```bash
   qovery auth
   # Follow the prompts to generate a token
   ```

2. **Organization ID**:
   ```bash
   qovery organization list
   ```

3. **Project ID**:
   ```bash
   qovery project list
   ```

4. **Environment ID**:
   ```bash
   qovery environment list
   ```

5. **Application IDs**:
   ```bash
   qovery application list
   ```

## Container Images

Images are built with multi-architecture support (amd64/arm64) and pushed to:

- `ghcr.io/your-username/doktolib/backend:latest`
- `ghcr.io/your-username/doktolib/frontend:latest` 
- `ghcr.io/your-username/doktolib/load-generator:latest`

## Environment Configuration

### Preview Environment
- Automatic deployment on push to main
- Includes load testing
- Uses preview environment secrets

### Production Environment  
- Manual deployment via workflow dispatch
- Enhanced health checks
- Production environment secrets

## Security Features

- **Vulnerability Scanning**: Trivy scans all images
- **Attestation**: Build provenance attestation
- **Secrets Management**: All sensitive data in GitHub secrets
- **OIDC**: OpenID Connect for secure authentication

## Deployment Process

1. **Build Phase**: 
   - Parallel builds for all services
   - Multi-architecture support
   - Layer caching for faster builds

2. **Security Phase**:
   - Trivy vulnerability scans
   - Results uploaded to GitHub Security tab

3. **Deploy Phase**:
   - Sequential deployment (backend → frontend → load-generator)
   - Health checks after each service
   - Rollback on failure

4. **Validation Phase**:
   - API health endpoint checks
   - Frontend accessibility validation
   - Optional load testing

## Usage Examples

### Automatic Deployment
```bash
git push origin main  # Triggers full CI/CD pipeline
```

### Manual Deployment
1. Go to GitHub Actions tab
2. Select "CI/CD - Build and Deploy to Qovery"  
3. Click "Run workflow"
4. Choose environment (preview/production)

### Monitor Deployment
- Check GitHub Actions logs for detailed progress
- View deployment summary in workflow run
- Monitor application health in Qovery console

## Customization

### Adding New Services
1. Add service to build matrix in workflow
2. Create Qovery application
3. Add application ID to secrets
4. Update deployment steps

### Environment Variables
Modify build-args in the workflow matrix:
```yaml
build-args: |
  ENV_VAR_NAME=value
  ANOTHER_VAR=value
```

### Load Testing Configuration
Adjust load test parameters:
```yaml
- name: Run Load Test
  run: |
    docker run --rm \
      -e API_URL="${BACKEND_URL}" \
      -e SCENARIO=normal \        # light/normal/heavy/stress
      -e DURATION_MINUTES=5 \     # Test duration
      -e LOG_LEVEL=info \
      ghcr.io/your-username/doktolib/load-generator:${{ github.sha }}
```

## Troubleshooting

### Common Issues

**Build Failures**:
- Check Dockerfile syntax
- Verify build context paths
- Review build logs in Actions tab

**Deployment Failures**:
- Verify Qovery secrets are set correctly
- Check Qovery CLI authentication
- Ensure applications exist in Qovery

**Health Check Failures**:
- Verify application URLs are accessible
- Check application logs in Qovery
- Increase health check timeout if needed

### Debug Commands

```bash
# Test Qovery CLI locally
qovery auth
qovery organization list
qovery project list
qovery application list

# Test container builds locally  
docker build -t test-backend ./backend
docker build -t test-frontend ./frontend
docker build -t test-load-generator ./load-generator
```

## Monitoring

- **GitHub Actions**: Workflow execution logs
- **Qovery Console**: Application health and metrics
- **GHCR**: Container image registry
- **GitHub Security**: Vulnerability scan results

## Best Practices

1. **Secrets Management**: Never commit secrets to repository
2. **Image Tagging**: Use commit SHA for reproducible deployments  
3. **Health Checks**: Always verify deployment success
4. **Testing**: Run tests before deployment
5. **Monitoring**: Set up alerts for deployment failures

---

This pipeline provides a production-ready CI/CD solution for deploying containerized applications to Qovery with comprehensive testing, security scanning, and monitoring.