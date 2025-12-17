#!/bin/bash
echo "Starting EHR Keys Management System (OpenBao + PostgreSQL)..."
docker-compose -f docker-compose-keys.yml up -d
echo "OpenBao UI: http://localhost:18200/ui"
echo "OpenBao Token: ehr-permanent-token"
echo "PostgreSQL: localhost:5433 (user: openbao_user)"
echo "Network: ehr-keys-net (managed by Docker Compose)"