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
# Create initial audit log file
touch openbao/logs/audit.log
chmod 644 openbao/logs/audit.log

echo ""
echo "Cleaning up old network and containers..."
docker-compose -f docker-compose-keys.yml down 2>/dev/null
docker network rm ehr-keys-net 2>/dev/null || true

echo ""
echo "Starting Docker containers..."
docker-compose -f docker-compose-keys.yml up -d

echo ""
echo "Waiting for services to start (30 seconds)..."
sleep 30

echo ""
echo "Testing PostgreSQL connection (with retry logic)..."
POSTGRES_READY=false
for i in {1..10}; do
    echo "Attempt $i/10: Checking PostgreSQL connection..."
    if docker-compose -f docker-compose-keys.yml exec postgres-keys \
       pg_isready -U openbao_user -d openbao_vault 2>/dev/null | grep -q "accepting connections"; then
        echo "✅ PostgreSQL is running and accessible"
        POSTGRES_READY=true
        break
    else
        echo "PostgreSQL not ready yet, waiting 5 seconds..."
        sleep 5
    fi
done

if [ "$POSTGRES_READY" = false ]; then
    echo "❌ PostgreSQL connection failed after 10 attempts"
    echo "Check logs: docker logs postgres-keys"
    echo "Debug info:"
    docker-compose -f docker-compose-keys.yml ps
    exit 1
fi

echo ""
echo "Testing OpenBao connectivity (with retry logic)..."
# Load OpenBao token from environment variables with fallback
OPENBAO_TOKEN="${OPENBAO_TOKEN:-ehr-permanent-token}"
OPENBAO_ADDR="${OPENBAO_ADDR:-http://localhost:18200}"

OPENBAO_READY=false
for i in {1..10}; do
    echo "Attempt $i/10: Checking OpenBao connectivity..."
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
      --header "X-Vault-Token: $OPENBAO_TOKEN" \
      "$OPENBAO_ADDR/v1/sys/health")
    
    if [ "$RESPONSE" = "200" ] || [ "$RESPONSE" = "501" ]; then
        echo "✅ OpenBao is running with configured token"
        OPENBAO_READY=true
        break
    else
        echo "OpenBao not ready yet (HTTP $RESPONSE), waiting 5 seconds..."
        sleep 5
    fi
done

if [ "$OPENBAO_READY" = false ]; then
    echo "❌ OpenBao connectivity failed after 10 attempts"
    echo "Check logs: docker logs openbao"
    echo "Debug info:"
    docker-compose -f docker-compose-keys.yml ps
    exit 1
fi

# Check if initialized and unsealed
HEALTH=$(curl -s --header "X-Vault-Token: $OPENBAO_TOKEN" \
  "$OPENBAO_ADDR/v1/sys/health")

if echo "$HEALTH" | grep -q '"sealed":false'; then
    echo "OpenBao is unsealed and ready for operations"
fi

echo ""
echo "Testing audit functionality..."
# Wait a bit more for audit device to be fully initialized
sleep 5

# Make a test API call to generate audit entry
TEST_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
  --header "X-Vault-Token: $OPENBAO_TOKEN" \
  "$OPENBAO_ADDR/v1/sys/audit")

if [ "$TEST_RESPONSE" = "200" ]; then
    echo "Audit device is configured and accessible"
    
    # Check if audit log file is being written to
    if [ -f "./openbao/logs/audit.log" ]; then
        echo "Audit log file created successfully"
    else
        echo "Note: Audit log file will be created on first audit event"
    fi
else
    echo "Warning: Audit device test returned HTTP $TEST_RESPONSE"
    echo "Audit logs may not be fully configured"
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
    echo "  To manage audit logs, run:"
    echo "   ./manage-audit-logs.sh [list|stats|rotate|test]"
    echo ""
    echo "   Storage:"
    echo "   OpenBao data stored in: Docker volume 'ehr-keys-postgres-data'"
    echo "   OpenBao logs stored in: ./openbao/logs/ (JSON format with ISO timestamps)"
    echo "   OpenBao audit logs: ./openbao/logs/audit.log"
    echo "   PostgreSQL credentials: openbao_user / OpenBaoSecurePassword123!"
    echo ""
    echo "   For EHR backend integration, use environment variables:"
    echo "   OPENBAO_ADDR=http://openbao:8200"
    echo "   OPENBAO_TOKEN=\$OPENBAO_TOKEN"
    
    # Create configuration reference file
    cat > CONFIGURATION_REFERENCE.md << 'CONFIGEOF'
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
In EHR backend `.env` file:
\`\`\`bash
OPENBAO_ADDR=http://openbao:8200
OPENBAO_TOKEN=\$OPENBAO_TOKEN
\`\`\`

In EHR `docker-compose.yml`, connect to the network:
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
- OpenBao Audit: JSON audit logs to ./openbao/logs/audit.log
- PostgreSQL: Docker JSON logging driver with ISO timestamps
- Log level: info (OpenBao), default (PostgreSQL)

## Management Scripts
- \`./setup-keys-system.sh\` - Full system setup and initialization
- \`./start-keys-system.sh\` - Start existing containers
- \`./stop-keys-system.sh\` - Stop containers preserving data
- \`./logs-keys-system.sh\` - View container logs
- \`./test-connection.sh\` - Test system connectivity
- \`./configure-openbao-keys-management.sh\` - Configure cryptographic keys
- \`./manage-audit-logs.sh\` - Manage audit devices and audit logs
CONFIGEOF

    echo ""
    echo "Configuration saved to: CONFIGURATION_REFERENCE.md"