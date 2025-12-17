#!/bin/bash

# EHR Keys Management System Startup Script
# Starts Docker containers for OpenBao and PostgreSQL with environment configuration

echo "Starting EHR Keys Management System (OpenBao + PostgreSQL)..."
echo "Loading configuration from environment variables..."

# Load environment variables from .env file if available
if [ -f .env ]; then
    source .env
    echo "Configuration loaded from .env file"
else
    echo "Using default configuration values"
fi

# Start Docker containers in detached mode
docker-compose -f docker-compose-keys.yml up -d

echo ""
echo "System Startup Complete"
echo "======================="
echo "OpenBao UI: ${OPENBAO_ADDR:-http://localhost:18200}/ui"
echo "OpenBao Token: ${OPENBAO_TOKEN:-ehr-permanent-token}"
echo "PostgreSQL: localhost:5433 (user: openbao_user)"
echo "Network: ehr-keys-net (managed by Docker Compose)"
echo ""
echo "Logs: ./logs-keys-system.sh"
echo "Test: ./test-connection.sh"
echo "Configure: ./configure-openbao-keys-management.sh"