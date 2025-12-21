# RDS Aurora Serverless PostgreSQL for Doktolib

This Terraform configuration creates an AWS RDS Aurora Serverless v2 PostgreSQL cluster optimized for use with Qovery deployment.

## Features

- **Aurora Serverless v2**: Automatic scaling based on workload (0.5-2 ACUs by default)
- **High Availability**: Multi-AZ deployment support with read replicas
- **Security**: Encrypted at rest, stored credentials in AWS Secrets Manager
- **Monitoring**: CloudWatch logs and Performance Insights enabled
- **Backup**: Automated daily backups with 7-day retention
- **Cost-Optimized**: Scales down to 0.5 ACU during low traffic periods

## Prerequisites

1. **AWS Account** with appropriate permissions to create:
   - RDS clusters and instances
   - VPC resources (security groups, subnet groups)
   - Secrets Manager secrets
   - KMS keys (optional)

2. **AWS CLI** configured with credentials:
   ```bash
   aws configure
   ```

3. **Terraform** installed (v1.0+):
   ```bash
   brew install terraform  # macOS
   # or
   wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
   ```

4. **Qovery CLI** (optional, for deployment):
   ```bash
   brew install qovery-cli  # macOS
   ```

## Quick Start

### 1. Initialize Terraform

```bash
cd terraform/rds-aurora
terraform init
```

### 2. Review and Customize Configuration

Create a `terraform.tfvars` file to override defaults:

```hcl
# terraform.tfvars
aws_region    = "us-east-1"
cluster_name  = "doktolib-production"
database_name = "doktolib"

# Scaling configuration
min_capacity = 0.5  # Minimum ACUs (0.5 = ~1GB RAM)
max_capacity = 4    # Maximum ACUs (4 = ~8GB RAM)

# Multi-AZ for production
instance_count = 2  # Creates writer + reader

# Security
allowed_cidr_blocks = ["10.0.0.0/8"]  # Restrict to your VPC CIDR
publicly_accessible = false            # Private database

# Tags
tags = {
  Project     = "Doktolib"
  Environment = "Production"
  ManagedBy   = "Terraform"
  Team        = "Platform"
}
```

### 3. Plan the Deployment

```bash
terraform plan
```

Review the planned changes to ensure everything looks correct.

### 4. Deploy the Aurora Cluster

```bash
terraform apply
```

Type `yes` when prompted. The deployment takes approximately 5-10 minutes.

### 5. Retrieve Connection Details

```bash
# Get database endpoint
terraform output cluster_endpoint

# Get connection URL for Qovery (sensitive output)
terraform output -raw qovery_database_url

# Get all outputs in JSON format
terraform output -json > outputs.json
```

## Qovery Integration

### Option 1: Using Terraform Outputs

After deploying the Aurora cluster, configure Qovery environment variables:

```bash
# Get the connection details
DB_HOST=$(terraform output -raw qovery_database_host)
DB_PORT=$(terraform output -raw qovery_database_port)
DB_NAME=$(terraform output -raw qovery_database_name)
DB_USER=$(terraform output -raw qovery_database_username)
DB_PASSWORD=$(terraform output -raw qovery_database_password)
DB_URL=$(terraform output -raw qovery_database_url)
```

### Option 2: Using Qovery CLI

Add the database to your Qovery environment:

```bash
# Set environment variables in Qovery
qovery environment variable create \
  --organization-id $ORG_ID \
  --project-id $PROJECT_ID \
  --environment-id $ENV_ID \
  --key DATABASE_URL \
  --value "$(terraform output -raw qovery_database_url)" \
  --secret

# Individual variables (if needed)
qovery environment variable create --key DB_HOST --value "$(terraform output -raw qovery_database_host)"
qovery environment variable create --key DB_PORT --value "$(terraform output -raw qovery_database_port)"
qovery environment variable create --key DB_NAME --value "$(terraform output -raw qovery_database_name)"
qovery environment variable create --key DB_USER --value "$(terraform output -raw qovery_database_username)" --secret
qovery environment variable create --key DB_PASSWORD --value "$(terraform output -raw qovery_database_password)" --secret
```

