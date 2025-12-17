# EHR Keys Management System - OpenBao Configuration
# PostgreSQL storage backend with structured logging

# PostgreSQL Storage Backend Configuration
# Provides persistent storage for OpenBao secrets and keys
storage "postgresql" {
  # Connection URL for PostgreSQL database
  # Format: postgres://username:password@host:port/database?options
  connection_url = "postgres://openbao_user:OpenBaoSecurePassword123!@postgres-keys:5432/openbao_vault?sslmode=disable"
  
  # Maximum parallel operations for database connections
  max_parallel = 4
}

# Logging Configuration
# Structured JSON logging with ISO 8601 timestamps for audit trail
log_level = "info"
log_format = "json"
log_file = "/vault/logs/openbao.log"

# Audit Device Configuration
# File-based audit logging for critical operations
audit "file" {
  type = "file"
  path = "/vault/logs/audit.log"
  description = "Audit logs for critical operations"
  options = {
    file_path = "/vault/logs/audit.log"
  }
}

# Development Settings
# Required for containerized environments without mlock capability
disable_mlock = true