# EHR Keys Management System

A Docker-based keys management system using OpenBao with PostgreSQL storage backend for Electronic Health Records (EHR) applications. Provides cryptographic key management, secrets storage, and secure configuration management with structured logging using ISO 8601 timestamps.

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    EHR Keys Management System                │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐        ┌─────────────┐                     │
│  │   OpenBao   │◄──────►│ PostgreSQL  │                     │
│  │  Container  │        │  Container  │                     │
│  └─────────────┘        └─────────────┘                     │
│         ▲                         ▲                         │
│         │                         │                         │
│  ┌──────┴─────────────────────────┴──────┐                  │
│  │         Docker Network: ehr-keys-net  │                  │
│  └───────────────────────────────────────┘                  │
│         ▲                         ▲                         │
│         │                         │                         │
│  ┌──────┴──────┐           ┌──────┴──────┐                  │
│  │   Host:     │           │   Host:     │                  │
│  │  Port 18200 │           │  Port 5433  │                  │
│  └─────────────┘           └─────────────┘                  │
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites

- **Docker** (version 20.10+)
- **Docker Compose** (version 2.0+)
- **curl** (for API testing)
- **PostgreSQL client tools** (optional, for direct database access)

## Quick Start

### 1. Initial Setup

```bash
# Clone the repository (if not already done)
# git clone <repository-url>

# Navigate to the project directory
cd ehr-keys-management-system

# Run the setup script (creates containers, network, and volumes)
./setup-keys-system.sh
```

The setup script will:
- Create necessary directories with proper permissions
- Start Docker containers for OpenBao and PostgreSQL
- Configure Docker logging with ISO 8601 timestamps
- Test connectivity between services
- Generate configuration reference documentation

### 2. Environment Configuration

Create a `.env` file for custom configuration (optional):

```bash
# Copy the example configuration
cp .env.example .env  # If an example file exists

# Or create your own .env file with these variables:
# OPENBAO_TOKEN=your-custom-token-here
# OPENBAO_ADDR=http://localhost:18200
```

**Security Note**: The `.env` file is excluded from version control via `.gitignore`. Never commit sensitive credentials to version control.

### 3. Configure Cryptographic Keys

```bash
# Set up transit engine and cryptographic keys for EHR system
./configure-openbao-keys-management.sh
```

This script configures:
- Transit engine for cryptographic operations
- RSA-2048 key for key exchange
- AES-256-GCM key for data encryption
- KV v2 secrets engine for EHR configuration
- Auto-rotation policies for keys

## Container Management

### Starting the System

```bash
# Start all containers in detached mode
./start-keys-system.sh

# Or manually with Docker Compose
docker-compose -f docker-compose-keys.yml up -d
```

### Stopping the System

```bash
# Stop containers while preserving PostgreSQL data
./stop-keys-system.sh

# Or manually with Docker Compose
docker-compose -f docker-compose-keys.yml down
```

**Note**: PostgreSQL data is preserved in Docker volume `ehr-keys-postgres-data`.

### Viewing Logs

```bash
# View recent container logs
./logs-keys-system.sh

# View OpenBao logs only (with ISO timestamps)
docker logs openbao --tail 50

# View PostgreSQL logs only
docker logs postgres-keys --tail 20
```

### Testing Connectivity

```bash
# Run comprehensive connectivity tests
./test-connection.sh
```

Tests include:
- Host-to-container connectivity
- Container-to-container network communication
- PostgreSQL data access
- OpenBao API responsiveness

## Access Points

| Service | Internal URL | External URL | Purpose |
|---------|--------------|--------------|---------|
| OpenBao UI | `http://openbao:8200/ui` | `http://localhost:18200/ui` | Web interface for management |
| OpenBao API | `http://openbao:8200` | `http://localhost:18200` | REST API for automation |
| PostgreSQL | `postgres-keys:5432` | `localhost:5433` | Database access |

## Configuration Details

### Environment Variables

The system uses environment variables for configuration. Create a `.env` file in the project root:

```bash
# OpenBao Configuration
OPENBAO_TOKEN=ehr-permanent-token          # Authentication token
OPENBAO_ADDR=http://localhost:18200        # External API address
VAULT_ADDR=http://openbao:8200             # Internal API address
VAULT_TOKEN=ehr-permanent-token            # Alias for OPENBAO_TOKEN

# PostgreSQL Configuration (reference - defined in docker-compose)
# POSTGRES_DB=openbao_vault
# POSTGRES_USER=openbao_user
# POSTGRES_PASSWORD=OpenBaoSecurePassword123!
```

### Docker Compose Services

- **openbao**: OpenBao server with PostgreSQL storage backend
  - Image: `openbao/openbao:latest`
  - Ports: `18200:8200`
  - Volumes: Configuration and logs
  - Logging: JSON format with ISO 8601 timestamps

- **postgres-keys**: PostgreSQL database for OpenBao storage
  - Image: `postgres:17-alpine`
  - Ports: `5433:5432`
  - Volume: Persistent data storage
  - Health checks: Automatic connectivity verification

### Network Configuration

- **Network**: `ehr-keys-net` (bridge driver)
- **Purpose**: Isolated communication between OpenBao and PostgreSQL
- **External access**: Port mappings for host connectivity

## Integration with EHR Backend

### 1. Environment Configuration

In EHR backend `.env` file:

```bash
OPENBAO_ADDR=http://openbao:8200
OPENBAO_TOKEN=ehr-permanent-token
```

