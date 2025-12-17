#!/bin/bash

# EHR Keys Management System Setup Script
# Initializes OpenBao with PostgreSQL storage backend
# Configures logging with ISO 8601 timestamps for audit trail

echo "================================================"
echo "  EHR Keys Management System Setup"
echo "  OpenBao + PostgreSQL Storage with Structured Logging"
echo "================================================"

echo ""
echo "Creating directories and setting permissions..."
# Create log directory for OpenBao structured JSON logs
mkdir -p openbao/logs
# Set appropriate permissions for log directory
chmod -R 755 openbao/logs

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
echo "Testing OpenBao connectivity..."
# Load OpenBao token from environment variables with fallback
OPENBAO_TOKEN="${OPENBAO_TOKEN:-ehr-permanent-token}"
OPENBAO_ADDR="${OPENBAO_ADDR:-http://localhost:18200}"

RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
  --header "X-Vault-Token: $OPENBAO_TOKEN" \
  "$OPENBAO_ADDR/v1/sys/health")

if [ "$RESPONSE" = "200" ] || [ "$RESPONSE" = "501" ]; then
    echo "OpenBao is running with configured token"
    
    # Check if initialized and unsealed
    HEALTH=$(curl -s --header "X-Vault-Token: $OPENBAO_TOKEN" \
      "$OPENBAO_ADDR/v1/sys/health")
    
    if echo "$HEALTH" | grep -q '"sealed":false'; then
        echo "OpenBao is unsealed and ready for operations"
    fi
    
    echo ""
    echo "================================================"
    echo "            SETUP COMPLETE!"
    echo "================================================"
    echo ""
    echo "   Access Points:"
    echo "   OpenBao UI:      $OPENBAO_ADDR/ui"
    echo "   OpenBao API:     $OPENBAO_ADDR"
    echo "   PostgreSQL:      localhost:5433"
    echo ""
    echo "  Configuration Token: $OPENBAO_TOKEN"
    echo "   (Loaded from .env file or using default)"
    echo ""
    echo "  To configure cryptographic keys, run:"
    echo "   ./configure-openbao-keys-management.sh"
    echo ""
    echo "   Storage:"
    echo "   OpenBao data stored in: Docker volume 'ehr-keys-postgres-data'"
    echo "   OpenBao logs stored in: ./openbao/logs/ (JSON format with ISO timestamps)"
    echo "   PostgreSQL credentials: openbao_user / OpenBaoSecurePassword123!"
    echo ""
    echo "   For EHR backend integration, use environment variables:"
    echo "   OPENBAO_ADDR=http://openbao:8200"
    echo "   OPENBAO_TOKEN=\$OPENBAO_TOKEN"
    
    # Create configuration reference file
    cat > CONFIGURATION_REFERENCE.md << CONFIGEOF
# EHR Keys Management System Configuration

## Environment Configuration
- Primary configuration file: `.env` (not committed to version control)
- Default values used if `.env` file not present
- Token loaded from: \${OPENBAO_TOKEN:-ehr-permanent-token}

## Network Configuration
- OpenBao Container: openbao:8200 (internal), \${OPENBAO_ADDR:-http://localhost:18200} (external)
- PostgreSQL Container: postgres-keys:5432 (internal), localhost:5433 (external)
- Docker Network: ehr-keys-net (managed by Docker Compose)

## Data Persistence
- PostgreSQL data: Docker volume 'ehr-keys-postgres-data'
- OpenBao logs: ./openbao/logs/ (JSON format with ISO 8601 timestamps)
- Log retention: Docker logging driver (10MB max, 3 files)

## Integration with EHR Backend
In your EHR backend `.env` file:
\`\`\`bash
OPENBAO_ADDR=http://openbao:8200
OPENBAO_TOKEN=\$OPENBAO_TOKEN
\`\`\`

In your EHR `docker-compose.yml`, connect to the network:
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
- Extensions: uuid-ossp, pgcrypto

## Logging Configuration
- OpenBao: JSON format with ISO 8601 timestamps to ./openbao/logs/openbao.log
- PostgreSQL: Docker JSON logging driver with ISO timestamps
- Log level: info (OpenBao), default (PostgreSQL)

## Management Scripts
- \`./setup-keys-system.sh\` - Full system setup and initialization
- \`./start-keys-system.sh\` - Start existing containers
- \`./stop-keys-system.sh\` - Stop containers preserving data
- \`./logs-keys-system.sh\` - View container logs
- \`./test-connection.sh\` - Test system connectivity
- \`./configure-openbao-keys-management.sh\` - Configure cryptographic keys
CONFIGEOF

    echo ""
    echo "Configuration saved to: CONFIGURATION_REFERENCE.md"
else
    echo "OpenBao test failed (HTTP $RESPONSE)"
    echo "Check logs: docker logs openbao"
    exit 1
fi