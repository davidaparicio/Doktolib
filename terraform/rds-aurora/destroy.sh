#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${RED}========================================${NC}"
echo -e "${RED}RDS Aurora Cluster Destroy Script${NC}"
echo -e "${RED}========================================${NC}"
echo ""

# Check if Terraform is initialized
if [ ! -d "$SCRIPT_DIR/.terraform" ]; then
    echo -e "${RED}❌ Terraform not initialized${NC}"
    echo "Run: terraform init"
    exit 1
fi

cd "$SCRIPT_DIR"

# Check if cluster exists
if [ ! -f "$SCRIPT_DIR/terraform.tfstate" ]; then
    echo -e "${YELLOW}⚠️  No Terraform state found${NC}"
    echo "No resources to destroy"
    exit 0
fi

# Show current resources
echo "Current Aurora resources:"
echo "-----------------------------------"
terraform show | grep -E "cluster_identifier|database_name|cluster_endpoint" || echo "No cluster found"
echo ""

# Get cluster name from state
CLUSTER_NAME=$(terraform output -raw cluster_id 2>/dev/null || echo "unknown")
DATABASE_URL=$(terraform output -raw qovery_database_url 2>/dev/null || echo "unknown")

echo -e "${YELLOW}⚠️  WARNING: This will permanently delete:${NC}"
echo "   • Aurora cluster: ${CLUSTER_NAME}"
echo "   • All databases and data"
echo "   • Security groups"
echo "   • Subnet groups"
echo "   • Secrets in AWS Secrets Manager (after recovery period)"
echo ""
echo -e "${YELLOW}A final snapshot will be created before deletion${NC}"
echo -e "${YELLOW}(unless skip_final_snapshot = true in terraform.tfvars)${NC}"
echo ""

# Double confirmation
read -p "Are you ABSOLUTELY sure you want to destroy this cluster? (yes/NO) " -r
echo
if [[ ! $REPLY == "yes" ]]; then
    echo "Destruction cancelled (must type 'yes' exactly)"
    exit 0
fi

read -p "Type the cluster name '${CLUSTER_NAME}' to confirm: " -r
echo
if [[ ! $REPLY == "$CLUSTER_NAME" ]]; then
    echo "Cluster name does not match. Destruction cancelled."
    exit 0
fi

# Optional: Create manual snapshot before destroying
read -p "Create a manual snapshot before destroying? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    SNAPSHOT_ID="${CLUSTER_NAME}-manual-$(date +%Y%m%d-%H%M%S)"
    echo ""
    echo "Creating manual snapshot: ${SNAPSHOT_ID}"
    aws rds create-db-cluster-snapshot \
        --db-cluster-identifier "$CLUSTER_NAME" \
        --db-cluster-snapshot-identifier "$SNAPSHOT_ID" || true
    echo -e "${GREEN}✓ Snapshot created: ${SNAPSHOT_ID}${NC}"
    echo ""
fi

# Show destroy plan
echo ""
echo "Generating destroy plan..."
terraform plan -destroy

echo ""
echo -e "${RED}========================================${NC}"
echo -e "${RED}FINAL CONFIRMATION${NC}"
echo -e "${RED}========================================${NC}"
echo ""
read -p "Proceed with destruction? (yes/NO) " -r
echo
if [[ ! $REPLY == "yes" ]]; then
    echo "Destruction cancelled"
    exit 0
fi

# Destroy resources
echo ""
echo "Destroying Aurora Serverless cluster..."
echo "This may take 5-10 minutes..."
terraform destroy -auto-approve

# Clean up local files
echo ""
read -p "Delete local Terraform state files? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -f terraform.tfstate*
    rm -f outputs.json
    rm -f tfplan
    echo -e "${GREEN}✓ Local state files deleted${NC}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Destruction Complete${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Notes:"
echo "• Final snapshot (if enabled) will be retained"
echo "• Secrets in Secrets Manager will be deleted after recovery period"
echo "• Manual snapshots (if created) are retained indefinitely"
echo ""
echo "To restore from snapshot in the future:"
echo "1. Note the snapshot identifier"
echo "2. Use terraform with snapshot_identifier variable"
echo ""
echo -e "${GREEN}Cleanup completed successfully${NC}"
