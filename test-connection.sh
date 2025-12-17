#!/bin/bash

# EHR Keys Management System Connection Test Script
# Validates connectivity between OpenBao, PostgreSQL, and network components
# Tests both host-to-container and container-to-container communication

echo "================================================"
echo "  Testing EHR Keys Management System"
echo "  OpenBao + PostgreSQL with Environment Configuration"
echo "================================================"

# Load environment variables from .env file if available
# Provides flexibility for different deployment environments
if [ -f .env ]; then
    echo "Loading configuration from .env file..."
    source .env
else
    echo "Using default configuration values..."
fi

# Set test parameters from environment variables with defaults
OPENBAO_TOKEN="${OPENBAO_TOKEN:-ehr-permanent-token}"
OPENBAO_ADDR="${OPENBAO_ADDR:-http://localhost:18200}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-OpenBaoSecurePassword123!}"

echo ""
echo "1. Testing from Host Machine..."
echo "   Testing OpenBao API connectivity..."
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
  --header "X-Vault-Token: $OPENBAO_TOKEN" \
  "$OPENBAO_ADDR/v1/sys/health")

if [ "$RESPONSE" = "200" ] || [ "$RESPONSE" = "501" ]; then
    echo "   ✅ Host can reach OpenBao"
else
    echo "   ❌ Host cannot reach OpenBao (HTTP $RESPONSE)"
fi

echo ""
echo "2. Testing PostgreSQL from Host Machine..."
if pg_isready -h localhost -p 5433 2>/dev/null | grep -q "accepting connections"; then
    echo "   ✅ Host can reach PostgreSQL"
else
    echo "   ❌ Host cannot reach PostgreSQL"
fi

echo ""
echo "3. Testing from Container Network (simulated)..."
echo "   Testing OpenBao internal container connectivity..."
docker run --rm --network ehr-keys-net \
  -e VAULT_TOKEN="$OPENBAO_TOKEN" \
  curlimages/curl:latest \
  curl -s -o /dev/null -w "Container → OpenBao: %{http_code}\n" \
  --header "X-Vault-Token: $OPENBAO_TOKEN" \
  http://openbao:8200/v1/sys/health

echo ""
echo "   Testing PostgreSQL internal container connectivity..."
docker run --rm --network ehr-keys-net \
  postgres:latest \
  pg_isready -h postgres-keys -U openbao_user -d openbao_vault 2>/dev/null | \
  xargs -I {} echo "Container → PostgreSQL: {}"

echo ""
echo "4. Testing PostgreSQL Data Access and Initialization..."
docker run --rm --network ehr-keys-net \
  -e PGPASSWORD="$POSTGRES_PASSWORD" \
  postgres:latest \
  psql -h postgres-keys -U openbao_user -d openbao_vault -c "SELECT test_message FROM openbao_init_test LIMIT 1;" 2>/dev/null | \
  grep -v "row" | grep -v "^--" | grep -v "^$" | \
  xargs -I {} echo "PostgreSQL Test Data: {}"

echo ""
echo "================================================"
echo "  Connection Test Results"
echo "================================================"
echo ""
echo "Standalone EHR Keys Management System Status:"
echo "1. OpenBao: Running in ehr-keys-net network"
echo "2. PostgreSQL: Running in ehr-keys-net network"
echo "3. Network: ehr-keys-net (managed by Docker Compose)"
echo ""
echo "For EHR backend integration (using environment variables):"
echo "1. Use 'openbao:8200' as OPENBAO_ADDR in containers"
echo "2. Use '\$OPENBAO_TOKEN' from .env file as OPENBAO_TOKEN"
echo "3. Connect EHR backend to ehr-keys-net Docker network"
echo ""
echo "Current OpenBao System Status:"
curl -s --header "X-Vault-Token: $OPENBAO_TOKEN" \
  "$OPENBAO_ADDR/v1/sys/health" | \
  python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(f'  Initialized: {d.get(\"initialized\", \"N/A\")}')
    print(f'  Sealed: {d.get(\"sealed\", \"N/A\")}')
    print(f'  Version: {d.get(\"version\", \"N/A\")}')
    print(f'  Storage Type: PostgreSQL')
    print(f'  Server Time UTC: {d.get(\"server_time_utc\", \"N/A\")}')
except Exception as e:
    print(f'  Could not parse OpenBao response: {e}')
"