# Deployment Guide

This guide covers deploying the Doktolib application using various methods, with a focus on Qovery deployment via GitHub Actions.

## Deployment Methods

### 1. GitHub Actions + Qovery (Recommended)

Automated CI/CD pipeline with GitHub Actions deploying to Qovery.

**Prerequisites:**
- GitHub repository with actions enabled
- Qovery account and project setup
- Required secrets configured

**Setup Steps:**

1. **Configure GitHub Secrets**:
   ```
   QOVERY_CLI_ACCESS_TOKEN
   QOVERY_ORGANIZATION_ID  
   QOVERY_PROJECT_ID
   QOVERY_ENVIRONMENT_ID
   QOVERY_BACKEND_APPLICATION_ID
   QOVERY_FRONTEND_APPLICATION_ID
   QOVERY_LOAD_GENERATOR_APPLICATION_ID
   ```

2. **Create Qovery Applications**:
   ```bash
   # Login to Qovery
   qovery auth
   
   # Create applications
   qovery application create \
     --name "doktolib-backend" \
     --container-image "ghcr.io/your-username/doktolib/backend" \
     --port 8080
   
   qovery application create \
     --name "doktolib-frontend" \
     --container-image "ghcr.io/your-username/doktolib/frontend" \
     --port 3000
   ```

3. **Deploy**:
   ```bash
   git push origin main  # Automatic deployment
   # OR manual via GitHub Actions UI
   ```

**Features:**
- ✅ Automatic builds and deployments
- ✅ Multi-architecture container images
- ✅ Security scanning with Trivy
- ✅ Health checks and load testing
- ✅ Rollback on failure
- ✅ Deployment notifications

### 2. Docker Compose (Local/Development)

Quick local deployment for development and testing.

```bash
# Start all services
NEXT_PUBLIC_API_URL=http://backend:8080 docker compose up -d

# With load testing
LOAD_SCENARIO=light LOAD_DURATION=5 docker compose --profile loadtest up

# View logs
docker compose logs -f

# Stop services
docker compose down
```

### 3. Kubernetes (Self-Managed)

Deploy to any Kubernetes cluster using the provided manifests.

**Prerequisites:**
- Kubernetes cluster access
- kubectl configured
- Container images in accessible registry

```bash
# Apply Kubernetes manifests
kubectl apply -f k8s/

# Check deployment status
kubectl get pods
kubectl get services
kubectl get ingress
```

### 4. Manual Qovery CLI Deployment

Direct deployment using Qovery CLI without GitHub Actions.

```bash
# Build and push images
docker build -t ghcr.io/your-username/doktolib/backend ./backend
docker build -t ghcr.io/your-username/doktolib/frontend ./frontend
docker push ghcr.io/your-username/doktolib/backend
docker push ghcr.io/your-username/doktolib/frontend

# Deploy with Qovery CLI
qovery application deploy --application $BACKEND_APP_ID --image-tag latest
qovery application deploy --application $FRONTEND_APP_ID --image-tag latest
```

## Environment Configuration

### Environment Variables

**Backend:**
- `DATABASE_URL`: PostgreSQL connection string
- `DB_SSL_MODE`: SSL mode (disable/require/verify-ca/verify-full)
- `PORT`: Server port (default: 8080)
- `GIN_MODE`: Gin mode (debug/release)

**Frontend:**
- `NEXT_PUBLIC_API_URL`: Backend API URL
- `PORT`: Frontend port (default: 3000)
- `NODE_ENV`: Node environment

**Load Generator:**
- `API_URL`: Target API URL
- `SCENARIO`: Load scenario (light/normal/heavy/stress)
- `DURATION_MINUTES`: Test duration
- `LOG_LEVEL`: Logging level

### Database Configuration

**PostgreSQL Environment Variables:**
```bash
POSTGRES_DB=doktolib
POSTGRES_USER=doktolib  
POSTGRES_PASSWORD=your-secure-password
DATABASE_URL=postgres://doktolib:password@host:5432/doktolib
```

**SSL Configuration:**
- `DB_SSL_MODE=disable` - No SSL (development)
- `DB_SSL_MODE=require` - SSL required
- `DB_SSL_MODE=verify-full` - Full SSL verification

## Deployment Scenarios

### Development Environment

```bash
# Local development with hot reload
cd frontend && npm run dev &
cd backend && DATABASE_URL="postgres://..." go run . &
```

### Staging Environment

