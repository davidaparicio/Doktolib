# Doktolib S3 Bucket Terraform Configuration

This Terraform configuration creates a secure AWS S3 bucket for storing medical files in the Doktolib application. The bucket is configured with security best practices including encryption, access controls, and lifecycle policies.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    AWS S3 Infrastructure                     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────┐    ┌──────────────────────────────────┐ │
│  │   S3 Bucket     │    │        IAM Resources             │ │
│  │                 │    │                                  │ │
│  │ • Encryption    │    │  ┌─────────────────────────────┐ │ │
│  │ • Versioning    │    │  │      Application Role      │ │ │
│  │ • Lifecycle     │    │  │                             │ │ │
│  │ • CORS Config   │    │  │ • S3 Read/Write Access      │ │ │
│  │ • Public Block  │    │  │ • Cross-service Assume      │ │ │
│  └─────────────────┘    │  └─────────────────────────────┘ │ │
│                         │                                  │ │
│                         │  ┌─────────────────────────────┐ │ │
│                         │  │      Application User      │ │ │
│                         │  │                             │ │ │
│                         │  │ • Access Key Credentials    │ │ │
│                         │  │ • S3 Bucket Permissions     │ │ │
│                         │  └─────────────────────────────┘ │ │
│                         └──────────────────────────────────┘ │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Security Features

### 🔐 Encryption & Privacy
- **Server-side encryption** with AES-256
- **Public access blocked** at bucket level
- **Versioning enabled** for data protection
- **Lifecycle policies** for automatic cleanup

### 🔑 Access Control
- **IAM role-based access** for applications
- **Dedicated IAM user** with minimal permissions
- **Cross-service assume role** capabilities
- **Bucket policy** restricting access to authorized principals only

### 🌐 CORS Configuration
- **Configurable origins** for web application access
- **Secure headers** and methods allowed
- **Production-ready** CORS policies

## File Organization

The S3 bucket organizes medical files in a structured hierarchy:

```
medical-files/
├── lab_results/
│   ├── patient-id-1/
│   │   ├── file-uuid-1.pdf
│   │   └── file-uuid-2.jpg
│   └── patient-id-2/
│       └── file-uuid-3.pdf
├── insurance/
│   └── patient-id-1/
│       └── file-uuid-4.jpg
├── prescription/
├── medical_records/
└── other/
```

## Quick Start

### 1. Local Development

```bash
# Set required environment variables
export AWS_ACCESS_KEY_ID="your_access_key"
export AWS_SECRET_ACCESS_KEY="your_secret_key"
export TF_VAR_bucket_name="doktolib-medical-files-dev"
export TF_VAR_aws_region="us-east-1"

# Initialize and apply
terraform init
terraform plan
terraform apply
```

### 2. Qovery Lifecycle Job

The included Dockerfile and entrypoint script allow this to be run as a Qovery lifecycle job:

```bash
# Build the container
docker build -t doktolib-terraform-s3 .

# Run with environment variables
docker run --rm \
  -e AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
  -e AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
  -e TF_VAR_bucket_name="doktolib-medical-files" \
  -e TF_VAR_aws_region="us-east-1" \
  doktolib-terraform-s3 apply
```

## Required Environment Variables

### AWS Credentials
```bash
AWS_ACCESS_KEY_ID="your_aws_access_key"
AWS_SECRET_ACCESS_KEY="your_aws_secret_key"
```

### Terraform Variables
```bash
TF_VAR_bucket_name="doktolib-medical-files"     # S3 bucket name
TF_VAR_aws_region="us-east-1"                   # AWS region
TF_VAR_environment="production"                 # Environment tag (optional)
TF_VAR_allowed_origins='["https://example.com"]' # CORS origins (optional)
TF_VAR_app_role_arn="arn:aws:iam::..."         # App role ARN (optional)
```

## Terraform Outputs

After successful deployment, the following outputs are available:

