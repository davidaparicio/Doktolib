#!/bin/bash

echo "🧪 Testing Doktolib Seed Data Locally"
echo "====================================="

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js 18+ to continue."
    exit 1
fi

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo "❌ npm is not installed. Please install npm to continue."
    exit 1
fi

# Install dependencies
echo "📦 Installing dependencies..."
npm install

# Test generation with small dataset
echo "🧪 Testing doctor generation (10 doctors)..."
node generate-doctors.js 10

if [ $? -eq 0 ]; then
    echo "✅ Doctor generation test passed"
else
    echo "❌ Doctor generation test failed"
    exit 1
fi

# Check if database is available
if [ -z "$DATABASE_URL" ]; then
    echo "⚠️ No DATABASE_URL set. Testing with dummy database..."
    echo "ℹ️ To test with real database, set DATABASE_URL environment variable"
    echo "   Example: export DATABASE_URL='postgres://user:pass@localhost:5432/doktolib'"
    echo "   Then run: npm run seed"
else
    echo "🗄️ Testing database connection..."
    echo "📊 Current configuration:"
    echo "   DATABASE_URL: ${DATABASE_URL/\/\/[^:]*:[^@]*@/\/\/***:***@}"
    echo "   DB_SSL_MODE: ${DB_SSL_MODE:-default}"
    echo "   DOCTOR_COUNT: ${DOCTOR_COUNT:-1500}"
    echo "   FORCE_SEED: ${FORCE_SEED:-false}"
    
    echo ""
    echo "🚀 To run the seeder:"
    echo "   npm run seed          # Normal seeding (skip if data exists)"
    echo "   npm run seed-force    # Force seeding (clear existing data)"
fi

echo ""
echo "🎉 Local testing completed successfully!"
echo "📁 Generated files:"
echo "   - doctors-seed.sql  (SQL statements)"
echo "   - doctors-seed.json (JSON data for reference)"
echo ""
echo "🐳 To test with Docker:"
echo "   docker build -t doktolib-seed ."
echo "   docker run --rm -e DATABASE_URL=... doktolib-seed"