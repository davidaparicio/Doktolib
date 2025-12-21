#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}RDS Aurora Serverless Deployment Script${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check prerequisites
echo "Checking prerequisites..."

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not installed${NC}"
    echo "Install it from: https://aws.amazon.com/cli/"
    exit 1
fi
echo -e "${GREEN}✓ AWS CLI installed${NC}"

# Check Terraform
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}❌ Terraform is not installed${NC}"
    echo "Install it from: https://www.terraform.io/downloads"
    exit 1
fi
echo -e "${GREEN}✓ Terraform installed${NC}"

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ AWS credentials not configured${NC}"
    echo "Run: aws configure"
    exit 1
fi
echo -e "${GREEN}✓ AWS credentials configured${NC}"

AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=$(aws configure get region || echo "us-east-1")
echo -e "   Account: ${YELLOW}${AWS_ACCOUNT}${NC}"
echo -e "   Region: ${YELLOW}${AWS_REGION}${NC}"
echo ""

# Check if terraform.tfvars exists
if [ ! -f "$SCRIPT_DIR/terraform.tfvars" ]; then
    echo -e "${YELLOW}⚠️  terraform.tfvars not found${NC}"
    echo "Creating from example..."
    cp "$SCRIPT_DIR/terraform.tfvars.example" "$SCRIPT_DIR/terraform.tfvars"
    echo -e "${GREEN}✓ Created terraform.tfvars${NC}"
    echo ""
    echo -e "${YELLOW}Please review and customize terraform.tfvars before deploying${NC}"
    echo "Edit: $SCRIPT_DIR/terraform.tfvars"
    echo ""
    read -p "Continue with default configuration? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Exiting. Please customize terraform.tfvars and run again."
        exit 0
    fi
fi

# Initialize Terraform
echo ""
echo "Initializing Terraform..."
cd "$SCRIPT_DIR"
terraform init

# Validate configuration
echo ""
echo "Validating Terraform configuration..."
terraform validate
echo -e "${GREEN}✓ Configuration is valid${NC}"

# Show plan
echo ""
echo "Generating deployment plan..."
terraform plan -out=tfplan

echo ""
echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}Review the plan above${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""
read -p "Do you want to apply this plan? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled"
    rm -f tfplan
    exit 0
fi

# Apply plan
echo ""
echo "Deploying Aurora Serverless cluster..."
echo "This may take 5-10 minutes..."
terraform apply tfplan

# Clean up plan file
rm -f tfplan

# Show outputs
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Save outputs to file
terraform output -json > outputs.json
echo -e "${GREEN}✓ Outputs saved to outputs.json${NC}"
echo ""

# Display connection information
echo -e "${YELLOW}Database Connection Information:${NC}"
echo "-----------------------------------"
echo "Endpoint: $(terraform output -raw cluster_endpoint)"
echo "Port: $(terraform output -raw cluster_port)"
echo "Database: $(terraform output -raw database_name)"
echo "Username: $(terraform output -raw master_username)"
echo ""

# Show Qovery integration instructions
echo -e "${YELLOW}Qovery Integration:${NC}"
echo "-----------------------------------"
echo "1. Copy the DATABASE_URL for Qovery:"
echo ""
echo "   terraform output -raw qovery_database_url"
echo ""
echo "2. Add to Qovery environment variables:"
echo ""
echo "   qovery environment variable create \\"
echo "     --key DATABASE_URL \\"
echo "     --value \"\$(terraform output -raw qovery_database_url)\" \\"
echo "     --secret"
echo ""
echo "3. Or use AWS Secrets Manager:"
echo "   Secret Name: $(terraform output -raw secrets_manager_secret_name)"
echo ""

# Show monitoring links
echo -e "${YELLOW}Monitoring:${NC}"
echo "-----------------------------------"
echo "CloudWatch Logs:"
echo "  aws logs tail /aws/rds/cluster/$(terraform output -raw cluster_id)/postgresql --follow"
echo ""
echo "RDS Console:"
echo "  https://console.aws.amazon.com/rds/home?region=${AWS_REGION}#database:id=$(terraform output -raw cluster_id)"
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Next Steps:${NC}"
echo -e "${GREEN}========================================${NC}"
echo "1. Test connection: psql \"\$(terraform output -raw qovery_database_url)\""
echo "2. Configure Qovery with the connection details above"
echo "3. Update your application to use the new database"
echo "4. Monitor the cluster in AWS Console"
echo ""
echo -e "${GREEN}Deployment script completed successfully!${NC}"