### 2. Docker Network Connection

In EHR `docker-compose.yml`:

```yaml
networks:
  ehr-keys-net:
    external: true
    name: ehr-keys-net

services:
-ehr-service:
    networks:
      - ehr-keys-net
    environment:
      - OPENBAO_ADDR=http://openbao:8200
      - OPENBAO_TOKEN=${OPENBAO_TOKEN}
```

### 3. Code Integration

Example Python code for accessing OpenBao:

```python
import hvac

# Initialize client with environment variables
client = hvac.Client(
    url=os.getenv('OPENBAO_ADDR'),
    token=os.getenv('OPENBAO_TOKEN')
)

# Use transit engine for encryption
encrypt_response = client.secrets.transit.encrypt_data(
    name='ehr-aes-master',
    plaintext='sensitive-data'
)
```

## Logging and Monitoring

### OpenBao Logs
- **Location**: `./openbao/logs/openbao.log`
- **Format**: JSON with ISO 8601 timestamps
- **Level**: `info` (configurable in `openbao/config/openbao.hcl`)

### PostgreSQL Logs
- **Format**: Docker JSON logging driver
- **Retention**: 10MB max file size, 3 files rotated

### Viewing Structured Logs

```bash
# View OpenBao JSON logs with jq for pretty printing
docker logs openbao --tail 10 | jq '.'

# View specific log fields
docker logs openbao --tail 10 | jq -r '"\(.time) \(.level): \(.message)"'
```

## Troubleshooting

### Common Issues

#### 1. Port Conflicts
```
Error: Port 18200 already in use
```
**Solution**: Stop other services using port 18200 or modify `OPENBAO_ADDR` in `.env` file.

#### 2. PostgreSQL Connection Failed
```
PostgreSQL connection failed
```
**Solution**:
```bash
# Check PostgreSQL logs
docker logs postgres-keys

# Verify port 5433 is available
netstat -an | grep 5433

# Restart PostgreSQL container
docker-compose -f docker-compose-keys.yml restart postgres-keys
```

#### 3. OpenBao Not Initialized
```
OpenBao not properly initialized
```
**Solution**:
```bash
# Check OpenBao logs
docker logs openbao

# Verify PostgreSQL is running
docker-compose -f docker-compose-keys.yml ps

# Restart OpenBao container
docker-compose -f docker-compose-keys.yml restart openbao
```

### Diagnostic Commands

```bash
# Check container status
docker-compose -f docker-compose-keys.yml ps

# Check network configuration
docker network inspect ehr-keys-net

# Check volume usage
docker volume inspect ehr-keys-postgres-data

# Test OpenBao API directly
curl -s --header "X-Vault-Token: $OPENBAO_TOKEN" \
  "$OPENBAO_ADDR/v1/sys/health" | jq
```

## Maintenance

### Backup PostgreSQL Data

```bash
# Create backup of PostgreSQL volume
docker run --rm -v ehr-keys-postgres-data:/source \
  -v $(pwd)/backups:/backup alpine \
  tar czf /backup/postgres-backup-$(date +%Y%m%d).tar.gz -C /source .
```

### Restore PostgreSQL Data

```bash
# Stop services
docker-compose -f docker-compose-keys.yml down

# Remove existing volume
docker volume rm ehr-keys-postgres-data

# Restore from backup
docker run --rm -v ehr-keys-postgres-data:/target \
  -v $(pwd)/backups:/backup alpine \
  tar xzf /backup/postgres-backup-YYYYMMDD.tar.gz -C /target

# Start services
./setup-keys-system.sh
```

### Update Container Images

```bash
# Pull latest images
docker-compose -f docker-compose-keys.yml pull

# Restart with new images
docker-compose -f docker-compose-keys.yml up -d
```

## Security Considerations

### Development vs Production

| Aspect | Development | Production |
|--------|-------------|------------|
| Authentication | Fixed token | Dynamic tokens with policies |
| Network | Bridge network | Isolated network segments |
| TLS/SSL | Disabled | Required with valid certificates |
| Logging | Local files | Centralized logging system |
| Monitoring | Basic health checks | Comprehensive monitoring |

### Production Recommendations

1. **Enable TLS**: Configure OpenBao with SSL certificates
2. **Token Management**: Implement proper token rotation and policies
3. **Network Security**: Use internal-only networking where possible
4. **Access Control**: Implement fine-grained policies for different services
5. **Audit Logging**: Enable OpenBao audit devices for compliance
6. **Backup Strategy**: Regular backups of PostgreSQL volume and OpenBao snapshots

## Script Reference

| Script | Purpose | Usage |
|--------|---------|-------|
| `setup-keys-system.sh` | Full system initialization | `./setup-keys-system.sh` |
| `start-keys-system.sh` | Start existing containers | `./start-keys-system.sh` |
| `stop-keys-system.sh` | Stop containers preserving data | `./stop-keys-system.sh` |
| `logs-keys-system.sh` | View container logs | `./logs-keys-system.sh` |
| `test-connection.sh` | Test system connectivity | `./test-connection.sh` |
| `configure-openbao-keys-management.sh` | Configure cryptographic keys | `./configure-openbao-keys-management.sh` |

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review container logs: `./logs-keys-system.sh`
3. Test connectivity: `./test-connection.sh`
4. Consult OpenBao documentation for API-specific questions

## License

MIT

---

**Note**: This is a development configuration. For production deployments, consult security best practices and implement appropriate hardening measures.
