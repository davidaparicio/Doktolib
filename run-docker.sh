#!/bin/bash

# Doktolib Docker Startup Script
# This script provides easy ways to run the application with different configurations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}    Doktolib Docker Runner${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker first."
    exit 1
fi

print_header

# Set environment file based on argument or default to local
ENV_FILE=".env.local"
case "${1:-local}" in
    "local")
        ENV_FILE=".env.local"
        print_status "Using local development configuration"
        ;;
    "docker")
        ENV_FILE=".env.docker"
        print_status "Using Docker container-to-container configuration"
        ;;
    "production")
        ENV_FILE=".env.production"
        print_status "Using production configuration"
        ;;
    *)
        print_warning "Unknown configuration '$1'. Using local configuration."
        ENV_FILE=".env.local"
        ;;
esac

# Check if environment file exists
if [[ ! -f "$ENV_FILE" ]]; then
    print_warning "Environment file $ENV_FILE not found. Creating from example..."
    cp .env.example "$ENV_FILE"
fi

# Export environment variables
set -a
source "$ENV_FILE"
set +a

print_status "Configuration loaded from $ENV_FILE"
print_status "Frontend will be built with API URL: ${NEXT_PUBLIC_API_URL}"

# Run docker compose with build args
print_status "Starting services with Docker Compose (building with API URL)..."
print_warning "Note: Frontend is rebuilt with the specified API URL"
docker compose up --build

print_status "Services started successfully!"
echo
print_status "Access the application:"
echo "  • Frontend: http://localhost:3000"
echo "  • Backend API: http://localhost:8080"
echo "  • Database: localhost:5432"
echo
print_status "To stop the services, press Ctrl+C or run:"
echo "  docker compose down"