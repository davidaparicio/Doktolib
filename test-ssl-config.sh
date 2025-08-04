#!/bin/bash

# Test script to demonstrate SSL configuration options
echo "🧪 Testing Doktolib SSL Configuration"
echo "======================================"

# Test 1: SSL Disabled (default)
echo ""
echo "Test 1: SSL Disabled (local development)"
echo "----------------------------------------"
export DATABASE_URL="postgres://user:pass@localhost:5432/test"
export DB_SSL_MODE="disable"
echo "DATABASE_URL: $DATABASE_URL"
echo "DB_SSL_MODE: $DB_SSL_MODE"
echo "Expected result: Connection string will include ?sslmode=disable"

# Test 2: SSL Required
echo ""
echo "Test 2: SSL Required (production)"
echo "--------------------------------"
export DATABASE_URL="postgres://user:pass@prod-host:5432/test"
export DB_SSL_MODE="require"
echo "DATABASE_URL: $DATABASE_URL"
echo "DB_SSL_MODE: $DB_SSL_MODE"
echo "Expected result: Connection string will include ?sslmode=require"

# Test 3: SSL with certificates
echo ""
echo "Test 3: SSL with certificates (full verification)"
echo "------------------------------------------------"
export DATABASE_URL="postgres://user:pass@secure-host:5432/test"
export DB_SSL_MODE="verify-full"
export DB_SSL_CERT="/path/to/client.crt"
export DB_SSL_KEY="/path/to/client.key"
export DB_SSL_ROOT_CERT="/path/to/ca.crt"
echo "DATABASE_URL: $DATABASE_URL"
echo "DB_SSL_MODE: $DB_SSL_MODE"
echo "DB_SSL_CERT: $DB_SSL_CERT"
echo "DB_SSL_KEY: $DB_SSL_KEY"
echo "DB_SSL_ROOT_CERT: $DB_SSL_ROOT_CERT"
echo "Expected result: Connection string will include SSL mode and certificate paths"

echo ""
echo "✅ To use these configurations:"
echo "   - For local development: Set DB_SSL_MODE=disable"
echo "   - For production: Set DB_SSL_MODE=require or verify-full"
echo "   - In Qovery: Configure db_ssl_mode in terraform.tfvars"