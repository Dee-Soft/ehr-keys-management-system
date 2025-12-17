-- PostgreSQL initialization for OpenBao Storage
-- This script runs when the PostgreSQL container is first started

-- Create additional extensions if needed (PostgreSQL will create the database from environment variables)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Grant necessary permissions (database and user are created from environment variables)
-- The openbao_user already has access to the openbao_vault database via environment variables

-- Create a simple test table to verify initialization
CREATE TABLE IF NOT EXISTS openbao_init_test (
    id SERIAL PRIMARY KEY,
    test_message TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert a test record
INSERT INTO openbao_init_test (test_message) 
VALUES ('PostgreSQL initialized successfully for OpenBao storage')
ON CONFLICT DO NOTHING;

-- Log success
DO $$ 
BEGIN
    RAISE NOTICE '✅ PostgreSQL initialized for OpenBao storage';
END $$;