```bash
# Docker Compose with production-like settings
export NEXT_PUBLIC_API_URL=https://staging-api.doktolib.com
export GIN_MODE=release
docker compose up -d
```

### Production Environment

```bash
# GitHub Actions deployment to production
# Set production secrets and deploy via workflow dispatch
```

## Health Checks and Monitoring

### Health Endpoints

- **Backend**: `GET /api/v1/health`
- **Frontend**: `GET /` (returns 200 if healthy)

### Monitoring Setup

```bash
# Check application health
curl -f https://api.doktolib.com/api/v1/health
curl -f https://app.doktolib.com

# Load testing
docker run --rm \
  -e API_URL=https://api.doktolib.com \
  -e SCENARIO=light \
  -e DURATION_MINUTES=5 \
  ghcr.io/your-username/doktolib/load-generator:latest
```

## Database Migration

### Initial Setup

```sql
-- Run migrations (automatically handled by backend on startup)
-- Or manually apply:
psql $DATABASE_URL -f backend/migrations/001_initial_schema.sql
```

### Seed Data

```bash
# Seed database with doctors
DATABASE_URL="postgres://..." npm run seed

# Or with specific count
DOCTOR_COUNT=1000 DATABASE_URL="postgres://..." npm run seed
```

## SSL/TLS Configuration

### Let's Encrypt (Qovery)
- Automatic SSL certificates via Qovery
- No additional configuration needed

### Custom SSL
```bash
# For self-hosted deployments
# Configure your load balancer or reverse proxy
# Update environment variables accordingly
```

## Scaling Configuration

### Horizontal Scaling

**Qovery:**
```bash
# Scale applications
qovery application scale --application $APP_ID --replicas 3
```

**Kubernetes:**
```bash
# Scale deployments
kubectl scale deployment doktolib-backend --replicas=3
kubectl scale deployment doktolib-frontend --replicas=2
```

### Resource Limits

**Memory and CPU:**
```yaml
# In Qovery or Kubernetes manifests
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

## Backup and Disaster Recovery

### Database Backups

```bash
# Manual backup
pg_dump $DATABASE_URL > backup.sql

# Restore
psql $DATABASE_URL < backup.sql
```

### Application Recovery

```bash
# Rollback to previous version
qovery application rollback --application $APP_ID --to-commit $PREVIOUS_SHA
```

## Security Considerations

### Container Security
- ✅ Non-root user in containers
- ✅ Minimal base images (Alpine Linux)
- ✅ Regular security scans with Trivy
- ✅ No secrets in container images

### Network Security
- ✅ HTTPS/TLS encryption
- ✅ Environment-based secrets
- ✅ Database connection encryption
- ✅ CORS configuration

### Access Control
- ✅ GitHub OIDC authentication
- ✅ Qovery RBAC
- ✅ Secrets management
- ✅ Container registry authentication

## Troubleshooting

### Common Issues

**Build Failures:**
```bash
# Check Docker build
docker build -t test-image ./service-directory

# Review Dockerfile syntax
# Check build context and .dockerignore
```

**Deployment Failures:**
```bash
# Check Qovery status
qovery application status --application $APP_ID

# View logs
qovery application logs --application $APP_ID --follow
```

**Database Connection Issues:**
```bash
# Test database connectivity
psql $DATABASE_URL -c "SELECT version();"

# Check SSL configuration
```

**Health Check Failures:**
```bash
# Test endpoints manually
curl -v https://your-api.com/api/v1/health
curl -v https://your-frontend.com

# Check application logs
```

### Debugging Commands

```bash
# Local debugging
docker compose logs -f service-name
docker exec -it container-name sh

# Qovery debugging  
qovery application shell --application $APP_ID
qovery application logs --application $APP_ID --follow

# Kubernetes debugging
kubectl describe pod pod-name
kubectl logs -f deployment/deployment-name
kubectl exec -it pod-name -- sh
```

## Performance Optimization

### Frontend Optimization
- ✅ Next.js static optimization
- ✅ Image optimization
- ✅ Bundle analysis and optimization
- ✅ CDN-ready assets

### Backend Optimization  
- ✅ Database connection pooling
- ✅ Efficient SQL queries
- ✅ Gin framework optimizations
- ✅ Health check caching

### Database Optimization
- ✅ Proper indexing
- ✅ Connection pooling
- ✅ Query optimization
- ✅ Regular maintenance

---

This deployment guide provides comprehensive instructions for deploying Doktolib in various environments with proper monitoring, security, and scaling considerations.