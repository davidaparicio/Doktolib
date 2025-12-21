#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Visio Health Check Service Deployment${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check prerequisites
echo "Checking prerequisites..."

if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not installed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ AWS CLI installed${NC}"

if ! command -v terraform &> /dev/null; then
    echo -e "${RED}❌ Terraform is not installed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Terraform installed${NC}"

if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ AWS credentials not configured${NC}"
    exit 1
fi
echo -e "${GREEN}✓ AWS credentials configured${NC}"

AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=$(aws configure get region || echo "us-east-1")
echo -e "   Account: ${YELLOW}${AWS_ACCOUNT}${NC}"
echo -e "   Region: ${YELLOW}${AWS_REGION}${NC}"
echo ""

# Check Lambda code exists
if [ ! -f "$SCRIPT_DIR/lambda/health.py" ]; then
    echo -e "${RED}❌ Lambda code not found at lambda/health.py${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Lambda code found${NC}"

# Create terraform.tfvars if it doesn't exist
if [ ! -f "$SCRIPT_DIR/terraform.tfvars" ]; then
    echo -e "${YELLOW}⚠️  terraform.tfvars not found, using defaults${NC}"
fi

# Initialize Terraform
echo ""
echo "Initializing Terraform..."
cd "$SCRIPT_DIR"
terraform init

# Validate configuration
echo ""
echo "Validating configuration..."
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
read -p "Apply this plan? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled"
    rm -f tfplan
    exit 0
fi

# Apply plan
echo ""
echo "Deploying Lambda function..."
terraform apply tfplan
rm -f tfplan

# Save outputs
terraform output -json > outputs.json
echo -e "${GREEN}✓ Outputs saved to outputs.json${NC}"

# Display results
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

HEALTH_URL=$(terraform output -raw health_endpoint)
STATUS_URL=$(terraform output -raw status_endpoint)

echo -e "${YELLOW}Service Endpoints:${NC}"
echo "-----------------------------------"
echo "Health: ${HEALTH_URL}"
echo "Status: ${STATUS_URL}"
echo ""

# Test the endpoint
echo -e "${YELLOW}Testing health endpoint...${NC}"
if curl -sf "${HEALTH_URL}" > /dev/null; then
    echo -e "${GREEN}✓ Health endpoint is operational${NC}"
    echo ""
    echo "Response:"
    curl -s "${HEALTH_URL}" | python3 -m json.tool || curl -s "${HEALTH_URL}"
else
    echo -e "${RED}❌ Health endpoint not responding${NC}"
    echo "The Lambda may need a few seconds to warm up. Try again:"
    echo "curl ${HEALTH_URL}"
fi

echo ""
echo -e "${YELLOW}Frontend Integration:${NC}"
echo "-----------------------------------"
echo "Add to your frontend .env file:"
echo ""
echo "  $(terraform output frontend_env_variable)"
echo ""
echo "Or set in Qovery:"
echo "  qovery environment variable create \\"
echo "    --key NEXT_PUBLIC_VISIO_HEALTH_URL \\"
echo "    --value \"${HEALTH_URL}\""
echo ""

echo -e "${YELLOW}Monitoring:${NC}"
echo "-----------------------------------"
echo "View logs:"
echo "  $(terraform output -raw cloudwatch_logs_command)"
echo ""
echo "CloudWatch Dashboard:"
echo "  $(terraform output cloudwatch_dashboard_url)"
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Next Steps:${NC}"
echo -e "${GREEN}========================================${NC}"
echo "1. Test the endpoint: curl ${HEALTH_URL}"
echo "2. Add NEXT_PUBLIC_VISIO_HEALTH_URL to your frontend"
echo "3. Implement VisioHealthIndicator component (see README)"
echo "4. Monitor in CloudWatch"
echo ""
echo -e "${GREEN}Deployment completed successfully!${NC}"
