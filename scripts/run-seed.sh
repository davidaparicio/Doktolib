#!/bin/bash

# Doktolib Seed Data Runner
# Usage: ./scripts/run-seed.sh [doctor_count] [force_seed]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
DOCTOR_COUNT="${1:-50}"
FORCE_SEED="${2:-false}"

echo -e "${BLUE}🌱 Doktolib Seed Data Runner${NC}"
echo -e "${BLUE}================================${NC}"

# Validate doctor count
if ! [[ "$DOCTOR_COUNT" =~ ^[0-9]+$ ]] || [ "$DOCTOR_COUNT" -lt 1 ]; then
    echo -e "${RED}❌ Invalid doctor count: $DOCTOR_COUNT (must be a positive integer)${NC}"
    exit 1
fi

# Validate force seed flag
if [[ ! "$FORCE_SEED" =~ ^(true|false)$ ]]; then
    echo -e "${RED}❌ Invalid force seed flag: $FORCE_SEED (must be true or false)${NC}"
    exit 1
fi

echo -e "${GREEN}📋 Seed Configuration:${NC}"
echo -e "  Doctor Count: ${YELLOW}$DOCTOR_COUNT${NC}"
echo -e "  Force Seed:   ${YELLOW}$FORCE_SEED${NC}"
echo ""

# Check if database service is running
echo -e "${BLUE}🔍 Checking if database service is running...${NC}"
if ! docker compose ps | grep -q "postgres.*Up"; then
    echo -e "${YELLOW}⚠️  Database service is not running, starting it now...${NC}"
    docker compose up -d postgres
    echo -e "${BLUE}⏱️  Waiting for database to be ready...${NC}"
    sleep 10
fi

# Test database connectivity
echo -e "${BLUE}🔗 Testing database connectivity...${NC}"
if docker compose exec postgres psql -U doktolib -d doktolib -c "SELECT version();" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Database is accessible${NC}"
else
    echo -e "${RED}❌ Database is not accessible${NC}"
    echo -e "${YELLOW}💡 Check database logs: docker compose logs postgres${NC}"
    exit 1
fi

# Set environment variables
export SEED_DOCTOR_COUNT="$DOCTOR_COUNT"
export SEED_FORCE="$FORCE_SEED"

echo -e "${BLUE}🌱 Starting seed data generation...${NC}"
echo -e "${YELLOW}📊 This will generate $DOCTOR_COUNT doctors${NC}"
echo -e "${YELLOW}🛑 Press Ctrl+C to stop${NC}"
echo ""

# Function to handle cleanup
cleanup() {
    echo -e "\n${YELLOW}🧹 Cleaning up...${NC}"
    docker compose --profile seed down
    exit 0
}

# Set trap for cleanup
trap cleanup SIGINT SIGTERM

# Run the seed data service
docker compose --profile seed up --build --abort-on-container-exit

# Check if seeding was successful
if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}✅ Seed data generation completed successfully!${NC}"
    
    # Show database statistics
    echo -e "${BLUE}📊 Database Statistics:${NC}"
    DOCTOR_COUNT_DB=$(docker compose exec postgres psql -U doktolib -d doktolib -t -c "SELECT COUNT(*) FROM doctors;" 2>/dev/null | tr -d ' ')
    if [ -n "$DOCTOR_COUNT_DB" ]; then
        echo -e "  Total Doctors: ${GREEN}$DOCTOR_COUNT_DB${NC}"
    else
        echo -e "  ${YELLOW}Unable to query database statistics${NC}"
    fi
else
    echo -e "\n${RED}❌ Seed data generation failed!${NC}"
    echo -e "${YELLOW}💡 Check the logs above for error details${NC}"
    exit 1
fi

# Cleanup
cleanup