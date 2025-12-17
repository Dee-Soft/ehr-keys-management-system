#!/bin/bash

# EHR Keys Management System Log Viewer
# Displays recent logs from OpenBao and PostgreSQL containers
# Shows structured JSON logs with ISO 8601 timestamps from OpenBao

echo "EHR Keys Management System - Container Logs"
echo "==========================================="
echo ""
echo "OpenBao Logs (last 50 lines with ISO timestamps):"
echo "-------------------------------------------------"
docker logs openbao --tail 50 2>/dev/null || echo "OpenBao container not running"

echo ""
echo "PostgreSQL Logs (last 20 lines):"
echo "--------------------------------"
docker logs postgres-keys --tail 20 2>/dev/null || echo "PostgreSQL container not running"

echo ""
echo "Note: OpenBao logs are stored in ./openbao/logs/ with JSON format"
echo "      PostgreSQL logs use Docker's JSON logging driver"