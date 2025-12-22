# Qovery Doktolib IAM Role CloudFormation

This CloudFormation template creates an IAM role that Qovery terraform services can assume to manage AWS resources securely without using long-lived access keys.

## Security Benefits

✅ **No long-lived credentials** - Uses temporary credentials through STS AssumeRole
✅ **Automatic credential rotation** - Credentials expire and are refreshed automatically
✅ **Better audit trail** - All actions are logged with AssumeRole events
✅ **Principle of least privilege** - Scoped permissions for specific services
✅ **External ID protection** - Prevents confused deputy problem

## Prerequisites

Before deploying this stack, you need to find your Qovery cluster's IAM role ARN:

```bash
# Get the Qovery cluster role ARN
# This is typically: arn:aws:iam::<ACCOUNT_ID>:role/qovery-user-role

# You can find it in:
# 1. AWS Console → IAM → Roles → Search for "qovery"
# 2. Or from Qovery cluster settings
```

## Deployment

### Option 1: AWS CLI

```bash
aws cloudformation create-stack \
  --stack-name qovery-doktolib-iam-role \
  --template-body file://qovery-doktolib-iam-role.yaml \
  --parameters \
    ParameterKey=QoveryClusterRoleArn,ParameterValue=arn:aws:iam::YOUR_ACCOUNT_ID:role/qovery-user-role \
    ParameterKey=EnvironmentName,ParameterValue=production \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1

# Wait for stack creation to complete
aws cloudformation wait stack-create-complete \
  --stack-name qovery-doktolib-iam-role

# Get the outputs
aws cloudformation describe-stacks \
  --stack-name qovery-doktolib-iam-role \
  --query 'Stacks[0].Outputs'
```

### Option 2: AWS Console

1. Go to AWS CloudFormation Console
2. Click **Create stack** → **With new resources**
3. Upload the `qovery-doktolib-iam-role.yaml` template
4. Enter parameters:
   - **Stack name**: `qovery-doktolib-iam-role`
   - **QoveryClusterRoleArn**: Your Qovery cluster role ARN
   - **EnvironmentName**: `production` (or your environment name)
5. Check **I acknowledge that AWS CloudFormation might create IAM resources with custom names**
6. Click **Create stack**
7. Wait for creation to complete
8. Go to **Outputs** tab and copy the `RoleArn` value

## Configure Qovery Environment

After the CloudFormation stack is created, add these environment variables to your Qovery environment:

```bash
# From CloudFormation Outputs
AWS_ASSUME_ROLE_ARN=arn:aws:iam::YOUR_ACCOUNT_ID:role/qovery-doktolib-production-role
AWS_ASSUME_ROLE_EXTERNAL_ID=qovery-doktolib-production
```

## IAM Permissions Included

The role includes permissions for:

### RDS Aurora
- Create, modify, delete Aurora clusters
- Manage DB subnet groups and parameter groups
- VPC and security group management

### AWS Lambda
- Create, update, delete Lambda functions
- Manage function configurations and versions
- IAM role pass for Lambda execution

### S3
- Create, manage, delete S3 buckets
- Manage bucket policies and configurations
- Object-level operations

### Secrets Manager
- Create, retrieve, update, delete secrets
- Manage secret versions and rotation

### CloudWatch
- Create and manage CloudWatch Logs
- Create and manage CloudWatch Alarms
- Metrics and monitoring

### IAM
- Create and manage IAM roles and policies
- Required for Lambda execution roles and S3 access roles

## Updating the Stack

To update permissions or configuration:

```bash
aws cloudformation update-stack \
  --stack-name qovery-doktolib-iam-role \
  --template-body file://qovery-doktolib-iam-role.yaml \
  --parameters \
    ParameterKey=QoveryClusterRoleArn,ParameterValue=arn:aws:iam::YOUR_ACCOUNT_ID:role/qovery-user-role \
    ParameterKey=EnvironmentName,ParameterValue=production \
  --capabilities CAPABILITY_NAMED_IAM
```

## Deleting the Stack

To remove the IAM role and all associated policies:

```bash
aws cloudformation delete-stack \
  --stack-name qovery-doktolib-iam-role

aws cloudformation wait stack-delete-complete \
  --stack-name qovery-doktolib-iam-role
```

## Troubleshooting

### "AssumeRole operation: Access denied"

**Cause**: The Qovery cluster role doesn't have permission to assume this role.

**Solution**: Verify that the `QoveryClusterRoleArn` parameter matches your actual Qovery cluster role ARN.

### "External ID mismatch"

**Cause**: The external ID in Qovery environment variable doesn't match the CloudFormation parameter.

**Solution**: Ensure `AWS_ASSUME_ROLE_EXTERNAL_ID` matches the `EnvironmentName` parameter:
```
AWS_ASSUME_ROLE_EXTERNAL_ID=qovery-doktolib-<EnvironmentName>
```

### "Insufficient permissions"

**Cause**: The IAM role doesn't have required permissions for a specific operation.

**Solution**: Update the CloudFormation template to add the missing permissions and update the stack.

## Multiple Environments

To create separate roles for different environments:

```bash
# Production
aws cloudformation create-stack \
  --stack-name qovery-doktolib-iam-role-production \
  --template-body file://qovery-doktolib-iam-role.yaml \
  --parameters \
    ParameterKey=QoveryClusterRoleArn,ParameterValue=arn:aws:iam::123:role/qovery-user-role \
    ParameterKey=EnvironmentName,ParameterValue=production \
  --capabilities CAPABILITY_NAMED_IAM

# Staging
aws cloudformation create-stack \
  --stack-name qovery-doktolib-iam-role-staging \
  --template-body file://qovery-doktolib-iam-role.yaml \
  --parameters \
    ParameterKey=QoveryClusterRoleArn,ParameterValue=arn:aws:iam::123:role/qovery-user-role \
    ParameterKey=EnvironmentName,ParameterValue=staging \
  --capabilities CAPABILITY_NAMED_IAM
```

## Security Best Practices

1. **Use separate roles per environment** - Isolate production from staging/dev
2. **Enable CloudTrail** - Audit all AssumeRole calls
3. **Set up alerts** - Monitor unusual AssumeRole patterns
4. **Regular reviews** - Periodically review and tighten permissions
5. **Rotate external IDs** - Change external IDs if compromised

## Cost

This CloudFormation stack creates IAM resources which are **free** in AWS. You only pay for the AWS resources created by the terraform services (RDS, Lambda, S3, etc.).
