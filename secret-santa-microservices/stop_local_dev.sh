#!/bin/bash

echo "🛑 Stopping Secret Santa Generator..."

# Stop CSV Parser Service
echo "Stopping CSV Parser Service..."
pkill -f "csv-parser-service" || echo "CSV Parser Service not running"

# Stop Rails servers
echo "Stopping Rails servers..."
pkill -f "rails server" || echo "Rails servers not running"

# Stop Docker services
echo "Stopping Docker services..."
docker-compose -f docker-compose.local.yml down

echo "✅ All services stopped!"