### Option 3: Using Qovery Console

1. Go to your Qovery project environment
2. Navigate to **Environment Variables**
3. Add the following variables:
   - `DATABASE_URL`: Get from `terraform output -raw qovery_database_url`
   - `DB_HOST`: Get from `terraform output -raw qovery_database_host`
   - `DB_PORT`: Get from `terraform output -raw qovery_database_port`
   - Mark `DATABASE_URL`, `DB_USER`, and `DB_PASSWORD` as **Secret**

### Option 4: Using AWS Secrets Manager with Qovery

Qovery can automatically retrieve secrets from AWS Secrets Manager:

1. Note the Secrets Manager secret name:
   ```bash
   terraform output secrets_manager_secret_name
   ```

2. In Qovery console, link the secret to your application
3. Qovery will automatically inject the credentials as environment variables

## Configuration Options

### Scaling Configuration

Aurora Serverless v2 uses Aurora Capacity Units (ACUs):
- **1 ACU** ≈ 2GB RAM
- **Minimum**: 0.5 ACU (1GB RAM) - ideal for development
- **Maximum**: 128 ACUs (256GB RAM) - enterprise scale

```hcl
min_capacity = 0.5  # Scales down to save costs
max_capacity = 16   # Scales up during traffic spikes
```

**Cost Estimate** (us-east-1):
- 0.5 ACU: ~$0.06/hour = ~$43/month
- 2 ACU: ~$0.24/hour = ~$175/month
- 16 ACU: ~$1.92/hour = ~$1,400/month

### High Availability

For production, deploy multiple instances across availability zones:

```hcl
instance_count = 2  # 1 writer + 1 reader
```

This provides:
- Automatic failover (< 30 seconds)
- Read scaling with reader endpoint
- Zero-downtime maintenance

### Security Configuration

#### Private Database (Recommended for Production)

```hcl
publicly_accessible = false
allowed_cidr_blocks = ["10.0.0.0/8"]  # Your VPC CIDR
```

#### Public Database (Development/Testing)

```hcl
publicly_accessible = true
allowed_cidr_blocks = ["0.0.0.0/0"]  # Allow all (not recommended for production)
```

#### Custom VPC

```hcl
use_default_vpc = false
vpc_id          = "vpc-xxxxx"
subnet_ids      = ["subnet-xxxxx", "subnet-yyyyy", "subnet-zzzzz"]
```

### Backup Configuration

```hcl
backup_retention_period      = 14  # Retain backups for 2 weeks
preferred_backup_window      = "03:00-04:00"  # UTC
preferred_maintenance_window = "mon:04:00-mon:05:00"  # UTC
```

### Engine Version

```hcl
engine_version = "15.5"  # PostgreSQL 15.5 (default)
# Other options: "14.9", "13.12", "16.1"
```

## Updating the Cluster

### Apply Configuration Changes

```bash
# Review changes
terraform plan

# Apply changes
terraform apply
```

By default, changes are applied during the maintenance window. To apply immediately:

```hcl
apply_immediately = true
```

### Upgrade PostgreSQL Version

```hcl
engine_version = "16.1"  # Upgrade to PostgreSQL 16
```

Then run:
```bash
terraform apply
```

## Monitoring and Maintenance

### CloudWatch Logs

Aurora automatically exports PostgreSQL logs to CloudWatch. View logs:

```bash
aws logs tail /aws/rds/cluster/doktolib-aurora/postgresql --follow
```

### Performance Insights

Enabled by default. View in AWS Console:
1. Navigate to RDS → Databases → Your Cluster
2. Click on **Performance Insights** tab
3. Analyze query performance and resource utilization

### Monitoring Metrics

