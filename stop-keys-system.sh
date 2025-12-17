#!/bin/bash

# EHR Keys Management System Shutdown Script
# Stops Docker containers while preserving PostgreSQL data volume

echo "Stopping EHR Keys Management System (OpenBao + PostgreSQL)..."
docker-compose -f docker-compose-keys.yml down

echo ""
echo "System Shutdown Complete"
echo "========================"
echo "Note: PostgreSQL data is preserved in Docker volume 'ehr-keys-postgres-data'"
echo ""
echo "To restart the system: ./start-keys-system.sh"
echo "To completely reset: ./setup-keys-system.sh"