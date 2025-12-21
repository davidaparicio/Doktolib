#!/bin/bash
set -euo pipefail

# Extract first 8 characters from QOVERY_ENVIRONMENT_ID
# This is used to create unique AWS resource names per environment
ENVIRONMENT_ID_FIRST_DIGITS="${QOVERY_ENVIRONMENT_ID:0:8}"

echo "Environment ID: ${QOVERY_ENVIRONMENT_ID}"
echo "First 8 digits: ${ENVIRONMENT_ID_FIRST_DIGITS}"

# Create output directory if it doesn't exist
mkdir -p /qovery-output

# Write to qovery-output.json in the required format
cat > /qovery-output/qovery-output.json <<EOF
{
  "ENVIRONMENT_ID_FIRST_DIGITS": {
    "sensitive": false,
    "value": "${ENVIRONMENT_ID_FIRST_DIGITS}"
  }
}
EOF

echo "Successfully wrote ENVIRONMENT_ID_FIRST_DIGITS to /qovery-output/qovery-output.json"
cat /qovery-output/qovery-output.json