| Output | Description | Usage |
|--------|-------------|-------|
| `bucket_name` | S3 bucket name | Set as `AWS_S3_BUCKET` in backend |
| `bucket_arn` | S3 bucket ARN | For IAM policies and monitoring |
| `app_user_access_key_id` | IAM user access key | Set as `AWS_ACCESS_KEY_ID` in backend |
| `app_user_secret_access_key` | IAM user secret key | Set as `AWS_SECRET_ACCESS_KEY` in backend |
| `app_role_arn` | IAM role ARN | For cross-service access |
| `bucket_regional_domain_name` | S3 regional domain | For direct API access |

## Integration with Doktolib Backend

After running Terraform, configure the backend with the generated credentials:

```bash
# Environment variables for the Go backend
export AWS_ACCESS_KEY_ID="<from terraform output>"
export AWS_SECRET_ACCESS_KEY="<from terraform output>"
export AWS_REGION="us-east-1"
export AWS_S3_BUCKET="<from terraform output>"
```

The backend will automatically:
1. Initialize S3 client on startup
2. Upload files to organized folder structure
3. Generate presigned URLs for secure file access
4. Handle file deletions and cleanup

## Lifecycle Management

### File Retention
- **Old versions**: Automatically deleted after 30 days
- **Incomplete uploads**: Automatically aborted after 1 day
- **File organization**: Automatic categorization by filename

### Infrastructure Management

```bash
# View current infrastructure
docker run --rm doktolib-terraform-s3 output

# Destroy infrastructure (DANGER!)
docker run --rm doktolib-terraform-s3 destroy
```

## Monitoring & Compliance

### CloudWatch Integration
The S3 bucket integrates with AWS CloudWatch for:
- **Access logging** and audit trails
- **Performance metrics** and monitoring
- **Cost analysis** and optimization

### HIPAA Compliance Features
- **Encryption at rest** and in transit
- **Access logging** for audit requirements
- **Versioning** for data integrity
- **Lifecycle policies** for retention compliance

## Troubleshooting

### Common Issues

1. **Access Denied**: Check AWS credentials and IAM permissions
2. **Bucket Already Exists**: Use a unique bucket name
3. **Region Mismatch**: Ensure consistent region configuration
4. **CORS Errors**: Verify allowed origins configuration

### Debug Commands

```bash
# Validate Terraform configuration
terraform validate

# Check current state
terraform show

# View detailed plan
terraform plan -detailed-exitcode

# Debug with verbose logging
export TF_LOG=DEBUG
terraform apply
```

### Log Analysis

The lifecycle job provides detailed colored output:
- 🔍 **Blue**: Status and progress information
- ✅ **Green**: Successful operations
- ⚠️ **Yellow**: Warnings and important notes
- ❌ **Red**: Errors and failures

## Cost Optimization

### Storage Classes
Files are stored in S3 Standard by default, but can be transitioned:
- **Standard-IA**: For infrequently accessed files (30+ days)
- **Glacier**: For archival (90+ days)
- **Deep Archive**: For long-term retention (180+ days)

### Request Optimization
- **Batch operations** for multiple file uploads
- **Presigned URLs** to reduce API calls
- **Efficient naming** for faster retrieval

## Security Best Practices

### ✅ Implemented
- Server-side encryption (AES-256)
- IAM least-privilege access
- Public access blocking
- CORS configuration
- Access logging enabled
- Versioning for data protection

### 🔄 Recommended Enhancements
- Enable AWS CloudTrail logging
- Set up S3 access point for enhanced security
- Implement S3 Object Lock for compliance
- Add KMS encryption for sensitive data
- Configure VPC endpoints for private access

## Contributing

When modifying this Terraform configuration:

1. **Test locally** before deploying to production
2. **Update documentation** for any new variables or outputs
3. **Follow security best practices** for all changes
4. **Validate configurations** with `terraform validate`
5. **Review cost implications** of infrastructure changes

For questions or issues, refer to the main project documentation or create an issue in the GitHub repository.