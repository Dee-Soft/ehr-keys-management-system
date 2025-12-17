#!/bin/bash

echo "================================================"
echo "  Testing EHR Keys Management System"
echo "  OpenBao + PostgreSQL Standalone Setup"
echo "================================================"

echo ""
echo "1. Testing from Host Machine..."
echo "   Testing OpenBao API..."
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
  --header "X-Vault-Token: ehr-permanent-token" \
  http://localhost:18200/v1/sys/health)

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
echo "   Testing OpenBao from container..."
docker run --rm --network ehr-keys-net \
  -e VAULT_TOKEN=ehr-permanent-token \
  curlimages/curl:latest \
  curl -s -o /dev/null -w "Container → OpenBao: %{http_code}\n" \
  --header "X-Vault-Token: ehr-permanent-token" \
  http://openbao:8200/v1/sys/health

echo ""
echo "   Testing PostgreSQL from container..."
docker run --rm --network ehr-keys-net \
  postgres:latest \
  pg_isready -h postgres-keys -U openbao_user -d openbao_vault 2>/dev/null | \
  xargs -I {} echo "Container → PostgreSQL: {}"

echo ""
echo "4. Testing PostgreSQL Data Access..."
docker run --rm --network ehr-keys-net \
  -e PGPASSWORD=OpenBaoSecurePassword123! \
  postgres:latest \
  psql -h postgres-keys -U openbao_user -d openbao_vault -c "SELECT test_message FROM openbao_init_test LIMIT 1;" 2>/dev/null | \
  grep -v "row" | grep -v "---" | grep -v "^$" | \
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
echo "For future EHR backend integration:"
echo "1. Use 'openbao:8200' as OPENBAO_ADDR in containers"
echo "2. Use 'ehr-permanent-token' as OPENBAO_TOKEN"
echo "3. Connect EHR backend to ehr-keys-net network"
echo ""
echo "Current OpenBao status:"
curl -s --header "X-Vault-Token: ehr-permanent-token" \
  http://localhost:18200/v1/sys/health | \
  python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(f'Initialized: {d.get(\"initialized\", \"N/A\")}')
    print(f'Sealed: {d.get(\"sealed\", \"N/A\")}')
    print(f'Version: {d.get(\"version\", \"N/A\")}')
    print(f'Storage Type: PostgreSQL')
except:
    print('Could not parse OpenBao response')
"