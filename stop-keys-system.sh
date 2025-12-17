#!/bin/bash
echo "Stopping EHR Keys Management System (OpenBao + PostgreSQL)..."
docker-compose -f docker-compose-keys.yml down
echo "Note: PostgreSQL data is preserved in Docker volume 'ehr-keys-postgres-data'"