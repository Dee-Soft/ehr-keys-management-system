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
