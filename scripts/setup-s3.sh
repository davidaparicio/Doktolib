#!/bin/bash

# Doktolib S3 Setup Script
# This script helps set up AWS S3 infrastructure for medical file uploads

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Banner
echo "=================================================="
echo "🏗️  Doktolib S3 Medical Files Setup"
echo "=================================================="
echo ""

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if AWS CLI is available
if ! command -v aws >/dev/null 2>&1; then
    print_warning "AWS CLI not found. Installing via Docker..."
fi

# Function to prompt for input
prompt_input() {
    local prompt="$1"
    local default="$2"
    local varname="$3"
    
    if [ -n "$default" ]; then
        read -p "$prompt [$default]: " input
        input="${input:-$default}"
    else
        read -p "$prompt: " input
        while [ -z "$input" ]; do
            print_error "This field is required"
            read -p "$prompt: " input
        done
    fi
    
    declare -g "$varname"="$input"
}

# Get configuration from user
print_status "Collecting configuration information..."

prompt_input "AWS Access Key ID" "" "AWS_ACCESS_KEY_ID"
prompt_input "AWS Secret Access Key" "" "AWS_SECRET_ACCESS_KEY"  
prompt_input "AWS Region" "us-east-1" "AWS_REGION"
prompt_input "S3 Bucket Name" "doktolib-medical-files-$(date +%s)" "BUCKET_NAME"
prompt_input "Environment" "development" "ENVIRONMENT"

# Validate AWS credentials
print_status "Validating AWS credentials..."

# Test AWS credentials using Docker
AWS_TEST_RESULT=$(docker run --rm \
    -e AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
    -e AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
    -e AWS_DEFAULT_REGION="$AWS_REGION" \
    amazon/aws-cli sts get-caller-identity --output json 2>/dev/null || echo "ERROR")

if [ "$AWS_TEST_RESULT" = "ERROR" ]; then
    print_error "Invalid AWS credentials. Please check your access key and secret key."
    exit 1
fi

print_success "AWS credentials validated"

# Check if bucket already exists
print_status "Checking if S3 bucket already exists..."

BUCKET_CHECK=$(docker run --rm \
    -e AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
    -e AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
    -e AWS_DEFAULT_REGION="$AWS_REGION" \
    amazon/aws-cli s3 ls "s3://$BUCKET_NAME" 2>/dev/null || echo "NOT_FOUND")

if [ "$BUCKET_CHECK" != "NOT_FOUND" ]; then
    print_warning "S3 bucket '$BUCKET_NAME' already exists. Do you want to use it? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        print_error "Please choose a different bucket name"
        exit 1
    fi
    BUCKET_EXISTS=true
else
    BUCKET_EXISTS=false
fi

# Setup options
echo ""
print_status "Setup Options:"
echo "1. Create S3 bucket using Docker Compose + Terraform"
echo "2. Create S3 bucket using standalone Terraform"
echo "3. Skip S3 creation (bucket already exists)"
echo ""

read -p "Choose setup method (1-3): " setup_method

case $setup_method in
    1)
        print_status "Setting up S3 bucket using Docker Compose + Terraform..."
        
        # Create .env file for Docker Compose
        cat > .env.s3 << EOF
# AWS Credentials
AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
AWS_REGION=$AWS_REGION

# S3 Configuration
S3_BUCKET_NAME=$BUCKET_NAME
S3_ENVIRONMENT=$ENVIRONMENT
S3_ALLOWED_ORIGINS=["http://localhost:3000","http://frontend:3000"]

# Terraform Variables
TF_VAR_bucket_name=$BUCKET_NAME
TF_VAR_aws_region=$AWS_REGION
TF_VAR_environment=$ENVIRONMENT
TF_VAR_allowed_origins=["http://localhost:3000","http://frontend:3000"]
EOF

        print_success "Created .env.s3 configuration file"
        
        # Run Terraform via Docker Compose
        print_status "Running Terraform to create S3 bucket..."
        
        docker compose --profile terraform --env-file .env.s3 up --build terraform-s3
        
        if [ $? -eq 0 ]; then
            print_success "S3 bucket created successfully via Docker Compose"
        else
            print_error "Failed to create S3 bucket via Docker Compose"
            exit 1
        fi
        ;;
        
    2)
        print_status "Setting up S3 bucket using standalone Terraform..."
        
        cd terraform/s3-bucket
        
        # Initialize Terraform
        docker run --rm -v "$(pwd)":/terraform -w /terraform \
            -e AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
            -e AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
            -e TF_VAR_bucket_name="$BUCKET_NAME" \
            -e TF_VAR_aws_region="$AWS_REGION" \
            -e TF_VAR_environment="$ENVIRONMENT" \
            hashicorp/terraform:latest init
            
        # Apply Terraform configuration
        docker run --rm -v "$(pwd)":/terraform -w /terraform \
            -e AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
            -e AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
            -e TF_VAR_bucket_name="$BUCKET_NAME" \
            -e TF_VAR_aws_region="$AWS_REGION" \
            -e TF_VAR_environment="$ENVIRONMENT" \
            hashicorp/terraform:latest apply -auto-approve
            
        cd ../..
        
        if [ $? -eq 0 ]; then
            print_success "S3 bucket created successfully via standalone Terraform"
        else
            print_error "Failed to create S3 bucket via standalone Terraform"
            exit 1
        fi
        ;;
        
    3)
        print_status "Skipping S3 bucket creation..."
        ;;
        
    *)
        print_error "Invalid setup method selected"
        exit 1
        ;;
