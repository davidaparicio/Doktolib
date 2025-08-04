#!/bin/bash

echo "🚀 Starting Doktolib locally with Docker database"
echo "================================================="

# Build the backend binary
echo "📦 Building backend..."
cd backend
CGO_ENABLED=0 go build -o doktolib .
if [ $? -ne 0 ]; then
    echo "❌ Backend build failed"
    exit 1
fi

# Start database with docker-compose
echo "🗄️ Starting PostgreSQL database..."
cd ..
docker compose -f docker-compose.simple.yml up -d

# Wait for database to be ready
echo "⏳ Waiting for database to be ready..."
sleep 5

# Start backend
echo "🔧 Starting backend on port 8080..."
cd backend
export DATABASE_URL="postgres://doktolib:password123@localhost:5432/doktolib"
export DB_SSL_MODE="disable"
export PORT="8080"
export GIN_MODE="debug"
./doktolib &
BACKEND_PID=$!

# Wait for backend to start
sleep 3

# Test backend
echo "🧪 Testing backend..."
curl -s http://localhost:8080/api/v1/health > /dev/null
if [ $? -eq 0 ]; then
    echo "✅ Backend is running on http://localhost:8080"
else
    echo "❌ Backend failed to start"
    kill $BACKEND_PID 2>/dev/null
    exit 1
fi

# Start frontend
echo "🎨 Starting frontend on port 3000..."
cd ../frontend
export NEXT_PUBLIC_API_URL="http://localhost:8080"
npm run start &
FRONTEND_PID=$!

# Wait for frontend to start
sleep 5

# Test frontend
echo "🧪 Testing frontend..."
curl -s http://localhost:3000/api/health > /dev/null
if [ $? -eq 0 ]; then
    echo "✅ Frontend is running on http://localhost:3000"
else
    echo "❌ Frontend failed to start"
fi

echo ""
echo "🎉 Doktolib is running!"
echo "📊 Frontend: http://localhost:3000"
echo "🔗 Backend API: http://localhost:8080/api/v1"
echo "🔍 Health checks:"
echo "   - Backend: http://localhost:8080/api/v1/health"
echo "   - Frontend: http://localhost:3000/api/health"
echo ""
echo "Press Ctrl+C to stop all services"

# Function to cleanup on exit
cleanup() {
    echo ""
    echo "🛑 Stopping services..."
    kill $BACKEND_PID 2>/dev/null
    kill $FRONTEND_PID 2>/dev/null
    docker compose -f docker-compose.simple.yml down
    echo "✅ All services stopped"
}

# Set trap to cleanup on script exit
trap cleanup EXIT

# Wait for user to stop
wait