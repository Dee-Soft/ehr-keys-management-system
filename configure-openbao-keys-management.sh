#!/bin/bash

# OpenBao Configuration Script for EHR System
# Sets up cryptographic engines, keys, and secret storage for EHR application
# Loads configuration from .env file for environment-specific settings

echo "================================================"
echo "  Configuring OpenBao for EHR System"
echo "  Loading configuration from environment variables"
echo "================================================"

# Load environment variables from .env file if it exists
# Falls back to default values if .env is not present
if [ -f .env ]; then
    echo "Loading configuration from .env file..."
    source .env
else
    echo "Warning: .env file not found, using default configuration"
fi

# Set OpenBao connection parameters
# Uses environment variables with fallback to defaults
VAULT_ADDR="${OPENBAO_ADDR:-http://localhost:18200}"
VAULT_TOKEN="${OPENBAO_TOKEN:-ehr-permanent-token}"

echo ""
echo "Step 1: Checking OpenBao status..."
STATUS=$(curl -s --header "X-Vault-Token: $VAULT_TOKEN" \
  $VAULT_ADDR/v1/sys/health)

if ! echo "$STATUS" | grep -q '"initialized":true'; then
    echo "OpenBao not properly initialized"
    exit 1
fi

echo "OpenBao is initialized (PostgreSQL storage backend)"

echo ""
echo "🔧 Step 2: Enabling Transit Engine for cryptography..."
curl -s --header "X-Vault-Token: $VAULT_TOKEN" \
  --request POST \
  --data '{"type":"transit"}' \
  $VAULT_ADDR/v1/sys/mounts/transit 2>/dev/null

echo "🔧 Step 3: Creating cryptographic keys..."

# Backend RSA key
curl -s --header "X-Vault-Token: $VAULT_TOKEN" \
  --request POST \
  --data '{"type":"rsa-2048", "exportable": true}' \
  $VAULT_ADDR/v1/transit/keys/ehr-rsa-exchange-backend 2>/dev/null

# Frontend RSA key  
curl -s --header "X-Vault-Token: $VAULT_TOKEN" \
  --request POST \
  --data '{"type":"rsa-2048", "exportable": true}' \
  $VAULT_ADDR/v1/transit/keys/ehr-rsa-exchange-frontend 2>/dev/null

# Backend AES key
curl -s --header "X-Vault-Token: $VAULT_TOKEN" \
  --request POST \
  --data '{"type":"aes256-gcm96", "derived": true}' \
  $VAULT_ADDR/v1/transit/keys/ehr-aes-master-backend 2>/dev/null

# Frontend AES key
curl -s --header "X-Vault-Token: $VAULT_TOKEN" \
  --request POST \
  --data '{"type":"aes256-gcm96", "derived": true}' \
  $VAULT_ADDR/v1/transit/keys/ehr-aes-master-frontend 2>/dev/null

echo "🔧 Step 4: Setting auto-rotation policies..."
curl -s --header "X-Vault-Token: $VAULT_TOKEN" \
  --request POST \
  --data '{"auto_rotate_period":"720h"}' \
  $VAULT_ADDR/v1/transit/keys/ehr-rsa-key/config 2>/dev/null

curl -s --header "X-Vault-Token: $VAULT_TOKEN" \
  --request POST \
  --data '{"auto_rotate_period":"2160h"}' \
  $VAULT_ADDR/v1/transit/keys/ehr-aes-master/config 2>/dev/null

echo "🔧 Step 5: Enabling KV v2 for EHR secrets..."
curl -s --header "X-Vault-Token: $VAULT_TOKEN" \
  --request POST \
  --data '{"type":"kv", "options":{"version":"2"}}' \
  $VAULT_ADDR/v1/sys/mounts/ehr 2>/dev/null

echo "🔧 Step 6: Storing EHR configuration keys..."
# MongoDB connection string for EHR backend
curl -s --header "X-Vault-Token: $VAULT_TOKEN" \
  --header "Content-Type: application/json" \
  --request POST \
  --data '{"data":{"connection_string":"mongodb://mongoDB:27017/ehr-system"}}' \
  $VAULT_ADDR/v1/ehr/data/mongodb 2>/dev/null

# JWT secret
curl -s --header "X-Vault-Token: $VAULT_TOKEN" \
  --header "Content-Type: application/json" \
  --request POST \
  --data '{"data":{"secret":"ehr-jwt-super-secret-key-123456"}}' \
  $VAULT_ADDR/v1/ehr/data/jwt 2>/dev/null

# API keys or other secrets
curl -s --header "X-Vault-Token: $VAULT_TOKEN" \
  --header "Content-Type: application/json" \
  --request POST \
  --data '{"data":{"encryption_enabled":"true", "key_rotation_days":"30"}}' \
  $VAULT_ADDR/v1/ehr/data/config 2>/dev/null

echo ""
echo "Configuration Complete!"
echo ""
echo "Test the setup:"
echo "------------------"
echo "# Generate a test data key:"
echo "curl --header \"X-Vault-Token: ehr-permanent-token\" \\"
echo "  --request POST \\"
echo "  http://localhost:18200/v1/transit/datakey/plaintext/ehr-aes-master"
echo ""
echo "# Get RSA public key:"
echo "curl --header \"X-Vault-Token: ehr-permanent-token\" \\"
echo "  http://localhost:18200/v1/transit/keys/ehr-rsa-key"
echo ""
echo "# Read stored secrets:"
echo "curl --header \"X-Vault-Token: ehr-permanent-token\" \\"
echo "  http://localhost:18200/v1/ehr/data/mongodb"
