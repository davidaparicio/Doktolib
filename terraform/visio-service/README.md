# Visio Conference Health Check Service

This Terraform configuration deploys an AWS Lambda-based video conference health check service that provides a simple HTTP endpoint for the Doktolib frontend to monitor service availability.

## Overview

The service simulates a video conference system health check and provides:
- **Health Check Endpoint**: Returns "OK" status for frontend navbar indicator
- **Status Endpoint**: Provides detailed service status information
- **CORS Support**: Configured for frontend access
- **CloudWatch Monitoring**: Automatic logging and alarms
- **Serverless Architecture**: No servers to manage, pay per request

## Architecture

```
Frontend (Next.js)
    ↓
    | HTTP GET /health
    ↓
Lambda Function URL
    ↓
AWS Lambda (Python 3.11)
    ↓
Returns: { "status": "OK", ... }
```

## Features

- **Lambda Function URL**: Direct HTTPS endpoint (no API Gateway needed)
- **Auto-scaling**: Handles any traffic volume automatically
- **Low latency**: < 50ms response time
- **Cost-efficient**: ~$0.20-2/month depending on traffic
- **CORS enabled**: Works with any frontend domain
- **Monitoring**: CloudWatch logs and alarms included

## Prerequisites

1. **AWS Account** with Lambda and CloudWatch permissions
2. **AWS CLI** configured:
   ```bash
   aws configure
   ```
3. **Terraform** installed (v1.0+)

## Quick Start

### 1. Initialize Terraform

```bash
cd terraform/visio-service
terraform init
```

### 2. Configure (Optional)

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars if needed
```

Default configuration is production-ready for most use cases.

### 3. Deploy

```bash
terraform apply
```

### 4. Get the Health Endpoint URL

```bash
# Get the health check URL
terraform output -raw health_endpoint

# Example output:
# https://abc123xyz.lambda-url.us-east-1.on.aws/health
```

### 5. Test the Endpoint

```bash
# Test health endpoint
curl $(terraform output -raw health_endpoint)

# Expected response:
# {
#   "status": "OK",
#   "service": "visio-conference",
#   "timestamp": "2024-08-15T10:30:00Z",
#   "version": "1.0.0",
#   "checks": {
#     "api": "operational",
#     "video_streaming": "operational",
#     ...
#   }
# }
```

## Frontend Integration

### Option 1: Environment Variable (Recommended)

Add to your frontend `.env` file:

```bash
# Get the environment variable
terraform output frontend_env_variable

# Add to frontend/.env
NEXT_PUBLIC_VISIO_HEALTH_URL=https://your-lambda-url.lambda-url.us-east-1.on.aws/health
```

### Option 2: Qovery Environment Variables

```bash
# Set in Qovery
qovery environment variable create \
  --key NEXT_PUBLIC_VISIO_HEALTH_URL \
  --value "$(terraform output -raw qovery_visio_health_url)"
```

### Option 3: Direct Integration

In your Next.js frontend code:

```typescript
// components/VisioHealthIndicator.tsx
'use client';

import { useEffect, useState } from 'react';

export function VisioHealthIndicator() {
  const [status, setStatus] = useState<'loading' | 'ok' | 'error'>('loading');

  useEffect(() => {
    const checkHealth = async () => {
      try {
        const response = await fetch(
          process.env.NEXT_PUBLIC_VISIO_HEALTH_URL ||
          'https://your-lambda-url.lambda-url.us-east-1.on.aws/health'
        );
        const data = await response.json();

        if (data.status === 'OK') {
          setStatus('ok');
        } else {
          setStatus('error');
        }
      } catch (error) {
        console.error('Failed to check visio health:', error);
        setStatus('error');
      }
    };

    checkHealth();
    // Check every 30 seconds
    const interval = setInterval(checkHealth, 30000);

    return () => clearInterval(interval);
  }, []);

  return (
    <div className="flex items-center gap-2">
      <div
        className={`w-2 h-2 rounded-full ${
          status === 'ok'
            ? 'bg-green-500'
            : status === 'error'
            ? 'bg-red-500'
            : 'bg-gray-400 animate-pulse'
        }`}
      />
      <span className="text-sm">
        Visio: {status === 'ok' ? 'Online' : status === 'error' ? 'Offline' : 'Checking...'}
      </span>
    </div>
  );
}
```

Add to your navbar:

```typescript
// app/layout.tsx or components/Navbar.tsx
import { VisioHealthIndicator } from '@/components/VisioHealthIndicator';

export function Navbar() {
  return (
    <nav className="flex items-center justify-between p-4">
      <div className="flex items-center gap-4">
        <Logo />
        <VisioHealthIndicator />
      </div>
      {/* ... rest of navbar */}
    </nav>
  );
}
```

## API Endpoints

### GET /health

Returns operational status of the video conference service.

**Response:**
```json
{
  "status": "OK",
  "service": "visio-conference",
  "timestamp": "2024-08-15T10:30:00Z",
  "version": "1.0.0",
  "region": "us-east-1",
  "uptime": "healthy",
  "checks": {
    "api": "operational",
    "video_streaming": "operational",
    "audio_streaming": "operational",
    "signaling_server": "operational",
    "turn_servers": "operational"
  }
}
```

### GET /status

Simplified status endpoint.

**Response:**
```json
{
  "status": "OK",
  "service": "visio-conference",
  "message": "Video conference service is operational",
  "timestamp": "2024-08-15T10:30:00Z"
}
```

### GET /

Service information and available endpoints.

**Response:**
```json
{
  "service": "Doktolib Video Conference Service",
  "version": "1.0.0",
  "endpoints": {
    "health": "/health",
    "status": "/status"
  },
  "timestamp": "2024-08-15T10:30:00Z"
}
```

## Configuration Options

### CORS Configuration

By default, CORS allows all origins (`*`). For production, restrict to your domains:

```hcl
# terraform.tfvars
cors_allow_origins = [
  "https://app.doktolib.com",
  "https://doktolib.com",
  "http://localhost:3000"
]
```

### Lambda Performance

Adjust timeout and memory based on your needs:

```hcl
lambda_timeout = 10   # seconds
lambda_memory  = 128  # MB (128 is minimum and sufficient)
```

### Log Retention

Configure CloudWatch log retention:

```hcl
log_retention_days = 7  # days (1, 3, 5, 7, 14, 30, 60, etc.)
```

## Monitoring

### View Logs

```bash
# Tail logs in real-time
aws logs tail /aws/lambda/doktolib-visio-health --follow

