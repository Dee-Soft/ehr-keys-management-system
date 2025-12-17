# OpenBao Configuration with PostgreSQL Storage
# Minimal config for dev mode - dev mode handles listeners automatically

# PostgreSQL Storage Backend
storage "postgresql" {
  connection_url = "postgres://openbao_user:OpenBaoSecurePassword123!@postgres-keys:5432/openbao_vault?sslmode=disable"
  max_parallel = 4
}

# Development settings
disable_mlock = true