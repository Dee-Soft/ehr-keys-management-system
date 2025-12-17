#!/bin/bash

echo "================================================"
echo "  EHR Keys Management System Setup"
echo "  OpenBao + PostgreSQL Storage"
echo "================================================"

echo ""
echo "Creating directories..."
mkdir -p openbao/logs
chmod -R 777 openbao/logs

echo ""
echo "🐳 Cleaning up old network and containers..."
docker-compose -f docker-compose-keys.yml down 2>/dev/null
docker network rm ehr-keys-net 2>/dev/null || true

echo ""
echo "Starting Docker containers..."
docker-compose -f docker-compose-keys.yml up -d

echo ""
echo "Waiting for services to start (60 seconds)..."
sleep 60

echo ""
echo "Testing PostgreSQL connection..."
if docker-compose -f docker-compose-keys.yml exec postgres-keys \
   pg_isready -U openbao_user -d openbao_vault 2>/dev/null | grep -q "accepting connections"; then
    echo "PostgreSQL is running and accessible"
else
    echo "PostgreSQL connection failed"
    echo "Check logs: docker logs postgres-keys"
    exit 1
fi

echo ""
echo "Testing OpenBao with permanent token..."
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
  --header "X-Vault-Token: ehr-permanent-token" \
  http://localhost:18200/v1/sys/health)

if [ "$RESPONSE" = "200" ] || [ "$RESPONSE" = "501" ]; then
    echo "OpenBao is running with permanent token"
    
    # Check if initialized
    HEALTH=$(curl -s --header "X-Vault-Token: ehr-permanent-token" \
      http://localhost:18200/v1/sys/health)
    
    if echo "$HEALTH" | grep -q '"sealed":false'; then
        echo "OpenBao is unsealed and ready"
    fi
    
    echo ""
    echo "================================================"
    echo "            SETUP COMPLETE!"
    echo "================================================"
    echo ""
    echo "   Access Points:"
    echo "   OpenBao UI:      http://localhost:18200/ui"
    echo "   OpenBao API:     http://localhost:18200"
    echo "   PostgreSQL:      localhost:5433"
    echo ""
    echo "  Permanent Token: ehr-permanent-token"
    echo "   (This token NEVER changes)"
    echo ""
    echo "  To configure for EHR, run:"
    echo "   ./configure-openbao-keys-management.sh"
    echo ""
    echo "   Storage:"
    echo "   OpenBao data stored in: Docker volume 'ehr-keys-postgres-data'"
    echo "   PostgreSQL credentials: openbao_user / OpenBaoSecurePassword123!"
    echo ""
    echo "   For EHR backend integration, use in .env:"
    echo "   OPENBAO_ADDR=http://openbao:8200"
    echo "   OPENBAO_TOKEN=ehr-permanent-token"
    
    # Create configuration reference file
    cat > CONFIGURATION_REFERENCE.md << CONFIGEOF
# EHR Keys Management System Configuration

## Permanent Credentials
- OpenBao Token: ehr-permanent-token (NEVER CHANGES)
- PostgreSQL User: openbao_user / OpenBaoSecurePassword123!
- PostgreSQL Database: openbao_vault

## Network Configuration
- OpenBao Container: openbao:8200 (internal), localhost:18200 (external)
- PostgreSQL Container: postgres-keys:5432 (internal), localhost:5433 (external)
- Docker Network: ehr-keys-net (managed by Docker Compose)

## Data Persistence
- PostgreSQL data: Docker volume 'ehr-keys-postgres-data'
- OpenBao logs: ./openbao/logs/

## Integration with EHR Backend
In your EHR backend .env file:
OPENBAO_ADDR=http://openbao:8200
OPENBAO_TOKEN=ehr-permanent-token

In your EHR docker-compose.yml, connect to the network:
\`\`\`yaml
networks:
  ehr-keys-net:
    external: true
    name: ehr-keys-net
\`\`\`

## PostgreSQL Connection Details
- Host: postgres-keys (within docker network) or localhost (from host)
- Port: 5432 (internal) or 5433 (external)
- Database: openbao_vault
- Username: openbao_user
- Password: OpenBaoSecurePassword123!
- SSL Mode: disabled (for development)
CONFIGEOF

    echo ""
    echo "Configuration saved to: CONFIGURATION_REFERENCE.md"
else
    echo "OpenBao test failed (HTTP $RESPONSE)"
    echo "Check logs: docker logs openbao"
    exit 1
fi