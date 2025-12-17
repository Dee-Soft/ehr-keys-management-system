# EHR Keys Management System Configuration

## System Status
✅ **PostgreSQL Container**: Fixed and running (PostgreSQL 17-alpine)
✅ **OpenBao Container**: Running with PostgreSQL storage backend
✅ **Network**: ehr-keys-net operational
✅ **Data Persistence**: PostgreSQL data volume configured correctly

## PostgreSQL 18+ Compatibility Fix
The system has been updated to handle PostgreSQL 18+ data directory structure changes:

### Issue Resolved
PostgreSQL 18+ introduced a breaking change in data directory structure:
- **Before PostgreSQL 18**: Data stored at `/var/lib/postgresql/data`
- **PostgreSQL 18+**: Data stored at `/var/lib/postgresql/{version}/data`

### Solution Implemented
1. **Updated volume mount path** in `docker-compose-keys.yml`:
   ```yaml
   # Before (caused PostgreSQL 18+ startup failure):
   volumes:
     - postgres-keys-data:/var/lib/postgresql/data
   
   # After (compatible with all PostgreSQL versions):
   volumes:
     - postgres-keys-data:/var/lib/postgresql
   ```

2. **Pinned PostgreSQL version** to 17-alpine for stability:
   ```yaml
   image: postgres:17-alpine
   ```

3. **Cleaned up old data volume** that was incompatible with new structure

## Permanent Credentials
- OpenBao Token: `ehr-permanent-token` (NEVER CHANGES)
- PostgreSQL User: `openbao_user` / `OpenBaoSecurePassword123!`
- PostgreSQL Database: `openbao_vault`

## Network Configuration
- OpenBao Container: `openbao:8200` (internal), `localhost:18200` (external)
- PostgreSQL Container: `postgres-keys:5432` (internal), `localhost:5433` (external)
- Docker Network: `ehr-keys-net` (managed by Docker Compose)

## Data Persistence
- PostgreSQL data: Docker volume `ehr-keys-postgres-data`
- OpenBao logs: `./openbao/logs/`

## Integration with EHR Backend
In your EHR backend `.env` file:
```bash
OPENBAO_ADDR=http://openbao:8200
OPENBAO_TOKEN=ehr-permanent-token
```

In your EHR `docker-compose.yml`, connect to the network:
```yaml
networks:
  ehr-keys-net:
    external: true
    name: ehr-keys-net
```

## PostgreSQL Connection Details
- Host: `postgres-keys` (within docker network) or `localhost` (from host)
- Port: `5432` (internal) or `5433` (external)
- Database: `openbao_vault`
- Username: `openbao_user`
- Password: `OpenBaoSecurePassword123!`
- SSL Mode: disabled (for development)

## Startup Scripts
- `./setup-keys-system.sh` - Full setup and initialization
- `./start-keys-system.sh` - Start existing containers
- `./stop-keys-system.sh` - Stop containers
- `./logs-keys-system.sh` - View container logs
- `./test-connection.sh` - Test system connectivity

## Troubleshooting

### PostgreSQL Startup Issues
If PostgreSQL fails to start:
1. Check logs: `docker logs postgres-keys`
2. Ensure no port conflicts (5433 on host)
3. Clean up old volume: `docker volume rm ehr-keys-postgres-data`
4. Restart: `docker-compose -f docker-compose-keys.yml restart postgres-keys`

### OpenBao Startup Issues
If OpenBao fails to start:
1. Check logs: `docker logs openbao`
2. Ensure port 18200 is available on host
3. Verify PostgreSQL is running and healthy
4. Check OpenBao config: `openbao/config/openbao.hcl`

### Network Issues
If containers can't communicate:
1. Verify network exists: `docker network ls | grep ehr-keys-net`
2. Check container network connections: `docker inspect openbao | grep Network`
3. Restart network: `docker-compose -f docker-compose-keys.yml down && ./setup-keys-system.sh`

## Maintenance

### Backup PostgreSQL Data
```bash
# Backup volume data
docker run --rm -v ehr-keys-postgres-data:/source -v $(pwd)/backups:/backup alpine tar czf /backup/postgres-backup-$(date +%Y%m%d).tar.gz -C /source .
```

### Restore PostgreSQL Data
```bash
# Stop services
docker-compose -f docker-compose-keys.yml down

# Remove existing volume
docker volume rm ehr-keys-postgres-data

# Restore from backup
docker run --rm -v ehr-keys-postgres-data:/target -v $(pwd)/backups:/backup alpine tar xzf /backup/postgres-backup-YYYYMMDD.tar.gz -C /target

# Start services
./setup-keys-system.sh
```

### Update PostgreSQL Version
To update PostgreSQL version:
1. Update `docker-compose-keys.yml` image tag
2. Run `./setup-keys-system.sh` (will create new volume with correct structure)
3. If data migration needed, use `pg_upgrade` tool

## Security Notes
- **Development Only**: This setup uses insecure settings (no TLS, simple passwords)
- **Production**: Enable TLS, use strong passwords, implement proper secrets management
- **Tokens**: The permanent token should be rotated in production environments
- **Network**: Consider using internal-only networking in production