esac

# Update environment configuration
print_status "Updating environment configuration..."

# Update .env.example
if [ -f .env.example ]; then
    # Create backup
    cp .env.example .env.example.backup
    
    # Update S3 configuration in .env.example
    sed -i.bak "s/AWS_S3_BUCKET=.*/AWS_S3_BUCKET=$BUCKET_NAME/" .env.example
    sed -i.bak "s/AWS_REGION=.*/AWS_REGION=$AWS_REGION/" .env.example
    sed -i.bak "s/S3_BUCKET_NAME=.*/S3_BUCKET_NAME=$BUCKET_NAME/" .env.example
    sed -i.bak "s/TF_VAR_bucket_name=.*/TF_VAR_bucket_name=$BUCKET_NAME/" .env.example
    
    print_success "Updated .env.example with S3 configuration"
fi

# Create local environment file
cat > .env.local << EOF
# Doktolib Local Development Configuration
# Generated by setup-s3.sh on $(date)

# Frontend Configuration
NEXT_PUBLIC_API_URL=http://localhost:8080

# Backend Configuration
DATABASE_URL=postgres://doktolib:password123@localhost:5432/doktolib
DB_SSL_MODE=disable
PORT=8080
GIN_MODE=debug

# AWS S3 Configuration
AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
AWS_REGION=$AWS_REGION
AWS_S3_BUCKET=$BUCKET_NAME

# PostgreSQL Configuration
POSTGRES_DB=doktolib
POSTGRES_USER=doktolib
POSTGRES_PASSWORD=password123
EOF

print_success "Created .env.local for local development"

# Test S3 connectivity
print_status "Testing S3 connectivity..."

TEST_FILE="/tmp/doktolib-test-$(date +%s).txt"
echo "Doktolib S3 connectivity test - $(date)" > "$TEST_FILE"

# Upload test file
UPLOAD_RESULT=$(docker run --rm \
    -v "$TEST_FILE:/tmp/test.txt" \
    -e AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
    -e AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
    -e AWS_DEFAULT_REGION="$AWS_REGION" \
    amazon/aws-cli s3 cp /tmp/test.txt "s3://$BUCKET_NAME/test.txt" 2>&1 || echo "ERROR")

if [[ "$UPLOAD_RESULT" == *"ERROR"* ]]; then
    print_error "S3 upload test failed. Check bucket permissions."
    print_error "Error: $UPLOAD_RESULT"
else
    print_success "S3 upload test successful"
    
    # Clean up test file
    docker run --rm \
        -e AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
        -e AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
        -e AWS_DEFAULT_REGION="$AWS_REGION" \
        amazon/aws-cli s3 rm "s3://$BUCKET_NAME/test.txt" >/dev/null 2>&1
fi

rm -f "$TEST_FILE"

# Final instructions
echo ""
echo "=================================================="
print_success "S3 Setup Complete!"
echo "=================================================="
echo ""
print_status "Configuration Summary:"
echo "  • AWS Region: $AWS_REGION"
echo "  • S3 Bucket: $BUCKET_NAME"
echo "  • Environment: $ENVIRONMENT"
echo ""
print_status "Next Steps:"
echo "1. Run the application with S3 support:"
echo "   docker compose up --build"
echo ""
echo "2. Access the Medical Files page:"
echo "   http://localhost:3000/files"
echo ""
echo "3. For production deployment, add these secrets to GitHub:"
echo "   - AWS_ACCESS_KEY_ID"
echo "   - AWS_SECRET_ACCESS_KEY"
echo "   - AWS_S3_BUCKET"
echo ""
print_warning "Keep your AWS credentials secure and never commit them to version control!"
echo ""

# Offer to start the application
read -p "Start the application now? (y/N): " start_app
if [[ "$start_app" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    print_status "Starting Doktolib with S3 file upload support..."
    docker compose up --build
fi