Key metrics to monitor:
- **ServerlessDatabaseCapacity**: Current ACUs in use
- **CPUUtilization**: CPU usage percentage
- **DatabaseConnections**: Number of active connections
- **FreeableMemory**: Available memory

### Backup and Restore

#### Manual Snapshot

```bash
aws rds create-db-cluster-snapshot \
  --db-cluster-identifier doktolib-aurora \
  --db-cluster-snapshot-identifier doktolib-manual-snapshot-$(date +%Y%m%d)
```

#### Restore from Snapshot

Create a new `terraform.tfvars` with:
```hcl
snapshot_identifier = "doktolib-manual-snapshot-20240815"
```

Then apply to create a new cluster from the snapshot.

## Cost Optimization

### Development/Staging

```hcl
min_capacity = 0.5  # Minimum possible
max_capacity = 1    # Low ceiling
instance_count = 1   # Single instance
backup_retention_period = 1  # Minimal backups
```

**Estimated cost**: ~$50-80/month

### Production

```hcl
min_capacity = 1    # Better baseline performance
max_capacity = 8    # Handle traffic spikes
instance_count = 2   # High availability
backup_retention_period = 14  # 2 weeks retention
```

**Estimated cost**: ~$200-600/month (depending on usage)

## Troubleshooting

### Connection Issues

1. **Check security group rules**:
   ```bash
   terraform output security_group_id
   aws ec2 describe-security-groups --group-ids <sg-id>
   ```

2. **Verify connectivity from Qovery**:
   ```bash
   # From a Qovery pod
   nc -zv <db-endpoint> 5432
   ```

3. **Check if database is publicly accessible**:
   ```bash
   psql "$(terraform output -raw qovery_database_url)"
   ```

### Performance Issues

1. **Check current capacity**:
   ```bash
   aws rds describe-db-clusters --db-cluster-identifier doktolib-aurora \
     --query 'DBClusters[0].ServerlessV2ScalingConfiguration'
   ```

2. **Increase max capacity** if hitting ceiling:
   ```hcl
   max_capacity = 8  # Increase from 2 to 8
   ```

3. **Review slow queries** in Performance Insights

### Cost Issues

1. **Check actual usage**:
   ```bash
   aws cloudwatch get-metric-statistics \
     --namespace AWS/RDS \
     --metric-name ServerlessDatabaseCapacity \
     --dimensions Name=DBClusterIdentifier,Value=doktolib-aurora \
     --start-time $(date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%S) \
     --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
     --period 3600 \
     --statistics Average
   ```

2. **Reduce max capacity** if not needed:
   ```hcl
   max_capacity = 2  # Lower ceiling
   ```

## Disaster Recovery

### Backup Strategy

- **Automated backups**: Daily, retained for 7 days (configurable)
- **Manual snapshots**: Create before major changes
- **Cross-region replication**: Can be configured for DR

### Recovery Time Objective (RTO)

- **From automated backup**: 10-15 minutes
- **From snapshot**: 10-15 minutes
- **From failover (Multi-AZ)**: < 30 seconds

## Security Best Practices

1. **Use private subnets** for production databases
2. **Restrict CIDR blocks** to only application subnets
3. **Enable encryption** at rest (enabled by default)
4. **Use Secrets Manager** for credential rotation
5. **Enable Performance Insights** for security auditing
6. **Regular security patches** (automatic with Aurora)

## Cleanup

To destroy the Aurora cluster:

```bash
terraform destroy
```

**Warning**: This will permanently delete your database unless you set `skip_final_snapshot = false` (default). A final snapshot will be created with timestamp.

To restore later, note the final snapshot identifier and restore from it.

## Support and Resources

- [AWS RDS Aurora Documentation](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/)
- [Aurora Serverless v2 Guide](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-serverless-v2.html)
- [Qovery Documentation](https://hub.qovery.com/docs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## License

This Terraform configuration is part of the Doktolib project and is provided as-is for demonstration purposes.
