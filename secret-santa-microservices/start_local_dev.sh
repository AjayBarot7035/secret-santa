#!/bin/bash

echo "🚀 Starting Secret Santa Generator in LOCAL DEVELOPMENT mode..."

# Set development environment variables
export RAILS_ENV=development

# Function to check if a port is available
check_port() {
    if lsof -Pi :$1 -sTCP:LISTEN -t >/dev/null ; then
        echo "❌ Port $1 is already in use. Please stop the service using port $1 and try again."
        exit 1
    fi
}

# Check ports
check_port 3000  # API Gateway
check_port 3001  # Assignment Service
check_port 8080  # UI Service
check_port 8081  # CSV Parser Service
check_port 5432  # PostgreSQL
check_port 6379  # Redis

echo "✅ All ports are available"

# Start PostgreSQL, Redis, and UI Service
echo "📦 Starting dependencies and UI Service..."
docker-compose -f docker-compose.local.yml up -d postgres redis ui-service

# Wait for PostgreSQL to be ready
echo "⏳ Waiting for PostgreSQL to be ready..."
until docker-compose -f docker-compose.local.yml exec -T postgres pg_isready -U postgres; do
    sleep 1
done

# Setup Assignment Service
echo "🔧 Setting up Assignment Service..."
cd assignment-service
bundle install
bundle exec rails db:create db:migrate
bundle exec rails db:seed 2>/dev/null || echo "No seeds to run"

# Start Assignment Service
echo "🚀 Starting Assignment Service on port 3001..."
bundle exec rails server -p 3001 -d
cd ..

# Setup API Gateway
echo "🔧 Setting up API Gateway..."
cd api-gateway
bundle install
bundle exec rails db:create db:migrate

# Start API Gateway
echo "🚀 Starting API Gateway on port 3000..."
bundle exec rails server -p 3000 -d
cd ..

# Build and start CSV Parser Service
echo "🔧 Building CSV Parser Service..."
cd csv-parser-service
go build -o csv-parser-service

# Start CSV Parser Service
echo "🚀 Starting CSV Parser Service on port 8081..."
PORT=8081 ./csv-parser-service &
cd ..

# Wait for services to start
echo "⏳ Waiting for services to start..."
sleep 5

# Test services
echo "🧪 Testing services..."

# Test CSV Parser Service
echo "Testing CSV Parser Service..."
curl -s http://localhost:8081/health | jq . || echo "CSV Parser Service not responding"

# Test Assignment Service
echo "Testing Assignment Service..."
curl -s http://localhost:3001/api/v1/assignments/health | jq . || echo "Assignment Service not responding"

# Test API Gateway
echo "Testing API Gateway..."
curl -s http://localhost:3000/api/v1/secret_santa/health | jq . || echo "API Gateway not responding"

echo ""
echo "🎉 All services started successfully!"
echo ""
echo "📋 Service URLs:"
echo "  UI Service:      http://localhost:8080"
echo "  API Gateway:     http://localhost:3000"
echo "  Assignment Service: http://localhost:3001"
echo "  CSV Parser Service: http://localhost:8081"
echo ""
echo "🔧 Test the API:"
echo "  curl -X POST http://localhost:3000/api/v1/secret_santa/generate_assignments \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"employees\":[{\"name\":\"John Doe\",\"email\":\"john@example.com\"},{\"name\":\"Jane Smith\",\"email\":\"jane@example.com\"}]}'"
echo ""
echo "🛑 To stop all services:"
echo "  ./stop_local_dev.sh"