# Or use Terraform output
$(terraform output -raw cloudwatch_logs_command)
```

### CloudWatch Dashboard

Access the CloudWatch dashboard:

```bash
terraform output cloudwatch_dashboard_url
```

### Metrics to Monitor

- **Invocations**: Number of requests
- **Duration**: Response time (should be < 100ms)
- **Errors**: Failed requests
- **Throttles**: Rate limiting events (should be 0)

### CloudWatch Alarms

Two alarms are automatically configured:
1. **Errors**: Triggers if > 10 errors in 2 minutes
2. **Throttles**: Triggers if > 5 throttles in 2 minutes

## Cost Estimation

Lambda pricing (us-east-1):
- **Requests**: $0.20 per 1M requests
- **Compute**: $0.0000166667 per GB-second

### Example Costs

**Low Traffic** (1,000 requests/day):
- 30,000 requests/month
- ~$0.20/month

**Medium Traffic** (10,000 requests/day):
- 300,000 requests/month
- ~$0.50/month

**High Traffic** (100,000 requests/day):
- 3,000,000 requests/month
- ~$1-2/month

**Note**: First 1M requests and 400,000 GB-seconds per month are FREE (AWS Free Tier).

## Updating the Service

### Update Lambda Code

1. Edit `lambda/health.py`
2. Apply changes:
   ```bash
   terraform apply
   ```

### Update Configuration

1. Edit `terraform.tfvars`
2. Apply changes:
   ```bash
   terraform apply
   ```

## Troubleshooting

### Test the Endpoint

```bash
# Test health endpoint
curl -v $(terraform output -raw health_endpoint)

# Test with formatted JSON
curl -s $(terraform output -raw health_endpoint) | jq .
```

### Check Lambda Logs

```bash
# View recent logs
aws logs tail /aws/lambda/doktolib-visio-health --since 10m

# Follow logs in real-time
aws logs tail /aws/lambda/doktolib-visio-health --follow
```

### CORS Issues

If frontend gets CORS errors:

1. Check `cors_allow_origins` in `terraform.tfvars`
2. Add your frontend domain:
   ```hcl
   cors_allow_origins = ["https://your-domain.com", "http://localhost:3000"]
   ```
3. Apply changes: `terraform apply`

### High Latency

If response time is slow:

1. Increase Lambda memory (improves CPU):
   ```hcl
   lambda_memory = 256  # or 512
   ```
2. Consider using provisioned concurrency (adds cost)

### Rate Limiting

If you see throttles:

1. Check CloudWatch metrics
2. Request limit increase: AWS Support
3. Consider caching on frontend (check every 30-60 seconds, not every second)

## Security Best Practices

1. **Restrict CORS origins** in production
2. **Enable AWS CloudTrail** for audit logging
3. **Review IAM permissions** regularly
4. **Enable Lambda function versioning** for rollbacks
5. **Use AWS WAF** if expecting high traffic or attacks

## Cleanup

To destroy the Lambda function and all resources:

```bash
terraform destroy
```

This will remove:
- Lambda function
- Lambda Function URL
- IAM roles and policies
- CloudWatch log groups
- CloudWatch alarms

## Alternative: API Gateway

If you need more control (rate limiting, API keys, custom domains), uncomment the API Gateway section in `main.tf`:

```hcl
# In main.tf, uncomment the API Gateway section
# This provides:
# - Custom domain names
# - API keys and usage plans
# - Rate limiting and throttling
# - Request/response transformation
```

**Note**: API Gateway adds ~$3.50/month minimum cost.

## Extending the Service

### Add Authentication

To require API keys:

1. Use API Gateway instead of Function URL
2. Enable API keys in API Gateway
3. Distribute keys to authorized applications

### Add Custom Domain

```hcl
# Add to main.tf
resource "aws_apigatewayv2_domain_name" "custom" {
  domain_name = "visio.doktolib.com"

  domain_name_configuration {
    certificate_arn = aws_acm_certificate.cert.arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}
```

### Add Real Video Conference

Replace the simulated health check with actual video conference service integration:
- WebRTC signaling server
- TURN/STUN servers
- Media server (Jitsi, Janus, etc.)

## Support and Resources

- [AWS Lambda Documentation](https://docs.aws.amazon.com/lambda/)
- [Lambda Function URLs](https://docs.aws.amazon.com/lambda/latest/dg/lambda-urls.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Python Lambda Development](https://docs.aws.amazon.com/lambda/latest/dg/lambda-python.html)

## License

This Terraform configuration is part of the Doktolib project and is provided for demonstration purposes.
