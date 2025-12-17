-- PostgreSQL Database Initialization Script for OpenBao Storage
-- Executed automatically when PostgreSQL container starts for the first time
-- Sets up required extensions and test structures for OpenBao backend

-- ============================================================================
-- Required Extensions for OpenBao PostgreSQL Storage
-- ============================================================================

-- UUID extension: Required for generating unique identifiers in OpenBao
-- Used by OpenBao for secret versioning and internal data structures
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Cryptographic extension: Provides encryption functions
-- Used by OpenBao for additional security features when available
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- Database and User Configuration
-- ============================================================================
-- Note: Database 'openbao_vault' and user 'openbao_user' are created
-- automatically by PostgreSQL from Docker environment variables
-- No additional grants needed as environment variables handle permissions

-- ============================================================================
-- Test Table for Initialization Verification
-- ============================================================================

-- Test table to verify database initialization and connectivity
-- Used by test scripts to confirm PostgreSQL is ready for OpenBao
CREATE TABLE IF NOT EXISTS openbao_init_test (
    -- Auto-incrementing primary key for test records
    id SERIAL PRIMARY KEY,
    
    -- Test message to verify successful initialization
    test_message TEXT NOT NULL,
    
    -- Timestamp with timezone for audit trail
    -- Uses ISO 8601 format for consistency with OpenBao logging
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- Test Data Insertion
-- ============================================================================

-- Insert initial test record to verify table creation and data access
-- Uses ON CONFLICT to prevent duplicate inserts on container restart
INSERT INTO openbao_init_test (test_message) 
VALUES ('PostgreSQL database initialized successfully for OpenBao storage backend')
ON CONFLICT DO NOTHING;

-- ============================================================================
-- Initialization Completion Notification
-- ============================================================================

-- Log success message to PostgreSQL logs for monitoring
-- Provides clear indication that initialization script completed
DO $$ 
BEGIN
    RAISE NOTICE '✅ PostgreSQL database initialized for OpenBao storage backend';
    RAISE NOTICE '   Database: openbao_vault';
    RAISE NOTICE '   User: openbao_user';
    RAISE NOTICE '   Extensions: uuid-ossp, pgcrypto';
    RAISE NOTICE '   Test table: openbao_init_test created';
END $$;
