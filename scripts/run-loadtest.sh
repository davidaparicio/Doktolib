#!/bin/bash

# Doktolib Load Test Runner
# Usage: ./scripts/run-loadtest.sh [scenario] [duration] [api_url]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
SCENARIO="${1:-normal}"
DURATION="${2:-5}"
BACKEND_URL="${3:-http://backend:8080}"

echo -e "${BLUE}🎭 Doktolib Load Test Runner${NC}"
echo -e "${BLUE}================================${NC}"

# Validate scenario
if [[ ! "$SCENARIO" =~ ^(light|normal|heavy|stress)$ ]]; then
    echo -e "${RED}❌ Invalid scenario: $SCENARIO${NC}"
    echo -e "${YELLOW}Valid scenarios: light, normal, heavy, stress${NC}"
    exit 1
fi

# Validate duration
if ! [[ "$DURATION" =~ ^[0-9]+$ ]] || [ "$DURATION" -lt 1 ]; then
    echo -e "${RED}❌ Invalid duration: $DURATION (must be a positive integer)${NC}"
    exit 1
fi

echo -e "${GREEN}📋 Test Configuration:${NC}"
echo -e "  Scenario: ${YELLOW}$SCENARIO${NC}"
echo -e "  Duration: ${YELLOW}$DURATION minutes${NC}"
echo -e "  Backend URL: ${YELLOW}$BACKEND_URL${NC}"
echo ""

# Check if services are running
echo -e "${BLUE}🔍 Checking if services are running...${NC}"
if ! docker compose ps | grep -q "backend.*Up"; then
    echo -e "${RED}❌ Backend service is not running${NC}"
    echo -e "${YELLOW}💡 Start services first: docker compose up -d${NC}"
    exit 1
fi

# Test API connectivity
echo -e "${BLUE}🔗 Testing API connectivity...${NC}"
if docker compose exec backend curl -f http://localhost:8080/api/v1/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ API is responding${NC}"
else
    echo -e "${RED}❌ API is not responding${NC}"
    echo -e "${YELLOW}💡 Check backend logs: docker compose logs backend${NC}"
    exit 1
fi

# Set environment variables
export LOAD_SCENARIO="$SCENARIO"
export LOAD_DURATION="$DURATION"
export LOAD_LOG_LEVEL="info"

echo -e "${BLUE}🚀 Starting load test...${NC}"
echo -e "${YELLOW}⏱️  This will run for $DURATION minutes${NC}"
echo -e "${YELLOW}🛑 Press Ctrl+C to stop early${NC}"
echo ""

# Function to handle cleanup
cleanup() {
    echo -e "\n${YELLOW}🧹 Cleaning up...${NC}"
    docker compose --profile loadtest down
    exit 0
}

# Set trap for cleanup
trap cleanup SIGINT SIGTERM

# Run the load test
docker compose --profile loadtest up --build --abort-on-container-exit

# Show final results
echo -e "\n${GREEN}✅ Load test completed!${NC}"
echo -e "${BLUE}📊 Check the output above for detailed statistics${NC}"

# Optionally save results
if command -v tee > /dev/null; then
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    RESULTS_FILE="load-test-results_${SCENARIO}_${TIMESTAMP}.log"
    echo -e "${YELLOW}💾 Saving results to: $RESULTS_FILE${NC}"
    docker compose logs load-generator | tee "$RESULTS_FILE"
fi

# Cleanup
cleanup